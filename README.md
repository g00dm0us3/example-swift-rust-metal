# example-uniffi-swift
A small example of turning your Rust library into Swift package.

To build install cargo-swift:

```cargo install cargo-swift```

Then navigate to the "example" directory, and run:

```cargo swift package```

This will generate the missing ```.xcframework```

After this, build and run the iOS project.

This example was created using [cargo-swift tool.](https://github.com/antoniusnaumann/cargo-swift)

Additional info on turning your Rust library into package can be found in the following places:

[The only tutorial on how to integrate Rust in iOS](https://krirogn.dev/blog/integrate-rust-in-ios)

[UniFFI User Guide](https://mozilla.github.io/uniffi-rs/latest/Motivation.html)

[UniFFI Github Examples](https://github.com/mozilla/uniffi-rs/tree/main/examples)
