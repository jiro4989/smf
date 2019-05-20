import smf

var smfObj = newSMF(headerFormat1, 480)

block:
  var track = newTrackChunk()
  track.add newMIDIEvent(0, statusNoteOn, 0, 0, 0)
  track.add newMIDIEvent(280, statusNoteOff, 0, 0, 0)
  track.add newMIDIEvent(280, statusNoteOn, 0, 0, 0)
  track.add newMIDIEvent(280, statusNoteOff, 0, 0, 0)
  smfObj.add track

block:
  var track = newTrackChunk()
  track.add newMIDIEvent(0, statusNoteOn, 0, 0, 0)
  track.add newMIDIEvent(280, statusNoteOff, 0, 0, 0)
  track.add newMIDIEvent(280, statusNoteOn, 0, 0, 0)
  track.add newMIDIEvent(280, statusNoteOff, 0, 0, 0)
  smfObj.add track

writeSMFFile("test.mid", smfObj)