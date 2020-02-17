import streams

type
  SMF* = ref object
  HeaderChunk* = ref object
    chunkType*: string
    dataLength*: uint32
    format*: uint16
    trackCount*: uint16
    timeUnit*: uint16

  TrackChunk* = object
    chunkType*: string
    dataLength*: uint32
    data*: seq[Event]

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

proc readDeltaTime(strm: Stream): seq[byte] =
  var i: int
  var b = data[i]
  result.add b
  while (b and 0b1000_0000) == 0b1000_0000:
    inc i
    b = data[i]
    result.add b

proc readHeaderChunk(strm: Stream): HeaderChunk =
  result = HeaderChunk()
  result.chunkType = strm.readStr(4)
  result.dataLength = strm.readUint32()
  result.format = strm.readUint16()
  result.trackCount = strm.readUint16()
  result.timeUnit = strm.readUint16()

proc readMIDIEvent(strm: Stream): MIDIEvent =
  discard

proc readSysExEvent(strm: Stream): SysExEvent =
  discard

proc readMetaEvent(strm: Stream): MetaEvent =
  discard

proc readTrackChunk(strm: Stream): TrackChunk =
  result = TrackChunk()
  result.chunkType = strm.readStr(4)
  result.dataLength = strm.readUint32()

proc readSMF(filename: string): SMF =
  var strm = newFileStream(filename, fmRead)
  var head = strm.readHeaderChunk()
  var track = strm.readTrackChunk()
