# pico-zdk

a project which builds as library with Zig and then links it into a program that uses the Pico-SDK.

To facilitate the use of the Zig standard library an (incomplete) IO layer was implemented using libc functions available in newlib, the libc implementation used by the Pico-SDK.

Support for custom filesystems and such needs to be implemented on the C side, newlib implements common IO functions like open, read, write, etc. as wrappers to their underrscored variant e.g. open calls \_open which you are expected to provide.
The Pico-SDK provides a weak \_write implementation only designed to support writing to STDOUT and STDERR.

## requirements
- Zig master

## cmake-zig
additionally this repo contains `cmake/zig-import`
it implements a function to import all zig targets into cmake and allows using them as well as automatic rebuilds of dependees if any change was made to the zig side.

## license
The Zig standard library was heavily referenced during the creation of this and as such this project is licensed under the same license as the ziglang project
