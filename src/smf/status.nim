type
  Status* = uint8

const
  stNoteOff*:               Status = 0x80'u8
  stNoteOn*:                Status = 0x90'u8
  stPolyphonicKeyPressure*: Status = 0xA0'u8
  stControlChange*:         Status = 0xB0'u8
  stProgramChange*:         Status = 0xC0'u8
  stChannelPressure*:       Status = 0xD0'u8
  stPitchBend*:             Status = 0xE0'u8
  stF0*:                    Status = 0b1111_0000'u8
  stF7*:                    Status = 0b1111_0111'u8
  stMetaPrefix*:            Status = 0b1111_1111'u8
