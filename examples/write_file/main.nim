import smf

var smfObj = newSMF(format0, 480)

block:
  var track = newTrackChunk()
  track.add newMIDIEvent(0, statusNoteOn, 0, 1, 40)
  track.add newMIDIEvent(240, statusNoteOff, 0, 1, 0)
  smfObj.add track

writeSMFFile("test.mid", smfObj)