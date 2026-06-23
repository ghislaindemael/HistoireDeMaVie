//
//  FlowLayout.swift
//  HDMV
//
//  Created for wrapping horizontal views
//

import SwiftUI

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var height: CGFloat = 0
        var width: CGFloat = 0
        
        for row in rows {
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            height += rowHeight
            
            let rowWidth = row.reduce(0) { $0 + $1.sizeThatFits(.unspecified).width } + CGFloat(max(row.count - 1, 0)) * spacing
            width = max(width, rowWidth)
        }
        
        height += CGFloat(max(rows.count - 1, 0)) * spacing
        
        return CGSize(width: proposal.width ?? width, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            
            for subview in row {
                let size = subview.sizeThatFits(.unspecified)
                subview.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
                x += size.width + spacing
            }
            y += rowHeight + spacing
        }
    }
    
    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[LayoutSubview]] {
        var rows: [[LayoutSubview]] = [[]]
        var currentWidth: CGFloat = 0
        let maxWidth = proposal.width ?? .infinity
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentWidth + size.width > maxWidth, !rows[rows.count - 1].isEmpty {
                rows.append([subview])
                currentWidth = size.width + spacing
            } else {
                rows[rows.count - 1].append(subview)
                currentWidth += size.width + spacing
            }
        }
        
        return rows
    }
}
