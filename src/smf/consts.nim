const
  headerChunkType* = @[0x4d'u8, 0x54, 0x68, 0x64] ## MThd
  headerDataLength* = 6
  format0* = @[0x00'u8, 0x00] ## 00
  format1* = @[0x00'u8, 0x01] ## 01
  format2* = @[0x00'u8, 0x02] ## 02
  headerChunkLength* = 14      ## 14byte

  trackChunkType*: seq[byte] = @[0x4d'u8, 0x54, 0x72, 0x6b] ## MTrk
  metaPrefix* = 0xFF'u8
  endOfTrack* = @[metaPrefix, 0x2F, 0x00]

  statusNoteOff*       = 0x80'u8 ## MIDI event status
  statusNoteOn*        = 0x90'u8 ## MIDI event status
  statusPKPresure*     = 0xA0'u8 ## MIDI event status
  statusControlChange* = 0xB0'u8 ## MIDI event status
  statusProgramChange* = 0xC0'u8 ## MIDI event status
  statusCKPresure*     = 0xD0'u8 ## MIDI event status
  statusPitchBend*     = 0xE0'u8 ## MIDI event status
  statuses*            = @[statusNoteOff,
                           statusNoteOn,
                           statusPKPresure,
                           statusControlChange,
                           statusProgramChange,
                           statusCKPresure,
                           statusPitchBend]

  metaSequenceNumber*    = 0x00'u8 ## Meta event type
  metaText*              = 0x01'u8 ## Meta event type
  metaCopyrightNotice*   = 0x02'u8 ## Meta event type
  metaSequenceTrackName* = 0x03'u8 ## Meta event type
  metaInstrumentName*    = 0x04'u8 ## Meta event type
  metaLyric*             = 0x05'u8 ## Meta event type
  metaMarker*            = 0x06'u8 ## Meta event type
  metaCuePoint*          = 0x07'u8 ## Meta event type
  metaMIDIChannelPrefix* = 0x20'u8 ## Meta event type
  metaMIDIPort*          = 0x21'u8 ## Meta event type
  metaEndOfTrack*        = 0x2F'u8 ## Meta event type
  metaSetTempo*          = 0x51'u8 ## Meta event type
  metaSMTPEOffset*       = 0x54'u8 ## Meta event type
  metaTimeSignature*     = 0x58'u8 ## Meta event type
  metaKeySignature*      = 0x59'u8 ## Meta event type
  metaSequencerSpecific* = 0x7F'u8 ## Meta event type
  metas*                 = @[metaSequenceNumber,
                             metaText,
                             metaCopyrightNotice,
                             metaSequenceTrackName,
                             metaInstrumentName,
                             metaLyric,
                             metaMarker,
                             metaCuePoint,
                             metaMIDIChannelPrefix,
                             metaMIDIPort,
                             metaEndOfTrack,
                             metaSetTempo,
                             metaSMTPEOffset,
                             metaTimeSignature,
                             metaKeySignature,
                             metaSequencerSpecific]
