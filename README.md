# pico-zdk

a project which builds as library with Zig and then links it into a program that uses the Pico-SDK.

To enable the use of the Zig standard library an (incomplete) IO layer was written that uses basic Standard C functions for File IO and the POSIX Socket API for Networking.
Support for File IO is provided through LittleFS and Networking is implemented through Lwip.
Lwip only supports POSIX sockets when used on a multitasking system for which FreeRTOS was chosen.

For demo purposes `main.c` will call functions to test stdout IO, File IO and depending on if Networking is available either Zigs stdlib HTTP Server or a test panic.

## requirements
- ~0.16.0-dev.2319
- [pico-sdk](https://github.com/raspberrypi/pico-sdk)
- arm gcc compiler
- newlib libc

## cmake-zig
additionally this repo contains `cmake/zig-import`
it implements a function to import all zig targets into cmake and allows using them as well as automatic rebuilds of dependees if any change was made to the zig side.

## license
pico-zdk is licensed under MIT
