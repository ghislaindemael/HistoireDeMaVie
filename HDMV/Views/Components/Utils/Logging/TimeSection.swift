//
//  TimeSection.swift
//  HDMV
//
//  Created by Ghislain Demael on 22.10.2025.
//

import SwiftUI

struct TimeSection<Editor: TimeTrackable>: View {
    @Binding var editor: Editor
    var timeOnly: Bool = false
    
    private var percentageBinding: Binding<Double> {
        Binding<Double>(
            get: { Double(editor.percentage) },
            set: { editor.percentage = Int($0) }
        )
    }

    var body: some View {
        Section("Time") {
            FullTimePicker(label: "Start Time", selection: $editor.timeStart)
            FullTimePicker(label: "End Time", selection: $editor.timeEnd)
            
            if !timeOnly{
                Toggle("Timed ?", isOn: $editor.timed)
                Slider(
                    value: percentageBinding,
                    in: 0...100,
                    step: 1
                )
                .tint(editor.percentage == 100 ? .gray : .accentColor)
            }
        }
    }
}
