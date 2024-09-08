//
//  ifs_rendering_shader.metal
//  SwiftRustUeffiExample
//
//  Created by g00dm0us3 on 9/8/24.
//

#include <metal_stdlib>

using namespace metal;

struct Uniforms {
    float4x4 modelMatrix;
};

struct VertexIn {
    packed_float2 pos;
    packed_float2 tex_coord;
};

struct VertexOut {
    float4 position [[position]];
    float2 tex_coord;
    half4 color;
};

vertex VertexOut vertex_function(
                                 constant VertexIn *vertices [[buffer(0)]],
                                 constant Uniforms& uniforms [[buffer(1)]],
                                 uint vid [[vertex_id]]
                                 ) {
    VertexOut out;
    float4 transformedCoords = float4(vertices[vid].pos, 0, 1);

    out.position = transformedCoords;
    out.tex_coord = vertices[vid].tex_coord;
    return out;
}

fragment half4 fragment_function(
                                 VertexOut vertexIn [[stage_in]],
                                 device uint32_t * max_value [[buffer(0)]],
                                 texture2d<uint> result [[texture(0)]]
                                 ) {
    constexpr sampler texture_sampler;

    uint4 sample = (result.sample(texture_sampler, vertexIn.tex_coord));
    float hist_sample =  (sample.r) / (float)(*max_value);

    if (hist_sample <= 0) {
        return half4(0);
    }

    return half4(255.0, 255.0, 255.0, hist_sample);
}
