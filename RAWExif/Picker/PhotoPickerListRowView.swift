//
//  PhotoPickerListRowView.swift
//  PhotoPickerListRowView
//
//  Created by Adam Gastineau on 9/25/21.
//

import SwiftUI
import Photos

struct PhotoPickerListRowView: View {
    @EnvironmentObject var manager: PhotoPickerState
    
    var photo: PHAsset
    @State private var image: NSImage? = nil
    @State private var resources = [PHAssetResource]()
    
    var body: some View {
        HStack {
            VStack {
                if let image = image {
                    Image(nsImage: image).overlay(alignment: .bottomTrailing) {
                        if photo.isFavorite {
                            Image(systemName: "heart.fill").padding().frame(width: 32, height: 32, alignment: .bottomTrailing)
                        }
                    }
                } else {
                    Image(systemName: "questionmark")
                }
            }
                .frame(width: 300, height: 300, alignment: .center)
            VStack {
                if let firstResource = resources.first {
                    Text(firstResource.originalFilename)
                }
                Text("Created on \(photo.creationDate?.ISO8601Format() ?? "unknown")")
                if let modificationDate = photo.modificationDate {
                    Text("Modified on \(modificationDate.ISO8601Format())")
                }
                Text(assetTypes())
            }.onAppear {
                fetchContent()
            }
        }
    }
    
    private func fetchContent() {
        manager.image.requestImage(for: photo, targetSize: CGSize(width: 300, height: 300), contentMode: .default, options: nil) { newImage, _ in
            image = newImage
        }
        
        resources = PHAssetResource.assetResources(for: photo)
    }
    
    private func assetTypes() -> String {
        let resourceTypes: [String] = resources.compactMap { resource in
            guard let uti = UTType(resource.uniformTypeIdentifier) else {
                print("Unknown UTI \(resource.uniformTypeIdentifier)")
                return nil
            }
            
            if uti.conforms(to: .rawImage) {
                return "RAW"
            } else if uti.conforms(to: .jpeg) {
                return "JPEG"
            } else if uti.conforms(to: .png) {
                return "PNG"
            } else if uti.conforms(to: .tiff) {
                return "TIFF"
            } else if uti.conforms(to: .heic) {
                return "HEIC"
            } else if uti.conforms(to: .heif) {
                return "HEIF"
            }
            
            return nil
        }
        
        if resourceTypes.count < 1 {
            return "Unknown"
        }
        
        return resourceTypes.joined(separator: ", ")
    }
}

struct PhotoPickerListRowView_Previews: PreviewProvider {
    static var previews: some View {
        PhotoPickerListRowView(photo: PHAsset())
    }
}
