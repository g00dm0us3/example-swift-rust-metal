//
//  TriangleView.swift
//  SwiftRustUeffiExample
//
//  Created by g00dm0us3 on 9/8/24.
//

import SwiftUI
import MetalKit
import IOSurface
import ExamplePackage

struct TriangleView: UIViewRepresentable {
    typealias UIViewType = MTKView

    private let device: MTLDevice
    private var delegate: MetalViewDelegate

    init() {
        let device = MTLCreateSystemDefaultDevice()!

        self.device = device
        self.delegate = MetalViewDelegate(
            renderer: Renderer(
                device: device
            )
        )
    }

    func makeUIView(
        context: Context
    ) -> MTKView {
        let mtkView = MTKView(frame: .zero, device: device)
        mtkView.delegate = delegate
        mtkView.preferredFramesPerSecond = 60
        mtkView.backgroundColor = context.environment.colorScheme == .dark ? UIColor.black : UIColor.white
        mtkView.isOpaque = true
        //mtkView.enableSetNeedsDisplay = true
        return mtkView
    }

    func updateUIView(
        _ uiView: MTKView,
        context: Context
    ) {}
}

// MARK: - MetalViewDelegate
extension TriangleView {
    final class MetalViewDelegate: NSObject, MTKViewDelegate {
        private let renderer: Renderer

        init(
            renderer: Renderer
        ) {
            self.renderer = renderer
        }

        func mtkView(
            _ view: MTKView,
            drawableSizeWillChange size: CGSize
        ) {
            renderer.drawableSize = size
        }

        func draw(in view: MTKView) {
            guard let drawable = view.currentDrawable else { return }
            renderer.render(
                with: drawable
            )
        }
    }
}

// MARK: - Renderer
extension TriangleView {
    final class Renderer {
        private let device: MTLDevice

        private var didSetNonzeroSize = false
        var drawableSize: CGSize = .zero {
            didSet {
                if drawableSize != .zero && !didSetNonzeroSize {
                    didSetNonzeroSize = true
                    sierpinskiTriangleDrawer = .init(
                        iterationsPerStep: 10000,
                        iterationLimit: 5 * drawableSize.minArea
                    )

                    sierpinskiTriangleDrawer?.setHeight(height: drawableSize.minHeight)
                    sierpinskiTriangleDrawer?.setWidth(width: drawableSize.minWidth)
                }
            }
        }

        private lazy var commandQueue: MTLCommandQueue =  {
            guard let commandQueue = device.makeCommandQueue() else {
                fatalError("Cannot create command queue!")
            }

            return commandQueue
        }()

        private lazy var triangleSurface: IOSurfaceRef? = {
            precondition(didSetNonzeroSize, "Drawable size should be non-zero!")

            return IOSurfaceCreate([
                kIOSurfaceWidth: UInt16(drawableSize.width),
                kIOSurfaceHeight: UInt16(drawableSize.height),
                kIOSurfaceBytesPerElement: 4
            ] as CFDictionary)
        }()

        private var sierpinskiTriangleDrawer: SierpinskyTriangleDrawer?

        init(
            device: MTLDevice
        ) {
            self.device = device
        }

        func render(
            with drawable: CAMetalDrawable
        ) {
            guard let sierpinskiTriangleDrawer else { return }
            guard let triangleSurface else { return }

            guard !sierpinskiTriangleDrawer.isDone() else { return }

            IOSurfaceLock(triangleSurface, .avoidSync, nil)

            let baseAddress = UInt64(
                bitPattern: Int64(
                    Int(
                        bitPattern: IOSurfaceGetBaseAddress(triangleSurface)
                    )
                )
            )
            let max = sierpinskiTriangleDrawer.updateDrawing(drawingData: baseAddress)

            IOSurfaceUnlock(triangleSurface, .avoidSync, nil)

            print("\(max)")
//            let commandBuffer = makeCommandBuffer()
//
//            commandBuffer.commit()
//            commandBuffer.present(drawable)
        }

        private func makeCommandBuffer() -> MTLCommandBuffer {
            guard let commandBuffer = commandQueue.makeCommandBuffer() else {
                fatalError("CAnnot create command buffer!")
            }

            return commandBuffer
        }
    }
}

// MARK: - Util
private extension CGSize {
    var minArea: UInt32 {
        UInt32(floor(width * height))
    }

    var minWidth: UInt16 {
        UInt16(floor(width))
    }

    var minHeight: UInt16 {
        UInt16(floor(height))
    }
}
