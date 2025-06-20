//
//  CityRowView.swift
//  HDMV
//
//  Created by Ghislain Demael on 20.06.2025.
//


import SwiftUI

struct CityRowView: View {
    let city: City
    let onRankChanged: (Int) -> Void
    
    @State private var selectedRank: Int

    init(city: City, onRankChanged: @escaping (Int) -> Void) {
        self.city = city
        self.onRankChanged = onRankChanged
        self._selectedRank = State(initialValue: city.rank)
    }
    
    var body: some View {
        HStack {
            Text(city.name)
            Spacer()
            Picker("", selection: $selectedRank) {
                ForEach(1...5, id: \.self) { rank in
                    Text("Rank \(rank)").tag(rank)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
        }
        .onChange(of: selectedRank) { oldValue, newValue in
            onRankChanged(newValue)
        }
    }
}
