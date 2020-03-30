import streams

import smftypes, midistatus, utils

type
  SmfWrite* = ref object
    fileName: string
    header: HeaderChunk
    track: TrackChunk

proc midiStatusByte(status: Status, channel: byte): byte =
  result = status and (channel and 0x0F'u8)

proc writeMidiNoteOff*(self: SmfWrite, timeNum: uint32, channel, note: byte) =
  ## 3 byte (8n kk vv)
  # delta time
  self.track.data.write(timeNum.toDeltaTime)
  # MIDI event
  # 8n
  self.track.data.write(midiStatusByte(stNoteOff, channel))
  # kk
  self.track.data.write(note)
  # vv
  self.track.data.write(0'u8)

proc writeMidiNoteOn*(self: SmfWrite, timeNum: uint32, channel, note, velocity: byte) =
  ## 3 byte (9n kk vv)
  # delta time
  self.track.data.write(timeNum.toDeltaTime)
  # MIDI event
  # 9n
  self.track.data.write(midiStatusByte(stNoteOn, channel))
  # kk
  self.track.data.write(note)
  # vv
  self.track.data.write(velocity)

proc writeMidiPolyphonicKeyPressure*(self: SmfWrite, timeNum: uint32, channel, note, velocity: byte) =
  ## 3 byte (An kk vv)
  # delta time
  self.track.data.write(timeNum.toDeltaTime)
  # MIDI event
  # An
  self.track.data.write(midiStatusByte(stPolyphonicKeyPressure, channel))
  # kk
  self.track.data.write(note)
  # vv
  self.track.data.write(velocity)

proc writeMidiControlChange*(self: SmfWrite, timeNum: uint32, channel, controller, value: byte) =
  ## 3 byte (Bn cc vv) 特殊なので注意
  # delta time
  self.track.data.write(timeNum.toDeltaTime)
  # MIDI event
  # Bn
  self.track.data.write(midiStatusByte(stControlChange, channel))
  # cc
  self.track.data.write(controller)
  # vv
  self.track.data.write(value)

proc writeMidiProgramChange*(self: SmfWrite, timeNum: uint32, channel, program: byte) =
  ## 2 byte (Cn pp)
  # delta time
  self.track.data.write(timeNum.toDeltaTime)
  # MIDI event
  # Cn
  self.track.data.write(midiStatusByte(stProgramChange, channel))
  # pp
  self.track.data.write(program)

proc writeMidiChannelPressure*(self: SmfWrite, timeNum: uint32, channel, pressure: byte) =
  ## 2 byte (Dn pp)
  # delta time
  self.track.data.write(timeNum.toDeltaTime)
  # MIDI event
  # Dn
  self.track.data.write(midiStatusByte(stChannelPressure, channel))
  # pp
  self.track.data.write(pressure)

proc writeMidiPitchBend*(self: SmfWrite, timeNum: uint32, channel, pitch1, pitch2: byte) =
  ## 2 byte (Dn pp) リトルエンディアンなので注意
  # delta time
  self.track.data.write(timeNum.toDeltaTime)
  # MIDI event
  # En
  self.track.data.write(midiStatusByte(stPitchBend, channel))
  # ll
  self.track.data.write(pitch1)
  # mm
  self.track.data.write(pitch2)

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
