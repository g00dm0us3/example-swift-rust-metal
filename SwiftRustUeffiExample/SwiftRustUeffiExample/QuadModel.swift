//
//  QuadModel.swift
//  SwiftRustUeffiExample
//
//  Created by g00dm0us3 on 9/8/24.
//

import Metal

struct QuadModel {
    let buffer: MTLBuffer

    let vertexCount: Int

    init(device: MTLDevice) {
        var res = [Float]()

        let minX = Float(-1)
        let maxX = Float(1)

        let minY = Float(-1)
        let maxY = Float(1)

        let minTexX = Float(0)
        let maxTexX = Float(1)

        let minTexY = Float(0)
        let maxTexY = Float(1)

        res.append(contentsOf: [minX, minY, minTexX, minTexY])
        res.append(contentsOf: [minX, maxY, minTexX, maxTexY])
        res.append(contentsOf: [maxX, minY, maxTexX, minTexY])

        res.append(contentsOf: [maxX, minY, maxTexX, minTexY])
        res.append(contentsOf: [maxX, maxY, maxTexX, maxTexY])
        res.append(contentsOf: [minX, maxY, minTexX, maxTexY])

        buffer = device.makeBufferFor(array: res)!
        self.vertexCount = 6
    }
}

extension MTLDevice {
    func makeBufferFor(array: [Float]) -> MTLBuffer? {
        var _bytes = array
        return self.makeBuffer(
            bytes: &_bytes,
            length: array.count * MemoryLayout<Float>.size,
            options: .storageModeShared
        )
    }
}

