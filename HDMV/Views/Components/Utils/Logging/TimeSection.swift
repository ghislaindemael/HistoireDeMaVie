//
//  TimeSection.swift
//  HDMV
//
//  Created by Ghislain Demael on 22.10.2025.
//

import SwiftUI

struct TimeSection<Editor: TimeBound>: View {
    @Binding var editor: Editor
    
    private var isTrackable: Bool {
        editor is any TimeTrackable
    }
    
    private var timedBinding: Binding<Bool> {
        Binding<Bool>(
            get: {
                (editor as? any TimeTrackable)?.timed ?? false
            },
            set: { newValue in
                if var trackableEditor = editor as? any TimeTrackable {
                    trackableEditor.timed = newValue
                    if let casted = trackableEditor as? Editor {
                        editor = casted
                    }
                }
            }
        )
    }
    
    private var percentageBinding: Binding<Double> {
        Binding<Double>(
            get: {
                Double((editor as? any TimeTrackable)?.percentage ?? 0)
            },
            set: { newValue in
                if var trackableEditor = editor as? any TimeTrackable {
                    trackableEditor.percentage = Int(newValue)
                    if let casted = trackableEditor as? Editor {
                        editor = casted
                    }
                }
            }
        )
    }

    var body: some View {
        Section("Time") {
            FullTimePicker(label: "Start Time", selection: $editor.timeStart)
            FullTimePicker(label: "End Time", selection: $editor.timeEnd)
            
            if isTrackable {
                Toggle("Timed ?", isOn: timedBinding)
                
                Slider(
                    value: percentageBinding,
                    in: 0...100,
                    step: 1
                )
                .tint(percentageBinding.wrappedValue == 100 ? .gray : .accentColor)
            }
        }
    }
}
