# Package

version       = "0.1.0"
author        = "jiro4989"
description   = "smf is library for SMF (Standard MIDI File)"
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 0.19.4"

task examples, "Run example code":
  withDir "examples/write_file":
    exec "nim c -d:release main.nim"
    exec "./main"