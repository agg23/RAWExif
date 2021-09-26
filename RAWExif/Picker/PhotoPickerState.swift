//
//  PhotoPickerState.swift
//  PhotoPickerState
//
//  Created by Adam Gastineau on 9/25/21.
//

import Foundation
import Photos

class PhotoPickerState: ObservableObject {
    let image = PHImageManager.default()
    let resource = PHAssetResourceManager.default()
}
