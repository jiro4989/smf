import streams

import midistatus

type
  SMFWrite* = ref object
    fileName: string
    data: Stream

proc midiStatusByte(status: Status, channel: byte): byte =
  result = status and (channel and 0x0F'u8)

proc writeNoteOff*(self: SMFWrite, channel, note: byte) =
  ## 3 byte (8n kk vv)
  # 8n
  self.data.write(midiStatusByte(stNoteOff, channel))
  # kk
  self.data.write(note)
  # vv
  self.data.write(0'u8)

proc writeNoteOn*(self: SMFWrite, channel, note, velocity: byte) =
  ## 3 byte (9n kk vv)
  # 9n
  self.data.write(midiStatusByte(stNoteOn, channel))
  # kk
  self.data.write(note)
  # vv
  self.data.write(velocity)

proc writePolyphonicKeyPressure*(self: SMFWrite, channel, note, velocity: byte) =
  ## 3 byte (An kk vv)
  # An
  self.data.write(midiStatusByte(stPolyphonicKeyPressure, channel))
  # kk
  self.data.write(note)
  # vv
  self.data.write(velocity)

proc writeControlChange*(self: SMFWrite, channel, controller, value: byte) =
  ## 3 byte (Bn cc vv) 特殊なので注意
  # Bn
  self.data.write(midiStatusByte(stControlChange, channel))
  # cc
  self.data.write(controller)
  # vv
  self.data.write(value)

proc writeProgramChange*(self: SMFWrite, channel, program: byte) =
  ## 2 byte (Cn pp)
  # Cn
  self.data.write(midiStatusByte(stProgramChange, channel))
  # pp
  self.data.write(program)

proc writeChannelPressure*(self: SMFWrite, channel, pressure: byte) =
  ## 2 byte (Dn pp)
  # Dn
  self.data.write(midiStatusByte(stChannelPressure, channel))
  # pp
  self.data.write(pressure)

proc writePitchBend*(self: SMFWrite, channel, pitch1, pitch2: byte) =
  ## 2 byte (Dn pp) リトルエンディアンなので注意
  # En
  self.data.write(midiStatusByte(stPitchBend, channel))
  # ll
  self.data.write(pitch1)
  # mm
  self.data.write(pitch2)

proc openSMFWrite*(filename: string): SMFWrite =
  discard
