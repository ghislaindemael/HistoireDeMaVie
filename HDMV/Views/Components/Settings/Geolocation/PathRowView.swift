//
//  PlaceRowView.swift
//  HDMV
//
//  Created by Ghislain Demael on 20.06.2025.
//


import SwiftUI

struct PathRowView: View {
    @Bindable var path: Path
    
    var body: some View {
        VStack (alignment: .leading) {
            HStack {
                if let name = path.name {
                    Text(name)
                } else {
                    Text("Name unset")
                        .bold()
                        .foregroundStyle(.red)
                }
                Spacer()
                SyncStatusIndicator(status: path.syncStatus)
            }
            PlaceDisplayView(placeRid: path.placeStart?.rid)
            HStack {
                Image(systemName: "arrow.turn.down.right")
                PlaceDisplayView(placeRid: path.placeEnd?.rid)
            }
            if let details = path.details {
                Text(details)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(UIColor.secondarySystemBackground))
                    )

            }
        }
    }
}
