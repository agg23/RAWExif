//
//  ContentView.swift
//  RAWExif
//
//  Created by Adam Gastineau on 9/25/21.
//

import SwiftUI
import SwiftUILib_DocumentPicker

import Photos
import ExifTool

actor ExportCount: ObservableObject {
    var count: Int = 0
}

struct ContentView: View {
    @AppStorage("lenses") private var lenses: [Lens] = []
    
    @State var exportCount: Int = 0
    @State var selectedPhotos: [PHAsset] = []
    
    enum SelectedLens: Identifiable, Hashable {
        case same
        case custom(lens: Lens)
        
        var id: String {
            switch self {
            case .same:
                return "same"
            case .custom(lens: let lens):
                return lens.id.uuidString
            }
        }
        
        func hash(into hasher: inout Hasher) {
            switch self {
            case .same:
                hasher.combine(1234)
            case .custom(lens: let lens):
                hasher.combine(lens)
            }
        }
    }
    
    @State var selectedLens: SelectedLens = .same
    @State var shouldUploadJpegs = false
    
    @State var isSelectingExportUrl = false
    @State var isExporting = false
    
    @State var exportUrl: URL?
    
    var body: some View {
        VStack {
            PhotoPicker(selectedPhotos: $selectedPhotos)
            Spacer(minLength: 0)
            HStack(alignment: .bottom) {
                Picker("Overwrite Lens:", selection: $selectedLens) {
                    Text("None").tag(SelectedLens.same)
                    ForEach(lenses) { lens in
                        Text(lens.displayString).tag(SelectedLens.custom(lens: lens))
                    }
                }.onChange(of: lenses) { newValue in
                    // Ensure current selection is within set
                    switch selectedLens {
                    case .same:
                        return
                    case .custom(let lens):
                        if !lenses.contains(where: { l in
                            lens == l
                        }) {
                            selectedLens = .same
                        }
                    }
                }
                Toggle("Re-upload JPEGs", isOn: $shouldUploadJpegs)
                Button(selectedLens == .same ? "Download" : "Download and Update", action: selectExportUrl)
                    .disabled(selectedPhotos.isEmpty)
            }
                .padding()
                .sheet(isPresented: $isExporting) {
                    let total = shouldUploadJpegs ? selectedPhotos.count * 2 : selectedPhotos.count
                    
                    ProgressView("Exporting images", value: Double(exportCount), total: Double(total)).padding()
                }
            // Wrapped in if as documentPicker doesn't have correct isPresented logic
            if isSelectingExportUrl {
                Group {}
                    .documentPicker(isPresented: $isSelectingExportUrl, documentTypes: ["public.folder"], onDocumentsPicked:  { urls in
                        isSelectingExportUrl = false
                        guard let url = urls.first else {
                            return
                        }
                        
                        exportUrl = url
                        
                        exportSelected()
                    })
            }
        }
    }
    
    private func selectExportUrl() {
        isSelectingExportUrl = true
    }
    
    private func exportSelected() {
        exportCount = 0
        isExporting = true
        
        actor JpegUrls {
            var urls = [URL: Bool]()

            func add(_ url: URL, isFavorite: Bool) {
                urls[url] = isFavorite
            }
        }
        
        actor JpegSkippedAssets {
            var assets = Set<PHAsset>()
            
            func insert(_ asset: PHAsset) {
                assets.insert(asset)
            }
        }
        
        let skippedJpegAssets = JpegSkippedAssets()
        let urls = JpegUrls()
        
        let fetchRAW = {
            await withTaskGroup(of: Void.self) { group in
                for asset in selectedPhotos {
                    group.addTask {
                        var convertJpeg = false
                        
                        if shouldUploadJpegs {
                            if resource(for: asset, of: .fullSizePhoto, conformsTo: .jpeg) == nil {
                                // No JPEG asset available. Must convert RAW
                                await skippedJpegAssets.insert(asset)
                                convertJpeg = true
                            }
                        }
                        
                        let rawPath = await downloadRAW(for: asset)
                        
                        if let rawPath = rawPath, convertJpeg {
                            let jpegPath = tempJpegPath()
                            if jpeg(fromRaw: rawPath, output: jpegPath) {
                                await urls.add(jpegPath, isFavorite: asset.isFavorite)
                            } else {
                                print("Failed to create JPEG from RAW")
                            }
                        }
                        
                        let completedCount = convertJpeg ? 2 : 1
                        
                        DispatchQueue.main.async {
                            exportCount += completedCount
                        }
                    }
                }
            }
            
            print("Completed export of all selections")
        }
        
        let fetchAndUploadJPEG = {
            let successfulDownloads = await withTaskGroup(of: Bool.self) { group -> Int in
                var acc = 0

                for asset in selectedPhotos {
                    guard await !skippedJpegAssets.assets.contains(asset) else {
                        acc += 1
                        continue
                    }
                    
                    group.addTask {
                        if let newImageUrl = await downloadLatestJpeg(for: asset) {
                            await urls.add(newImageUrl, isFavorite: asset.isFavorite)
                            return true
                        } else {
                            print("Image could not be retrieved")
                            return false
                        }
                    }
                }
                
                for await result in group {
                    if result {
                        acc += 1
                    }
                }
                
                return acc
            }
            
            if successfulDownloads < selectedPhotos.count {
                print("Only downloaded \(successfulDownloads) of \(selectedPhotos.count). Aborting...")
                return
            }
            
            if await uploadJpegs(at: urls.urls) {
                print("Completed upload of all updated images")
            } else {
                print("Failed to upload updated images")
            }
        }
        
        Task {
            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    await fetchRAW()
                    if shouldUploadJpegs {
                        await fetchAndUploadJPEG()
                    }
                }
            }
            
