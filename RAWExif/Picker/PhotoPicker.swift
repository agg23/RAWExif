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

        var photos: [PHAsset] = []
        fetchedPhotos.enumerateObjects { asset, _, _ in
            photos.append(asset)
        }

        allPhotos = photos
    }
    
    public var body: some View {
        Text("Displaying \(count) photos")
        List(allPhotos, selection: $selectedPhotos) { asset in
            PhotoPickerListRowView(photo: asset)
        }.environmentObject(manager)
    }
}

struct PhotoPicker_Previews: PreviewProvider {
    static var previews: some View {
        PhotoPicker()
    }
}
