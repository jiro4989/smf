import smf
import strformat

for i in 1..128:
  var smfObj = newSMF(format0, 480)

  var track = newTrackChunk()
  #track.add newMetaEvent(0, metaText, "Test text")
  for n in 30'u8..50:
    track.add newMIDIEvent(0, statusNoteOn, 0, n, 0x64)
    track.add newMIDIEvent(120, statusNoteOff, 0, n, 0)
  smfObj.add track

  let outfn = &"out/{i:03}.mid"
  writeSMFFile(outfn, smfObj)
  echo outfn, " is generated."
