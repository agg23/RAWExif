//
//  PreferencesView.swift
//  PreferencesView
//
//  Created by Adam Gastineau on 9/26/21.
//

import SwiftUI

struct PreferencesView: View {
    @State private var addingLens = false
    @State private var selection: UUID?
    
    @AppStorage("lenses") private var lenses: [Lens] = []
    
    @State private var defaultLens = [Lens(make: "Example", model: "None", focalLength: 50, focalLengthMin: 20, focalLengthMax: 75, fStop: 2.6, fStopMin: 2.4, fStopMax: 5.4)]
            
    var body: some View {
        VStack {
            PreferencesTableView(lenses: !lenses.isEmpty ? $lenses : $defaultLens, selection: $selection)
            HStack {
                Button("Delete", action: delete)
                    .disabled(selection == nil || lenses.isEmpty)
                Button("Add", action: {
                    addingLens.toggle()
                }).sheet(isPresented: $addingLens) {
                    AddLensView(save: save)
                }
            }.padding()
        }.padding()
    }
    
    func save(lens: Lens) {
        lenses.append(lens)
    }
    
    func delete() {
        guard let selection = selection, !lenses.isEmpty else {
            return
        }
        
        lenses.removeAll { lens in
            lens.id == selection
        }
        
        self.selection = nil
    }
}

struct PreferencesTableView: View {
    @Binding var lenses: [Lens]
    @Binding var selection: UUID?
    
    var body: some View {
        Table(lenses, selection: $selection) {
            TableColumn("Make", value: \.make)
            TableColumn("Model", value: \.model)
            TableColumn("Image Focal Length", value: \.imageFocalLengthString)
            TableColumn("Lens Focal Range", value: \.exifFocalLengthString)
            TableColumn("Image F Stop", value: \.fStopString)
            TableColumn("F Stop Range", value: \.fStopRangeString)
        }
    }
}

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView()
    }
}
