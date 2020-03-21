import unittest

include smf/reader

const midiFile = "tests/test.mid"

suite "readSMF":
  test "normal":
    let got = readSMF(midiFile)
    echo got[]