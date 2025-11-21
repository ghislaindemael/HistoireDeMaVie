//
//  PathMetricsRowView.swift
//  HDMV
//
//  Created by Ghislain Demael on 21.11.2025.
//

import SwiftUI

struct PathMetricsRowView: View {
    
    let metrics: PathMetrics
    let showTitle: Bool
    let bubble: Bool
    
    init(
        metrics: PathMetrics,
        showTitle: Bool = true,
        bubble: Bool = true
    ) {
        self.metrics = metrics
        self.showTitle = showTitle
        self.bubble = bubble
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            if showTitle {
                Text("Custom Metrics")
                    .padding(.bottom, 2)
            }
            HStack(spacing: 12) {
                Label("\(metrics.distance.formatted()) m", systemImage: "ruler")
                Label("+\(metrics.elevationGain.formatted()) m", systemImage: "arrow.up.right")
                Label("-\(metrics.elevationLoss.formatted()) m", systemImage: "arrow.down.right")
                Spacer()
            }
            .foregroundStyle(.secondary)
            if let metrics = metrics.pathDescription, !metrics.isEmpty {
                Text(metrics)
                    .foregroundStyle(.secondary)
            }
        }
        .if(bubble) { view in
            view
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.primaryBackground)
                )
        }
    }
}


