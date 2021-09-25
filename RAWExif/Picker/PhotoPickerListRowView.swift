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
                    Text("Image could not be loaded")
                }
            }
                .frame(width: 300, height: 300, alignment: .center)
            VStack {
                Text("Created on \(photo.creationDate?.ISO8601Format() ?? "unknown")")
                if let modificationDate = photo.modificationDate {
                    Text("Modified on \(modificationDate.ISO8601Format())")
                }
            }.onAppear {
                manager.manager.requestImage(for: photo, targetSize: CGSize(width: 300, height: 300), contentMode: .default, options: nil) { newImage, _ in
                    image = newImage
                }
            }
        }
    }
}

struct PhotoPickerListRowView_Previews: PreviewProvider {
    static var previews: some View {
        PhotoPickerListRowView(photo: PHAsset())
    }
}
