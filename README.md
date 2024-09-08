# example-swift-rust-metal
A small example of turning your Rust library into Swift package.

![triangle drawing][tree_drawing.gif]

## What? Why?
So, I had this idea, that low-level, CPU intensive stuff works much better in C, than in Swift. Especially when it comes to playing with pointers.
I am not really sure if that's true, but nonetheless. C is just a fun language. Unfortunately it is also extremely bare-bones,
and doesn't provide enough abstraction.
C++ is hotter, but it requires a significant time investment. Like a really hefty chunk of your lifetime.

Rust is the one to rule them all then, all things considered. Also, it's super satisfying to write in Rust.

Take for example this repo. All it does is it draws a Sierpinski triangle, using "chaos game" algorithm. Basically it
crunches hundres of thousands of iterations, saving at each iteration something in  the chunk of memory, which it has been given.
Not a particularly useful piece of software, but fun to write nonetheless, in no small part thanks to borrow checker.

A more detailed overview of the process:

1. Allocate ```IOSurface```, create ```MTLTexture``` with it.
2. Pass raw pointer as a ```u64``` down to Rust library. Let it crunch.
3. Tell ```MTKView``` to draw whatever has been crunched.

The result is the peculiar image, which gradually appears clearer and clearer on the screen. Performance metrics also are... Not completely terrible. But then again I have nothing to compare to.

## How to build it?

To build install cargo-swift:

```cargo install cargo-swift```

Then navigate to the "example" directory, and run:

```cargo swift package -n ExamplePackage -p ios```

On any change in Rust lib code, re-run the command above (or use script build phase). 

This will generate the missing ```.xcframework```

After this, build and run the iOS project.

## References

[cargo-swift tool](https://github.com/antoniusnaumann/cargo-swift)

[The only tutorial on how to integrate Rust in iOS](https://krirogn.dev/blog/integrate-rust-in-ios)

[UniFFI User Guide](https://mozilla.github.io/uniffi-rs/latest/Motivation.html)

[UniFFI Github Examples](https://github.com/mozilla/uniffi-rs/tree/main/examples)
