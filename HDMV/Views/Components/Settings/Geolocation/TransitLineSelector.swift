//
//  TransitLineSelector.swift
//  HDMV
//

import SwiftUI

struct TransitLineSelector: View {
    let transitLine: TransitLine?
    let transitLineRid: Int?
    @Binding var isShowingSelector: Bool
    
    var onSelect: (TransitLine, Int?) -> Void
    var onClear: () -> Void
    
    var body: some View {
        if let line = transitLine {
            VStack(alignment: .leading) {
                HStack {
                    Image(systemName: "tram.fill")
                        .foregroundColor(.blue)
                    Text(line.name)
                        .font(.headline)
                    Spacer()
                }
                
                Divider().padding(.vertical, 4)
                
                Button(role: .destructive) {
                    withAnimation {
                        onClear()
                    }
                } label: {
                    Label("Clear Transit Line", systemImage: "trash.fill")
                        .foregroundStyle(.red)
                }
            }
        } else if let rid = transitLineRid {
            HStack {
                Image(systemName: "exclamationmark.triangle")
                Spacer()
                Text("Uncached Line (ID: \(rid))")
            }
            .foregroundColor(.orange)
            .fontWeight(.semibold)
        } else {
            Button {
                isShowingSelector = true
            } label: {
                Label("Select Transit Line", systemImage: "tram")
            }
        }
    }
}
