//
//  create_metal_buffer.c
//  SwiftRustUeffiExample
//
//  Created by g00dm0us3 on 9/7/24.
//

#include "create_metal_buffer.h"
#include "exampleFFI.h"

#include <Metal/Metal.h>

static RustBuffer rust_buffer;
static RustCallStatus call_status;

RustCallStatus * get_static_call_status(void) {

    call_status.code = 0;
    call_status.errorBuf = rust_buffer;

    return &call_status;
}

float * make_buffer(
                    uint64_t width,
                    uint64_t height,
                    uint64_t page_size
                    ) {

    // I decided not to use Swift for this, as UnsafeRawPoiter(bitPattern:) constructor has been refactored into oblivion.
    float * buff = (float *)uniffi_example_fn_func_alloc_texture(width, height, page_size, get_static_call_status());

    buff[(width*height)-1] = 3.14159265397323;

    return buff;
}

