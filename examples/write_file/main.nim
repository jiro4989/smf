import smf

var smfObj = newSMF(format0, 480)

block:
  var track = newTrackChunk()
  for i in 1'u8..20:
    let n: byte = 0x30'u8 + i
    track.add newMIDIEvent(0, statusNoteOn, 0, n, 0x64)
    track.add newMIDIEvent(120, statusNoteOff, 0, n, 0)
  smfObj.add track

writeSMFFile("test.mid", smfObj)

let smfObj2 = readSMFFile("test.mid")
echo smfObj
echo smfObj2