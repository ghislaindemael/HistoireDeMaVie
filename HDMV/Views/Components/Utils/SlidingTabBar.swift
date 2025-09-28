//
//  SlidingTabBar.swift
//  HDMV
//
//  Created by Ghislain Demael on 28.09.2025.
//

import SwiftUI

struct SlidingTabBar: View {
    @Binding var selectedTab: Tab
    let tabs = Tab.allCases
    
    @State private var offset: CGFloat = 0
    private let visibleCount = 5
    
    var body: some View {
        GeometryReader { geo in
            let tabWidth = geo.size.width / CGFloat(visibleCount)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(tabs, id: \.self) { tab in
                        tabButton(tab, tabWidth: tabWidth)
                    }
                }
                .offset(x: offset)
            }
            .gesture(
                DragGesture()
                    .onEnded { value in
                        var newOffset = offset + value.translation.width
                        
                        newOffset = round(newOffset / tabWidth) * tabWidth
                        
                        let maxOffset: CGFloat = 0
                        let minOffset: CGFloat = -tabWidth * CGFloat(tabs.count - visibleCount)
                        newOffset = min(max(newOffset, minOffset), maxOffset)
                        
                        withAnimation(.easeOut) {
                            offset = newOffset
                        }
                    }
            )
        }
        .frame(height: 40)
        .padding(.top, 5)
        .background(.ultraThinMaterial)
    }
    
    @ViewBuilder
    private func tabButton(_ tab: Tab, tabWidth: CGFloat) -> some View {
        Button {
            selectedTab = tab
        } label: {
            VStack {
                Image(systemName: tab.icon)
                    .imageScale(.large)
                Text(tab.title)
                    .font(.caption)
            }
            .frame(width: tabWidth, height: 50)
            .foregroundColor(selectedTab == tab ? .blue : .gray)
        }
    }
    
    private func shift(by steps: Int, tabWidth: CGFloat) {
        withAnimation {
            offset += CGFloat(steps) * -tabWidth
        }
    }
}
