//
//  TestView.swift
//  HDMV
//
//  Created by Ghislain Demael on 24.06.2025.
//


// File: TestView.swift
import SwiftUI

struct TestView: View {
    var body: some View {
        VStack {
            // If the error appears on the line below, we know for sure
            // that Xcode is not recognizing your extension file at all.
            Text("The time is: \(DateFormatter.timeOnly.string(from: Date()))")
            
            Text("If you see this view, the test is working.")
        }
    }
}

#Preview {
    TestView()
}