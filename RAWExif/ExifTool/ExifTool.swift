//
//  ExifTool.swift
//  ExifTool
//
//  Created by Adam Gastineau on 9/26/21.
//

import Foundation
import ExifTool

func configureExifTool() {
    guard let url = Bundle.main.url(forResource: "exiftool", withExtension: "") else {
        print("exiftool binary was not found in bundle")
        return
    }
    
    ExifTool.setExifTool(url.path)
}
