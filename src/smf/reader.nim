import streams

type
  Status = uint8
  DeltaTime = uint32

const
  stNoteOff: Status = 0b1000_0000'u8
  stNoteOn: Status = 0b1001_0000'u8
  stControlChange: Status = 0b1011_0000'u8
  stF0: Status = 0b1111_0000'u8
  stF7: Status = 0b1111_0111'u8

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
    deltaTime*: DeltaTime
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
    deltaTime*: DeltaTime
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
    else:
      discard

proc readDeltaTime(strm: Stream): DeltaTime =
  ## デルタタイムを取り出す。
  var b = strm.readUint8()
  result = DeltaTime(b)
  while (b and 0b1000_0000) == 0b1000_0000:
    result = result shl 8
    b = strm.readUint8()
    result += DeltaTime(b)

proc readHeaderChunk(strm: Stream): HeaderChunk =
  result = HeaderChunk()
  result.chunkType = strm.readStr(4)
  result.dataLength = strm.readUint32()
  result.format = strm.readUint16()
  result.trackCount = strm.readUint16()
  result.timeUnit = strm.readUint16()

proc readMIDIEvent(strm: Stream): MIDIEvent =
  result.deltaTime = strm.readDeltaTime()
  let head = strm.readUint8()
  result.status = head and 0b1111_0000'u8
  result.channel = head and 0b0000_1111'u8
  case result.status
  of stNoteOff, stNoteOn:
    result.note = strm.readUint8()
    result.velocity = strm.readUint8()
  of stControlChange:
    result.control = strm.readUint8()
    result.data = strm.readUint8()
  else:
    discard

proc readSysExEvent(strm: Stream): SysExEvent =
  result = SysExEvent()
  result.eventType = strm.readUint8()
  doAssert result.eventType in [0xf0'u8, 0xf7], "SysExイベントの先頭の文字が不正"
  result.deltaTime = strm.readDeltaTime()
  for i in 0'u32 ..< result.deltaTime:
    result.data.add(strm.readUint8())
  doAssert result.data[^1] == 0xf7'u8, "SysExイベント終端の文字が不正"

proc readMetaEvent(strm: Stream): MetaEvent =
  ## TODO
  discard

proc readTrackChunk(strm: Stream): TrackChunk =
  result = TrackChunk()
  result.chunkType = strm.readStr(4)
  result.dataLength = strm.readUint32()

proc readSMF(filename: string): SMF =
  var strm = newFileStream(filename, fmRead)
  var head = strm.readHeaderChunk()
  var track = strm.readTrackChunk()
