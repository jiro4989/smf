import streams

import smftypes, midistatus, utils

type
  SmfWrite* = ref object
    fileName: string
    header: HeaderChunk
    track: TrackChunk

proc midiStatusByte(status: Status, channel: byte): byte =
  result = status and (channel and 0x0F'u8)

template writeValueTmpl =
  # delta time
  let deltaTime = timeNum.toDeltaTime
  self.track.data.write(deltaTime)
  inc(self.track.dataLength, deltaTime.len)
  # event
  self.track.data.write(midiStatusByte(st, v1))
  inc(self.track.dataLength)
  self.track.data.write(v2)
  inc(self.track.dataLength)

proc writeValue3(self: SmfWrite, timeNum: uint32, st: Status, v1, v2: byte) =
  writeValueTmpl()

proc writeValue4(self: SmfWrite, timeNum: uint32, st: Status, v1, v2, v3: byte) =
  writeValueTmpl()
  self.track.data.write(v3)
  inc(self.track.dataLength)

proc writeMidiNoteOff*(self: SmfWrite, timeNum: uint32, channel, note: byte) =
  ## 3 byte (8n kk vv)
  self.writeValue4(timeNum, stNoteOff, channel, note, 0'u8)

proc writeMidiNoteOn*(self: SmfWrite, timeNum: uint32, channel, note, velocity: byte) =
  ## 3 byte (9n kk vv)
  self.writeValue4(timeNum, stNoteOn, channel, note, velocity)

proc writeMidiPolyphonicKeyPressure*(self: SmfWrite, timeNum: uint32, channel, note, velocity: byte) =
  ## 3 byte (An kk vv)
  self.writeValue4(timeNum, stPolyphonicKeyPressure, channel, note, velocity)

proc writeMidiControlChange*(self: SmfWrite, timeNum: uint32, channel, controller, value: byte) =
  ## 3 byte (Bn cc vv) 特殊なので注意
  self.writeValue4(timeNum, stControlChange, channel, controller, value)

proc writeMidiProgramChange*(self: SmfWrite, timeNum: uint32, channel, program: byte) =
  ## 2 byte (Cn pp)
  # delta time
  self.writeValue3(timeNum, stProgramChange, channel, program)

proc writeMidiChannelPressure*(self: SmfWrite, timeNum: uint32, channel, pressure: byte) =
  ## 2 byte (Dn pp)
  self.writeValue3(timeNum, stChannelPressure, channel, pressure)

proc writeMidiPitchBend*(self: SmfWrite, timeNum: uint32, channel, pitch1, pitch2: byte) =
  ## 2 byte (Dn pp) リトルエンディアンなので注意
  self.writeValue4(timeNum, stPitchBend, channel, pitch1, pitch2)

proc writeMetaEndOfTrack*(self: SmfWrite) =
  ## 4 byte
  self.track.data.write(0'u8)             # delta time
  self.track.data.write(stMetaPrefix)     # meta prefix
  self.track.data.write(meEndOfTrack.ord) # end of track
  self.track.data.write(0'u8)             # data length

proc newHeaderChunk(): HeaderChunk =
  result = HeaderChunk(
    chunkType: headerChunkType,
    format: 0'u16,
    trackCount: 1'u16,
    timeUnit: 0'u16,
  )

proc newTrackChunk(filename: string): TrackChunk =
  result = TrackChunk(
    chunkType: trackChunkType,
    data: newFileStream(filename, fmWrite),
  )

proc openSmfWrite*(filename: string): SmfWrite =
  result = SmfWrite(header: newHeaderChunk(), track: newTrackChunk(filename))
