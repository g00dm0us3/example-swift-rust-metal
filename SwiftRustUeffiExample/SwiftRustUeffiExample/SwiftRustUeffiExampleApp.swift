//
//  SwiftRustUeffiExampleApp.swift
//  SwiftRustUeffiExample
//
//  Created by g00dm0us3 on 9/7/24.
//

import SwiftUI
import ExamplePackage

@main
struct SwiftRustUeffiExampleApp: App {
    let buffer = make_buffer(8192, 8192, 4096);

    var body: some Scene {
        print(buffer?.advanced(by: 8192*8192-1).pointee)

        return WindowGroup {
            ContentView()
        }
    }
}
