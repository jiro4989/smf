import streams

type
  SMFWrite* = ref object
    fileName: string
    data: Stream

proc writeNoteOff*(self: SMFWrite, channelNumber, note: byte) =
  ## 3 byte
  # 8n
  self.data.write(0b1000_0000'u8 and (channelNumber and 0b0000_1111'u8))
  # kk
  self.data.write(note)
  # vv
  self.data.write(0'u8)

proc writeNoteOn*(self: SMFWrite, channelNumber, note, velocity: byte) =
  ## 3 byte
  # 9n
  self.data.write(0b1001_0000'u8 and (channelNumber and 0b0000_1111'u8))
  # kk
  self.data.write(note)
  # vv
  self.data.write(velocity)

proc openSMFWrite*(filename: string): SMFWrite =
  discard
