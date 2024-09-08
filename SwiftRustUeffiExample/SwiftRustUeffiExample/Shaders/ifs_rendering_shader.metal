//
//  ifs_rendering_shader.metal
//  SwiftRustUeffiExample
//
//  Created by g00dm0us3 on 9/8/24.
//

#include <metal_stdlib>

#define HEX_COLOR(code) float3(((code & 0xFF0000) >> 16), ((code & 0xFF00) >> 8), (code & 0xFF))

using namespace metal;
typedef struct rgb {
    float r, g, b;
} RGB;

typedef struct hsl {
    float h, s, l;
} HSL;

/*
 * Converts an RGB color value to HSL. Conversion formula
 * adapted from http://en.wikipedia.org/wiki/HSL_color_space.
 * Assumes r, g, and b are contained in the set [0, 255] and
 * returns HSL in the set [0, 1].
 */
inline HSL rgb2hsl(float r, float g, float b) {

    HSL result;

    r /= 255;
    g /= 255;
    b /= 255;

    float max_ = max(max(r,g),b);
    float min_ = min(min(r,g),b);

    result.h = result.s = result.l = (max_ + min_) / 2;

    if (max_ == min_) {
        result.h = result.s = 0; // achromatic
    }
    else {
        float d = max_ - min_;
        result.s = (result.l > 0.5) ? d / (2 - max_ - min_) : d / (max_ + min_);

        if (max_ == r) {
            result.h = (g - b) / d + (g < b ? 6 : 0);
        }
        else if (max_ == g) {
            result.h = (b - r) / d + 2;
        }
        else if (max_ == b) {
            result.h = (r - g) / d + 4;
        }

        result.h /= 6;
    }

    return result;

}

inline float hue2rgb(float p, float q, float t) {

    if (t < 0)
        t += 1;
    if (t > 1)
        t -= 1;
    if (t < 1./6)
        return p + (q - p) * 6 * t;
    if (t < 1./2)
        return q;
    if (t < 2./3)
        return p + (q - p) * (2./3 - t) * 6;

    return p;

}

inline RGB hsl2rgb(float h, float s, float l) {

    RGB result;

    if(0 == s) {
        result.r = result.g = result.b = l; // achromatic
    }
    else {
        float q = l < 0.5 ? l * (1 + s) : l + s - l * s;
        float p = 2 * l - q;
        result.r = hue2rgb(p, q, h + 1./3) * 255;
        result.g = hue2rgb(p, q, h) * 255;
        result.b = hue2rgb(p, q, h - 1./3) * 255;
    }

    return result;

}

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

inline RGB map_color(float3 start_color,
                     float3 end_color,
                     float3 color_range,
                     float alpha_val
                     ) {

    RGB result;
    // magical, gonna use it for now
    float gamma = log(alpha_val+1) / (alpha_val);

    // color depends on number of hits - more hits, brighter color
    // (1.1 - gamma) - decreases as exp(-(hits^2)) (super fast)
    // saturation and lghtness are directly proportional to the values in rgb channels
    result.r = min((1.1 - gamma)*(start_color.x + alpha_val*color_range.x), end_color.r); // R
    result.g = min((1.1 - gamma)*(start_color.y + alpha_val*color_range.y), end_color.g); // G
    result.b = min((1.1 - gamma)*(start_color.z + alpha_val*color_range.z), end_color.b); // B

    return result;
}

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
                                 texture2d<uint32_t> result [[texture(0)]]
                                 ) {
    constexpr sampler texture_sampler (mag_filter::linear, min_filter::linear);
    float hist_sample = result.sample(texture_sampler, vertexIn.tex_coord).r / (float)(*max_value);

//    if (hist_sample <= 0) {
//        return half4(0);
//    }

    float3 palette_start = HEX_COLOR(0x03045e);
    float3 palette_end = HEX_COLOR(0xade8f4);
    float3 distance = palette_end - palette_start;

    RGB rgb = map_color(palette_start, palette_end, distance, hist_sample);
    HSL hsl = rgb2hsl(rgb.r, rgb.g, rgb.b);

    // more hits - more saturation
    // gamma falls as 2^(-2*(x^hits))
    // x^hits - we assume exponential distribution of number of hits, while running original chaos game
    // using siply x^-hits significantly reduces saturation))
    hsl.s = pow(hsl.s, exp2(-2*hist_sample));
    rgb = hsl2rgb(hsl.h, hsl.s, hsl.l);

    return half4(rgb.r / 255.0, rgb.g / 255.0, rgb.b / 255.0, hist_sample);
    //return half4(0.5, 0.5, 0.5, hist_sample);
}
