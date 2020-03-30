import unittest, os

include smf/smfwrite

let outDir = "tests"/"out"

suite "case: writing midi file":
  test "normal":
    var smf = openSmfWrite(outDir/"case1.mid")
    let
      channel = 0'u8
      note = 49'u8
      velocity = 100'u8
    smf.writeMidiNoteOn(0'u32, channel, note, velocity)
    smf.writeMidiNoteOff(120'u32, channel, note)
    smf.writeMetaEndOfTrack()
    smf.close()
