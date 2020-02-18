import streams

type
  Status = enum
    stNoteOff = 0b1000_0000'u8
    stNoteOn = 0b1001_0000'u8
    stControlChange = 0b1011_0000'u8

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

  ChannelMessage* = ref object
    channel*: uint8
    case status*: Status
    of stNoteOff, stNoteOn:
      note*: uint8
      velocity*: uint8
    of stControlChange:
      control*: uint8
      data*: uint8

proc readDeltaTime(strm: Stream): seq[byte] =
  ## デルタタイムを取り出す。
  var b = strm.readUint8()
  result.add(b)
  while (b and 0b1000_0000) == 0b1000_0000:
    b = strm.readUint8()
    result.add b

proc readHeaderChunk(strm: Stream): HeaderChunk =
  result = HeaderChunk()
  result.chunkType = strm.readStr(4)
  result.dataLength = strm.readUint32()
  result.format = strm.readUint16()
  result.trackCount = strm.readUint16()
  result.timeUnit = strm.readUint16()

proc readMIDIEvent(strm: Stream): MIDIEvent =
  let delta = strm.readDeltaTime()
  let head = strm.readUint8()
  result.status = ChannelMessage(status: head and 0b1111_0000'u8)
  result.channel = head and 0b0000_1111'u8
  case result.status
  of stNoteOff, stNoteOn:
    result.note = strm.readUint8()
    result.velocity = strm.readUint8()
  of stControlChange:
    result.control = strm.readUint8()
    result.data = strm.readUint8()

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
