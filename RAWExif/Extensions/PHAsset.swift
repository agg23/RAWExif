//
//  PHAsset.swift
//  RAWExif
//
//  Created by Adam Gastineau on 9/25/21.
//

import Photos

extension PHAsset: Identifiable {
    public var id: String {
        self.localIdentifier
    }
}
