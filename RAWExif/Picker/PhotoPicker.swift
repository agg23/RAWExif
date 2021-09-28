//
//  PhotoPicker.swift
//  RAWExif
//
//  Created by Adam Gastineau on 9/25/21.
//

import SwiftUI
import Photos

struct PhotoPicker: View {    
    @Binding var selectedPhotos: [PHAsset]
    @State private var status: PHAuthorizationStatus = .denied
    
    var body: some View {
        VStack {
            if status == .authorized {
                AuthorizedPhotoPicker(selectedPhotos: $selectedPhotos)
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
    
    @Binding var selectedPhotos: [PHAsset]
    
    @State private var selectedPhotoIds = Set<String>()

    init(selectedPhotos: Binding<[PHAsset]>) {
        self._selectedPhotos = selectedPhotos
        
        let photosOptions = PHFetchOptions()
        photosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        photosOptions.includeAssetSourceTypes = [.typeUserLibrary]
        let fetchedPhotos = PHAsset.fetchAssets(with: .image, options: photosOptions)

        count = fetchedPhotos.count

        allPhotos = fetchedPhotos.objects(at: IndexSet(integersIn: 0..<count))
    }
    
    public var body: some View {
        let selectedPhotoIdsBinding = Binding(get: { self.selectedPhotoIds }, set: { newIds in
            self.selectedPhotoIds = newIds
            selectedPhotos = allPhotos.filter({ asset in
                newIds.contains(asset.id)
            })
        })

        Text("Displaying \(count) photos")
        List(allPhotos, selection: selectedPhotoIdsBinding) { asset in
            PhotoPickerListRowView(photo: asset)
        }
    }
}
