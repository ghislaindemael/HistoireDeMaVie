//
//  CityNodeView.swift
//  HDMV
//

import SwiftUI

struct CityNodeView: View {
    let city: City
    @ObservedObject var viewModel: CitiesPageViewModel
    @Binding var cityToEdit: City?
    
    var body: some View {
        if city.sortedChildren.isEmpty {
            rowContent
        } else {
            DisclosureGroup {
                ForEach(city.sortedChildren) { child in
                    CityNodeView(city: child, viewModel: viewModel, cityToEdit: $cityToEdit)
                }
                .onDelete { offsets in
                    for index in offsets {
                        viewModel.deleteItem(city.sortedChildren[index])
                    }
                }
            } label: {
                rowContent
            }
        }
    }
    
    private var rowContent: some View {
        Button(action: { cityToEdit = city }) {
            CityRowView(city: city) { c in
                withAnimation(.snappy) {
                    viewModel.updateModel(c) { concreteCity in
                        concreteCity.cache.toggle()
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
}
