import streams

import status, metaevent
export status, metaevent

type
  DeltaTime* = uint32

  HeaderChunk* = ref object
    chunkType*: string
    dataLength*: uint32
    format*: uint16
    trackCount*: uint16
    timeUnit*: uint16
  TrackChunk* = ref object
    chunkType*: string
    dataLength*: uint32
    data*: Stream

  EventSet* = ref object
    ## An object that has delta time and event data.
    deltaTime*: DeltaTime
    event*: Event

  EventKind* = enum
    ekMIDI, ekSysEx, ekMeta
  Event* = ref object of RootObj
    size*: uint32
    kind*: EventKind
  MIDIEvent* = ref object of Event
    ## 3 byte
    channel*: uint8 ## 1/2 byte (0000 xxxx)
    case status*: Status ## 1/2 byte (xxxx 0000)
    of stNoteOff, stNoteOn:
      note*: uint8 ## 1 byte
      velocity*: uint8 ## 1 byte
    of stControlChange:
      control*: uint8 ## 1 byte
      data*: uint8 ## 1 byte
    else:
      discard
  SysExEvent* = ref object of Event
    eventType*: byte
    dataLength*: uint32
    data*: seq[byte]
  MetaEvent* = ref object of Event
    metaPrefix*: byte ## 0xff
    metaType*: byte
    dataLength*: uint32
    data*: seq[byte]


const
  headerChunkType* = "MThd"
  trackChunkType* = "MTrk"
