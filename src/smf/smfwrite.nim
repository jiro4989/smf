import streams, endians

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
  for d in deltaTime:
    self.track.data.write(d)
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
  self.track.data.write(0'u8)         # delta time
  self.track.data.write(stMetaPrefix) # meta prefix
  self.track.data.write(meEndOfTrack) # end of track
  self.track.data.write(0'u8)         # data length
  inc(self.track.dataLength, 4)

proc newHeaderChunk(timeUnit: uint16): HeaderChunk =
  result = HeaderChunk(
    chunkType: headerChunkType,
    dataLength: 6'u32,
    format: 0'u16,
    trackCount: 1'u16,
    timeUnit: timeUnit,
  )

proc newTrackChunk(): TrackChunk =
  result = TrackChunk(
    chunkType: trackChunkType,
    data: newStringStream(),
  )

proc openSmfWrite*(filename: string, timeUnit: uint16): SmfWrite =
  result = SmfWrite(
    filename: filename,
    header: newHeaderChunk(timeUnit),
    track: newTrackChunk(),
  )

template writeBigEndian(s: Stream, data: uint16) =
  block:
    var date2: uint16
    bigEndian16(addr(date2), addr(data))
    s.write(date2)

template writeBigEndian(s: Stream, data: uint32) =
  block:
    var date2: uint32
    bigEndian32(addr(date2), addr(data))
    s.write(date2)

proc close*(self: SmfWrite) =
  self.writeMetaEndOfTrack()

  var outfile = newFileStream(self.filename, fmWrite)

  # write header
  let h = self.header
  outfile.write(h.chunkType)
  outfile.writeBigEndian(h.dataLength)
  outfile.write(h.format)
  outfile.writeBigEndian(h.trackCount)
  outfile.writeBigEndian(h.timeUnit)

  # write track
  outfile.write(self.track.chunkType)
  outfile.writeBigEndian(self.track.dataLength)
  self.track.data.setPosition(0)
  const bufSize = 1024
  var buffer: array[bufSize, byte]
  while true:
    let writtenSize = self.track.data.readData(addr(buffer), bufSize)
    if writtenSize == bufSize:
      outFile.write(buffer)
    elif 0 < writtenSize:
      for i in 0..<writtenSize:
        outFile.write(buffer[i])
    else:
      if self.track.data.atEnd:
        break
  outfile.close()
  self.track.data.close()
