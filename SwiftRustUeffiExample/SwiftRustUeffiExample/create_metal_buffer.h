//
//  create_metal_buffer.h
//  SwiftRustUeffiExample
//
//  Created by g00dm0us3 on 9/7/24.
//

#ifndef create_metal_buffer_h
#define create_metal_buffer_h

#include <inttypes.h>

float * make_buffer(
                    uint64_t width,
                    uint64_t height,
                    uint64_t page_size
                    );

#endif /* create_metal_buffer_h */
