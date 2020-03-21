import streams, sugar, endians

import consts

type
  Status = uint8
  DeltaTime = uint32

const
  stNoteOff: Status = 0b1000_0000'u8
  stNoteOn: Status = 0b1001_0000'u8
  stControlChange: Status = 0b1011_0000'u8
  stF0: Status = 0b1111_0000'u8
  stF7: Status = 0b1111_0111'u8
  stMetaPrefix: Status = 0b1111_1111'u8

type
  SMF* = ref object
    header*: HeaderChunk
    track*: TrackChunk

  HeaderChunk* = ref object
    chunkType*: string
    dataLength*: uint32
    format*: uint16
    trackCount*: uint16
    timeUnit*: uint16

  TrackChunk* = ref object
    chunkType*: string
    dataLength*: uint32
    data*: seq[EventSet]

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

template decho(x: untyped) =
  when not defined release:
    dump x

proc readDeltaTime(strm: Stream): (DeltaTime, uint32) =
  ## デルタタイムを取り出す。
  var
    b = strm.readUint8()
    deltaTime = DeltaTime(b)
    size = 1'u32
  while (b and 0b1000_0000) == 0b1000_0000:
    inc(size)
    deltaTime = deltaTime shl 8
    b = strm.readUint8()
    deltaTime += DeltaTime(b)
  result = (deltaTime, size)

proc readHeaderChunk(strm: Stream): HeaderChunk =
  result = HeaderChunk()
  result.chunkType = strm.readStr(4)

  # default: readUint32 returns a value of little endians.
  var littleDataLength = strm.readUint32()
  bigEndian32(addr(result.dataLength), addr(littleDataLength))

  result.format = strm.readUint16()
  result.trackCount = strm.readUint16()
  result.timeUnit = strm.readUint16()
  decho result[]

proc readMIDIEvent(strm: Stream): MIDIEvent =
  let
    head = strm.readUint8()
    status = head and 0b1111_0000'u8
    channel = head and 0b0000_1111'u8
  case status
  of stNoteOff, stNoteOn:
    let note = strm.readUint8()
    let velocity = strm.readUint8()
    result = MIDIEvent(
      size: 3'u8,
      kind: ekMIDI,
      status: status, channel: channel,
      note: note, velocity: velocity)
  of stControlChange:
    let control = strm.readUint8()
    let data = strm.readUint8()
    result = MIDIEvent(
      size: 3'u8,
      kind: ekMIDI,
      status: status, channel: channel,
      control: control, data: data)
  else:
    doAssert false, "不正なデータ"

proc readSysExEvent(strm: Stream, deltaTime: DeltaTime): SysExEvent =
  result = SysExEvent(kind: ekSysEx)
  result.eventType = strm.readUint8()
  inc(result.size)
  doAssert result.eventType in [0xf0'u8, 0xf7], "SysExイベントの先頭の文字が不正"
  for i in 0'u32 ..< deltaTime:
    result.data.add(strm.readUint8())
    inc(result.size)
  doAssert result.data[^1] == 0xf7'u8, "SysExイベント終端の文字が不正"

proc readMetaEvent(strm: Stream, deltaTime: DeltaTime): MetaEvent =
  result = MetaEvent(kind: ekMeta)
  result.metaPrefix = strm.readUint8()
  inc(result.size)
  result.metaType = strm.readUint8()
  inc(result.size)
  for i in 0'u32 ..< deltaTime:
    result.data.add(strm.readUint8())
    inc(result.size)

proc readTrackChunk(strm: Stream): TrackChunk =
  ## Reads track chunk.
  result = TrackChunk()
  result.chunkType = strm.readStr(4)

  # default: readUint32 returns a value of little endians.
  var littleDataLength = strm.readUint32()
  bigEndian32(addr(result.dataLength), addr(littleDataLength))

  var size: uint32
  while size < result.dataLength:
    var evtSet = EventSet()
    let (deltaTime, deltaTimeSize) = strm.readDeltaTime()
    evtSet.deltaTime = deltaTime
    size += deltaTimeSize
    decho result[]
    decho evtSet[]
    # FIXME: なんでコレがクラッシュするんだろう
    # decho $evtSet.event
    decho size
    decho result.dataLength
    decho "---------------"
    var pref = strm.peekUint8()
    case pref
    of stF0, stF7:
      evtSet.event = strm.readSysExEvent(evtSet.deltaTime)
      size += evtSet.event.size
      result.data.add(evtSet)
    of stMetaPrefix:
      evtSet.event = strm.readMetaEvent(evtSet.deltaTime)
      size += evtSet.event.size
      result.data.add(evtSet)
    else:
      pref = pref and 0b1111_0000
      case pref
      of stNoteOff, stNoteOn, stControlChange:
        evtSet.event = strm.readMIDIEvent()
        size += evtSet.event.size
        result.data.add(evtSet)
      else:
        doAssert false, "不正なデータ"
  let evtSet = EventSet(event: strm.readMetaEvent(0))
  result.data.add(evtSet)
  let eot = result.data[^1].event
  let meta = cast[MetaEvent](eot)
  doAssert meta.kind == ekMeta, "終端イベントタイプ不正"
  doAssert meta.metaType == metaEndOfTrack, "終端データ不正"

proc readSMF*(filename: string): SMF =
  result = SMF()
  var strm = newFileStream(filename, fmRead)
  result.header = strm.readHeaderChunk()
  result.track = strm.readTrackChunk()

#proc `$`*(self: SMF): string = 

proc `$`*(self: MIDIEvent): string = $self[]
proc `$`*(self: SysExEvent): string = $self[]
proc `$`*(self: MetaEvent): string = $self[]
proc `$`*(self: Event): string =
  case self.kind
  of ekMIDI: $cast[MIDIEvent](self)
  of ekSysEx: $cast[SysExEvent](self)
  of ekMeta: $cast[MetaEvent](self)