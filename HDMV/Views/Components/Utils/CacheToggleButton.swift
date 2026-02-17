//
//  CacheToggleButton.swift
//  HDMV
//
//  Created by Ghislain Demael on 17.02.2026.
//

import SwiftUI

struct CacheToggleButton<Model: CachableObject>: View {
    var model: Model
    var onToggle: (Model) -> Void

    var body: some View {
        ModelBoolToggleButton(
            isOn: model.cache,
            onSymbol: "iphone.gen1",
            offSymbol: "iphone.gen1.slash",
            action: {
                onToggle(model)
            }
        )
    }
}
