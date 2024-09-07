uniffi::include_scaffolding!("lib");

use std::alloc::{alloc, Layout};
use std::mem::size_of;

pub fn alloc_texture(
    width: u64,
    height: u64,
    page_size: u64
) -> u64 {
    let result: *mut u8;

    let width = width as usize;
    let height = height as usize;
    let page_size = page_size as usize;

    unsafe {
        let layout = Layout::from_size_align(width * height * size_of::<f32>(), page_size).expect("Layout");

        result = alloc(layout); 

        println!("Allocated {} bytes", layout.size());
    }

    return result as u64;
}

// ... classes with methods ...
pub struct Greeter {
    name: String,
}

impl Greeter {
    // By convention, a method called new is exposed as a constructor
    pub fn new(name: String) -> Self {
        Self { name }
    }

    pub fn greet(&self) -> String {
        format!("Hello, {}!", self.name)
    }
}

// ... and much more! For more information about bindings, read the UniFFI book: https://mozilla.github.io/uniffi-rs/udl_file_spec.html