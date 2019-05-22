# Package

version       = "0.1.0"
author        = "jiro4989"
description   = "smf is library for SMF (Standard MIDI File)"
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 0.19.4"

import strformat

task docs, "Generate documents":
  exec "nimble doc src/smf.nim -o:docs/smf.html"
  for m in ["types", "consts", "utils", "parse"]:
    exec &"nimble doc src/smf/{m}.nim -o:docs/{m}.html"

task examples, "Run example code":
  withDir "examples/write_file":
    exec "nim c -d:release main.nim"
    exec "./main"

task ci, "Run CI tasks":
  exec "nimble test"
  exec "nimble docs"
  exec "nimble examples"
