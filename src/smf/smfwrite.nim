import streams

import midistatus, utils

type
  SMFWrite* = ref object
    fileName: string
    data: Stream

proc midiStatusByte(status: Status, channel: byte): byte =
  result = status and (channel and 0x0F'u8)

proc writeMidiNoteOff*(self: SMFWrite, timeNum: uint32, channel, note: byte) =
  ## 3 byte (8n kk vv)
  # delta time
  self.data.write(timeNum.toDeltaTime)
  # MIDI event
  # 8n
  self.data.write(midiStatusByte(stNoteOff, channel))
  # kk
  self.data.write(note)
  # vv
  self.data.write(0'u8)

proc writeMidiNoteOn*(self: SMFWrite, timeNum: uint32, channel, note, velocity: byte) =
  ## 3 byte (9n kk vv)
  # delta time
  self.data.write(timeNum.toDeltaTime)
  # MIDI event
  # 9n
  self.data.write(midiStatusByte(stNoteOn, channel))
  # kk
  self.data.write(note)
  # vv
  self.data.write(velocity)

proc writeMidiPolyphonicKeyPressure*(self: SMFWrite, timeNum: uint32, channel, note, velocity: byte) =
  ## 3 byte (An kk vv)
  # delta time
  self.data.write(timeNum.toDeltaTime)
  # MIDI event
  # An
  self.data.write(midiStatusByte(stPolyphonicKeyPressure, channel))
  # kk
  self.data.write(note)
  # vv
  self.data.write(velocity)

proc writeMidiControlChange*(self: SMFWrite, timeNum: uint32, channel, controller, value: byte) =
  ## 3 byte (Bn cc vv) 特殊なので注意
  # delta time
  self.data.write(timeNum.toDeltaTime)
  # MIDI event
  # Bn
  self.data.write(midiStatusByte(stControlChange, channel))
  # cc
  self.data.write(controller)
  # vv
  self.data.write(value)

proc writeMidiProgramChange*(self: SMFWrite, timeNum: uint32, channel, program: byte) =
  ## 2 byte (Cn pp)
  # delta time
  self.data.write(timeNum.toDeltaTime)
  # MIDI event
  # Cn
  self.data.write(midiStatusByte(stProgramChange, channel))
  # pp
  self.data.write(program)

proc writeMidiChannelPressure*(self: SMFWrite, timeNum: uint32, channel, pressure: byte) =
  ## 2 byte (Dn pp)
  # delta time
  self.data.write(timeNum.toDeltaTime)
  # MIDI event
  # Dn
  self.data.write(midiStatusByte(stChannelPressure, channel))
  # pp
  self.data.write(pressure)

proc writeMidiPitchBend*(self: SMFWrite, timeNum: uint32, channel, pitch1, pitch2: byte) =
  ## 2 byte (Dn pp) リトルエンディアンなので注意
  # delta time
  self.data.write(timeNum.toDeltaTime)
  # MIDI event
  # En
  self.data.write(midiStatusByte(stPitchBend, channel))
  # ll
  self.data.write(pitch1)
  # mm
  self.data.write(pitch2)

proc writeMetaEndOfTrack*(self: SMFWrite) =
  ## 4 byte
  self.data.write(0'u8)             # delta time
  self.data.write(stMetaPrefix)     # meta prefix
  self.data.write(meEndOfTrack.ord) # end of track
  self.data.write(0'u8)             # data length

proc openSMFWrite*(filename: string): SMFWrite =
  discard
