//
//  ContentView.swift
//  RAWExif
//
//  Created by Adam Gastineau on 9/25/21.
//

import SwiftUI
import Photos
import ExifTool

actor ExportCount: ObservableObject {
    var count: Int = 0
}

struct ContentView: View {
    @AppStorage("lenses") private var lenses: [Lens] = []
    
    @StateObject var manager = PhotoPickerState()
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
        
    @State var isExporting = false
    
    var body: some View {
        VStack {
            PhotoPicker(manager: manager, selectedPhotos: $selectedPhotos)
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
                Button(selectedLens == .same ? "Download" : "Download and Update", action: exportSelected)
                    .disabled(selectedPhotos.isEmpty)
            }
                .padding()
                .sheet(isPresented: $isExporting) {
                    ProgressView("Exporting images", value: Double(exportCount), total: Double(selectedPhotos.count)).padding()
                }
        }
    }
    
    private func exportSelected() {
        exportCount = 0
        isExporting = true
        
        Task {
            await withTaskGroup(of: Void.self) { group in
                for asset in selectedPhotos {
                    group.addTask {
                        await downloadRAW(for: asset)
                        DispatchQueue.main.async {
                            exportCount += 1
                        }
                    }
                }
            }
            
            print("Completed export of all selections")
            isExporting = false
        }
    }
    
    private func downloadRAW(for asset: PHAsset) async {
        let resources = PHAssetResource.assetResources(for: asset)
        
        guard let resource = resources.first(where: { resource in
            if resource.type == .alternatePhoto {
                return true
            }
            
            guard let type = UTType(resource.uniformTypeIdentifier) else {
                return false
            }
            
            return type.conforms(to: .rawImage)
        }) else {
            return
        }
        
        print("Exporting asset \(asset) using resource \(resource)")

        let options = PHAssetResourceRequestOptions()
        options.isNetworkAccessAllowed = true
        var data = Data()
        
        do {
            let _: Void = try await withCheckedThrowingContinuation { continuation in
                manager.resource.requestData(for: resource, options: options) { newData in
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
        }
        
        print("Downloaded image")

        let path = URL(fileURLWithPath: "\(NSHomeDirectory())/\(resource.originalFilename)")

        do {
            try data.write(to: path)
            print("Wrote image to \(path)")
        } catch {
            print(error)
        }
        
        switch selectedLens {
        case .same:
            return
        case .custom(let lens): do {
            let exifData = ExifTool.read(fromurl: path)
            var newExifData = [String: String]()
            
            newExifData["LensInfo"] = lens.exifInfoString
            newExifData["LensMake"] = lens.make
            newExifData["LensModel"] = lens.model
        
            newExifData["FocalLength"] = lens.exifFocalLengthString
            newExifData["MinFocalLength"] = "\(lens.focalLengthMin)"
            newExifData["MaxFocalLength"] = "\(lens.focalLengthMax)"
            newExifData["FocalLengthIn35mmFormat"] = lens.exifFocalLength35String
            
            newExifData["FNumber"] = lens.fStopString

            exifData.update(metadata: newExifData)
        }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
