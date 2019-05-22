type
  Event* = ref object of RootObj
  MIDIEvent* = ref object of Event
    deltaTime*: uint32
    status*: byte
    channel*, note*, velocity*: byte
  SysExEvent* = ref object of Event
    deltaTime*: uint32
    eventType*: byte
    dataLength*: uint32
    data*: seq[byte]
  MetaEvent* = ref object of Event
    deltaTime*: uint32
    metaPrefix*: byte ## 0xff
    metaType*: byte
    dataLength*: uint32
    data*: seq[byte]

  HeaderChunk* = object
    chunkType*, format*: seq[byte]
    dataLength*: uint32
    trackCount*: uint16
    timeUnit*: uint16
  TrackChunk* = object
    chunkType*, endOfTrack*: seq[byte]
    dataLength*: uint32
    data*: seq[Event]
  SMF* = object
    headerChunk*: HeaderChunk
    trackChunks*: seq[TrackChunk]
