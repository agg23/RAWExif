//
//  PhotoPicker.swift
//  RAWExif
//
//  Created by Adam Gastineau on 9/25/21.
//

import SwiftUI
import Photos

struct PhotoPicker: View {
    @State private var status: PHAuthorizationStatus = .denied
    
    var body: some View {
        VStack {
            if status == .authorized {
                AuthorizedPhotoPicker()
            } else {
                Text("Invalid authorization")
            }
        }.onAppear {
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                self.status = status
            }
        }
    }
}

private struct AuthorizedPhotoPicker: View {
    let count: Int
    let allPhotos: [PHAsset]
    
    @StateObject var manager = PhotoPickerState()
    @State private var selectedPhotos = Set<String>()

    init() {
        let photosOptions = PHFetchOptions()
        photosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        photosOptions.includeAssetSourceTypes = [.typeUserLibrary]
        let fetchedPhotos = PHAsset.fetchAssets(with: .image, options: photosOptions)

        count = fetchedPhotos.count

        allPhotos = fetchedPhotos.objects(at: IndexSet(integersIn: 0..<count))
    }
    
    public var body: some View {
        Text("Displaying \(count) photos")
        List(allPhotos, selection: $selectedPhotos) { asset in
            PhotoPickerListRowView(photo: asset)
        }.environmentObject(manager)
        Button("Export RAW", action: exportSelectedRAW)
    }
    
    private func exportSelectedRAW() {
        guard !selectedPhotos.isEmpty, let first = selectedPhotos.first else {
            return
        }
        
        guard let asset = allPhotos.first(where: { asset in
            asset.id == first
        }) else {
            return
        }
        
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
        manager.resource.requestData(for: resource, options: options) { newData in
            data += newData
        } completionHandler: { error in
            if error != nil {
                print("Error \(String(describing: error))")
                return
            }
            
            print("Downloaded image")
            
            let path = URL(fileURLWithPath: "\(NSHomeDirectory())/output.raw")
            
            do {
                try data.write(to: path)
                print("Wrote image to \(path)")
            } catch {
                print(error)
            }
        }
    }
}

struct PhotoPicker_Previews: PreviewProvider {
    static var previews: some View {
        PhotoPicker()
    }
}
