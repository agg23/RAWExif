//
//  Lens.swift
//  Lens
//
//  Created by Adam Gastineau on 9/26/21.
//

import Foundation

struct Lens: Identifiable, Codable, Hashable {
    let make: String
    let model: String
    let focalLength: Int
    let focalLengthMin: Int
    let focalLengthMax: Int
    let fStop: Double
    let fStopMin: Double
    let fStopMax: Double
    var id = UUID()
    
    var imageFocalLengthString: String {
        "\(focalLength)mm"
    }
    
    var exifFocalLengthString: String {
        "\(focalLength).0 mm"
    }
    
    func exifFocalLength35String(scaleFactor: String) -> String {
        guard let scaleFactor = Double(scaleFactor) else {
            print("Unknown scaleFactor \(scaleFactor)")
            assertionFailure()
            return ""
        }
        
        return String(format: "%.1f mm", Double(focalLength) * scaleFactor)
    }
    
    private var fullFocalLengthString: String {
        focalLengthMin == focalLengthMax ? "\(focalLengthMin)mm" : "\(focalLengthMin)-\(focalLengthMax)mm"
    }
    
    
    var exifFStopString: String {
        fStopMin == fStopMax ? "f/\(fStopMin)" : "f/\(fStopMin)-\(fStopMax)"
    }
    
    var fStopString: String {
        "\(fStop)"
    }
    
    var fStopRangeString: String {
        "f/\(fStopMin) - f/\(fStopMax)"
    }
    
    var exifInfoString: String {
        "\(fullFocalLengthString) \(exifFStopString)"
    }
    
    var displayString: String {
        "\(make) \(model) \(fullFocalLengthString) \(exifFStopString)"
    }
}
