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

        delegate.renderer.initRenderingPipeline(with: mtkView.colorPixelFormat)
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
        let renderer: Renderer

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
            renderer.render(
                in: view
            )
        }
    }
}

// MARK: - Renderer
// - TODO: refactor.
extension TriangleView {
    final class Renderer {
        private let device: MTLDevice

        private lazy var defaultLibrary = device.makeDefaultLibrary()!

        private lazy var model = QuadModel(
            device: device
        )

        private var didSetNonzeroSize = false
        var drawableSize: CGSize = .zero {
            didSet {
                if drawableSize != .zero && !didSetNonzeroSize {
                    didSetNonzeroSize = true
                    sierpinskiTriangleDrawer = .init(
                        iterationsPerStep: 6000,
                        iterationLimit: 5 * UInt32(drawableSize.minWidth) * UInt32(drawableSize.minWidth)
                    )

                    sierpinskiTriangleDrawer?.setHeight(height: 4 * drawableSize.minWidth)
                    sierpinskiTriangleDrawer?.setWidth(width: drawableSize.minWidth)
                }
            }
        }

        private lazy var triangleSurface: IOSurfaceRef? = {
            precondition(didSetNonzeroSize, "Drawable size should be non-zero!")

            return IOSurfaceCreate([
                kIOSurfaceWidth: UInt16(drawableSize.minWidth),
                kIOSurfaceHeight: UInt16(4 * drawableSize.minWidth),
                kIOSurfaceBytesPerElement: 4,
                // This has to be multiple of 16. Hence, multiplying it by 4,
                // Meaning that width has to be 4 time it's initial value.
                // Have to adjust height in the same way.

                // - TODO: there must be a better way of doing this.
                kIOSurfaceBytesPerRow: 4 * 4 * UInt16(drawableSize.minWidth)
            ] as CFDictionary)
        }()

        private var sierpinskiTriangleDrawer: SierpinskyTriangleDrawer?
        private var pipeline: RenderingPipeline?

        private lazy var texture = makeTexture()!

        init(
            device: MTLDevice
        ) {
            self.device = device
        }

        func initRenderingPipeline(
            with pixelFormat: MTLPixelFormat
        ) {
            guard pipeline == nil else { return }
            pipeline = .init(
                device: device,
                library: defaultLibrary,
                pixelFormat: pixelFormat
            )
        }

        func render(
            in view: MTKView
        ) {
            guard let currentRenderPassDescriptor = view.currentRenderPassDescriptor else { return }
            guard let drawable = view.currentDrawable else { return }
            guard let pipeline else { return }

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

            var max = sierpinskiTriangleDrawer.updateDrawing(drawingData: baseAddress)

            IOSurfaceUnlock(triangleSurface, .avoidSync, nil)

            let commandBuffer = makeCommandBuffer()
            
            let renderEncoder = commandBuffer.makeRenderCommandEncoder(
                descriptor: currentRenderPassDescriptor
            )!

            renderEncoder.setRenderPipelineState(pipeline.pipelineState)

            renderEncoder.setVertexBuffer(model.buffer, offset: 0, index: 0);
            renderEncoder.setVertexBuffer(modelMatrixBuffer, offset: 0, index: 1)

            memcpy(
                maxValBuffer.contents(),
                &max,
                MemoryLayout<UInt32>.stride
            )

            renderEncoder.setFragmentBuffer(maxValBuffer, offset: 0, index: 0)
            renderEncoder.setFragmentTexture(texture, index: 0)

            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: model.vertexCount)

            renderEncoder.endEncoding()
            commandBuffer.present(drawable)

            commandBuffer.commit()
        }

        // MARK: - Shader Argument Management
        private func allocateBuffer(
            size: Int
        ) -> MTLBuffer? {
            device.makeBuffer(
                length: size,
                options: .storageModeShared
            )
        }

        private lazy var maxValBuffer = {
            allocateBuffer(size: MemoryLayout<UInt32>.stride)!
        }()

        private lazy var modelMatrixBuffer = {
            var modelMatrix = self.modelMatrix

            let size = MemoryLayout<simd_float4x4>.stride
            let buffer = self.allocateBuffer(size: size)

            memcpy(
                buffer?.contents(),
                &modelMatrix, size
            )

            return buffer
        }()

        private lazy var modelMatrix = makeModelMatrix()
        private func makeModelMatrix() -> simd_float4x4 {
            let aspect = Float(drawableSize.width / drawableSize.height)

            return simd_float4x4(rows:[
                SIMD4<Float>(1, 0,     0, 0),
                SIMD4<Float>(0,     aspect, 0, 0),
                SIMD4<Float>(0,     0,     1, 0),
                SIMD4<Float>(0,     0,     0, 1)
            ])
        }

        // MARK: - Factories
        private func makeCommandBuffer() -> MTLCommandBuffer {
            guard let commandBuffer = pipeline?.commandQueue.makeCommandBuffer() else {
                fatalError("aAnnot create command buffer!")
            }

            return commandBuffer
        }

        private func makeTexture() -> MTLTexture? {
            guard let triangleSurface else {
                return nil
            }

            let descriptor = MTLTextureDescriptor()

            descriptor.usage = .shaderRead
            descriptor.pixelFormat = .rgba8Uint
            descriptor.width = Int(drawableSize.minWidth)
            descriptor.height = Int(drawableSize.minWidth)

            return device.makeTexture(
                descriptor: descriptor,
                iosurface: triangleSurface,
                plane: 0
            )
        }
    }

    struct RenderingPipeline {
        let pipelineState: MTLRenderPipelineState
        let commandQueue: MTLCommandQueue

        init(
            device: MTLDevice,
            library: MTLLibrary,
            pixelFormat: MTLPixelFormat
        ) {
            print(UIScreen.main.scale)
            let pipelineStateDescriptor = MTLRenderPipelineDescriptor()

            pipelineStateDescriptor.vertexFunction = library.makeFunction(name: "vertex_function")
            pipelineStateDescriptor.fragmentFunction = library.makeFunction(name: "fragment_function")
            pipelineStateDescriptor.colorAttachments[0].pixelFormat = pixelFormat

            pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
            commandQueue = device.makeCommandQueue()!
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
