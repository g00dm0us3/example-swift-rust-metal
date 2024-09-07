//
//  ContentView.swift
//  SwiftRustUeffiExample
//
//  Created by g00dm0us3 on 9/7/24.
//

import ExamplePackage
import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text(Greeter(name: "Rust").greet())
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
