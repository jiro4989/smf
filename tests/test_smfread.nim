import unittest

include smf/smfread

const midiFile = "tests/test.mid"

suite "readSMF":
  test "normal":
    const
      headerSize = 14
      trackHeadSize = 8
      endOfTrackSize = 3
    var f = open(midiFile)
    let
      size = f.getFileSize
      got = openSmfReadFile(midiFile)
      trackSize = got.track.dataLength
    echo got[]
    f.close
    check size == headerSize + trackHeadSize + trackSize.int + endOfTrackSize