            print("Completed all operations")
            isExporting = false
        }
    }
    
    private func jpeg(fromRaw raw: URL, output: URL) -> Bool {
        guard let source = CGImageSourceCreateWithURL(raw as CFURL, nil), let destination = CGImageDestinationCreateWithURL(output as CFURL, UTType.jpeg.identifier as CFString, 0, nil) else {
            return false
        }
        
        let options = [kCGImageDestinationLossyCompressionQuality: 1.0]
        CGImageDestinationAddImageFromSource(destination, source, 0, options as CFDictionary)
        if CGImageDestinationFinalize(destination) {
            // ImageIO doesn't properly set all EXIF data, so we rely on ExifTool instead
            let exifData = ExifTool.read(fromurl: output)
            let scaleFactor = exifData["ScaleFactor35efl"] ?? "1"

            let dictionary = exifDictionary(from: selectedLens, scaleFactor: scaleFactor)
            exifData.update(metadata: dictionary)
            
            return true
        }
        
        return false
    }
    
    private func resource(for asset: PHAsset, of type: PHAssetResourceType, conformsTo uttype: UTType) -> PHAssetResource? {
        let resources = PHAssetResource.assetResources(for: asset)
        
        return resources.first { resource in
            if resource.type == type {
                return true
            }
            
            guard let type = UTType(resource.uniformTypeIdentifier) else {
                return false
            }
            
            return type.conforms(to: uttype)
        }
    }
    
    private func download(resource: PHAssetResource) async -> Data? {
        let options = PHAssetResourceRequestOptions()
        options.isNetworkAccessAllowed = true
        var data = Data()
        
        do {
            let _: Void = try await withCheckedThrowingContinuation { continuation in
                PHAssetResourceManager.default().requestData(for: resource, options: options) { newData in
                    data += newData
                } completionHandler: { error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            }
        } catch {
            print("Error \(error)")
            return nil
        }
        
        print("Downloaded image")
        
        return data
    }

    private func tempJpegPath() -> URL {
        URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent("\(UUID().uuidString).jpg")
    }
    
    private func downloadLatestJpeg(for asset: PHAsset) async -> URL? {
        guard let resource = resource(for: asset, of: .fullSizePhoto, conformsTo: .jpeg) else {
            print("Bad resource, \(PHAssetResource.assetResources(for: asset))")
            return nil
        }
        
        guard let data = await download(resource: resource) else {
            print("Bad download")
            return nil
        }
        
        let path = tempJpegPath()

        guard let source = CGImageSourceCreateWithData(data as CFData, nil), let destination = CGImageDestinationCreateWithURL(path as CFURL, "public.jpeg" as CFString, 0, nil) else {
            return nil
        }
        
        let success = CGImageDestinationCopyImageSource(destination, source, nil, nil)
        
        guard success else {
            print("Error in building JPEG")
            return nil
        }
                
        // ImageIO doesn't properly set all EXIF data, so we rely on ExifTool instead
        let exifData = ExifTool.read(fromurl: path)
        let scaleFactor = exifData["ScaleFactor35efl"] ?? "1"
        
        let dictionary = exifDictionary(from: selectedLens, scaleFactor: scaleFactor)
        exifData.update(metadata: dictionary)
        
        return path
    }
    
    private func uploadJpegs(at urls: [URL: Bool]) async -> Bool {
        do {
            return try await withCheckedThrowingContinuation { continuation in
                PHPhotoLibrary.shared().performChanges {
                    let albumRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: "RAWExif Import \(Date.now.formatted())")
                    
                    let assetRequests = urls.map { url, isFavorite -> PHAssetChangeRequest? in
                        let request = PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: url)
                        request?.isFavorite = isFavorite
                        return request
                    }
                    
                    albumRequest.addAssets(assetRequests.map { request in request?.placeholderForCreatedAsset } as NSArray)
                } completionHandler: { success, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: success)
                    }
                }
            }
        } catch  {
            print(error)
        }
        
        return false
    }
    
    private func downloadRAW(for asset: PHAsset) async -> URL? {
        guard let exportUrl = exportUrl else {
            return nil
        }
                
        guard let resource = resource(for: asset, of: .alternatePhoto, conformsTo: .rawImage) else {
            return nil
        }

        guard let data = await download(resource: resource) else {
            return nil
        }

        let path = exportUrl.appendingPathComponent(resource.originalFilename)

        do {
            try data.write(to: path)
            print("Wrote image to \(path)")
        } catch {
            print(error)
            return nil
        }

        let exifData = ExifTool.read(fromurl: path)
        let scaleFactor = exifData["ScaleFactor35efl"] ?? "1"

        let dictionary = exifDictionary(from: selectedLens, scaleFactor: scaleFactor)
        if dictionary.isEmpty {
            return path
        }
        
        exifData.update(metadata: dictionary)
        
        return path
    }
    
    private func exifDictionary(from selectedLens: SelectedLens, scaleFactor: String) -> [String: String] {
        switch selectedLens {
        case .same:
            return [:]
        case .custom(lens: let lens): do {
            var exifData = [String: String]()
            
            exifData["LensInfo"] = lens.exifInfoString
            exifData["LensMake"] = lens.make
            exifData["LensModel"] = lens.model
            exifData["Lens"] = lens.model
        
            exifData["FocalLength"] = lens.exifFocalLengthString
            exifData["MinFocalLength"] = "\(lens.focalLengthMin)"
            exifData["MaxFocalLength"] = "\(lens.focalLengthMax)"
            exifData["FocalLengthIn35mmFormat"] = lens.exifFocalLength35String(scaleFactor: scaleFactor)
            
            exifData["FNumber"] = lens.fStopString
            
            return exifData
        }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
