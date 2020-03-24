import streams

type
  SMFWrite* = ref object
    fileName: string
    data: Stream

proc writeNoteOff*(self: SMFWrite, channel, note: byte) =
  ## 3 byte (8n kk vv)
  # 8n
  self.data.write(0x80'u8 and (channel and 0x0F'u8))
  # kk
  self.data.write(note)
  # vv
  self.data.write(0'u8)

proc writeNoteOn*(self: SMFWrite, channel, note, velocity: byte) =
  ## 3 byte (9n kk vv)
  # 9n
  self.data.write(0x90'u8 and (channel and 0x0F'u8))
  # kk
  self.data.write(note)
  # vv
  self.data.write(velocity)

proc writePolyphonicKeyPressure*(self: SMFWrite, channel, note, velocity: byte) =
  ## 3 byte (An kk vv)
  # An
  self.data.write(0xA0'u8 and (channel and 0x0F'u8))
  # kk
  self.data.write(note)
  # vv
  self.data.write(velocity)

proc openSMFWrite*(filename: string): SMFWrite =
  discard
