//
//  RAWExifApp.swift
//  RAWExif
//
//  Created by Adam Gastineau on 9/25/21.
//

import SwiftUI

@main
struct RAWExifApp: App {
    init() {
        configureExifTool()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 800, minHeight: 600)
        }
        
        Settings {
            PreferencesView()
                .frame(minWidth: 600, minHeight: 400)
        }
    }
}
