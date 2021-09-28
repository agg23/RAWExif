//
//  AddLensView.swift
//  AddLensView
//
//  Created by Adam Gastineau on 9/26/21.
//

import SwiftUI

struct AddLensView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var save: (Lens) -> Void
    
    @State private var make: String = ""
    @State private var model: String = ""
    @State private var focalLength: Int = 0
    @State private var focalLengthMin: Int = 0
    @State private var focalLengthMax: Int = 0
    @State private var fStop: Double = 0
    @State private var fStopMin: Double = 0
    @State private var fStopMax: Double = 0
    
    private let intFormatter = NumberFormatter()
    private let doubleFormatter = NumberFormatter()
        
    init(save newSave: @escaping (Lens) -> Void) {
        save = newSave
        intFormatter.allowsFloats = false
        intFormatter.numberStyle = .none
        doubleFormatter.allowsFloats = true
        doubleFormatter.numberStyle = .decimal
    }
    
    var body: some View {
        Form {
            TextField("Make", text: $make)
            TextField("Model", text: $model)
            Section("Focal Length") {
                TextField("Picture Length", value: $focalLength, formatter: intFormatter)
                TextField("Lens Min", value: $focalLengthMin, formatter: intFormatter)
                TextField("Lens Max", value: $focalLengthMax, formatter: intFormatter)
            }
            Section("F Stop") {
                TextField("Picture F Stop", value: $fStop, formatter: doubleFormatter)
                TextField("F Stop Min", value: $fStopMin, formatter: doubleFormatter)
                TextField("F Stop Max", value: $fStopMax, formatter: doubleFormatter)
            }
            HStack {
                Spacer()
                Button("Cancel", action: {
                    presentationMode.wrappedValue.dismiss()
                })
                    .keyboardShortcut(.cancelAction)
                Button("Add", action: {
                    save(Lens(make: make, model: model, focalLength: focalLength, focalLengthMin: focalLengthMin, focalLengthMax: focalLengthMax, fStop: fStop, fStopMin: fStopMin, fStopMax: fStopMax))
                    presentationMode.wrappedValue.dismiss()
                })
                    .keyboardShortcut(.defaultAction)
                    .disabled(make.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || focalLength <= 0 || focalLengthMin <= 0 || focalLengthMax <= 0 || fStop <= 0 || fStopMin <= 0 || fStopMax <= 0)
            }
        }
        .padding()
        .frame(width: 400)
    }
}

struct AddLensView_Previews: PreviewProvider {
    static var previews: some View {
        AddLensView { _ in
            
        }
    }
}
