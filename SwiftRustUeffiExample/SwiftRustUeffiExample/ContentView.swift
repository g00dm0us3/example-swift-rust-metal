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
        // Only on 64 bit platforms will this rigmarole make sense!
        let bufferPointer = UnsafeRawPointer(
            bitPattern: UInt(
                allocTexture(
                    width: 8192,
                    height: 8192,
                    pageSize: 4096
                )
            )
        )

        let rusticPi = bufferPointer!
            .bindMemory(to: Float.self, capacity: 8192 * 8192)
            .advanced(by: 8192 * 8192 - 1).pointee

        VStack {
            Image("RustLogo")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Rustic value of 𝝅 = \(rusticPi)")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
