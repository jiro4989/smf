type
  Status* = uint8
  DeltaTime* = uint32
  MetaEvent* = enum
    meSequenceNumber    = 0x00'u8
    meText              = 0x01'u8
    meCopyrightNotice   = 0x02'u8
    meSequenceTrackName = 0x03'u8
    meInstrumentName    = 0x04'u8
    meLyric             = 0x05'u8
    meMarker            = 0x06'u8
    meCuePoint          = 0x07'u8
    meMIDIChannelPrefix = 0x20'u8
    meMIDIPort          = 0x21'u8
    meEndOfTrack        = 0x2F'u8
    meSetTempo          = 0x51'u8
    meSMTPEOffset       = 0x54'u8
    meTimeSignature     = 0x58'u8
    meKeySignature      = 0x59'u8
    meSequencerSpecific = 0x7F'u8

const
  stNoteOff*: Status               = 0x80'u8
  stNoteOn*: Status                = 0x90'u8
  stPolyphonicKeyPressure*: Status = 0xA0'u8
  stControlChange*: Status         = 0xB0'u8
  stProgramChange*: Status         = 0xC0'u8
  stChannelPressure*: Status       = 0xD0'u8
  stPitchBend*: Status             = 0xE0'u8
  stF0*: Status                    = 0b1111_0000'u8
  stF7*: Status                    = 0b1111_0111'u8

  stMetaPrefix*: Status               = 0b1111_1111'u8
