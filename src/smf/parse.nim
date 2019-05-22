import types, utils, consts
from sequtils import mapIt, foldl

proc parseMIDIEvent*(data: openArray[byte]): MIDIEvent =
  let
    deltaTime = data.parseDeltaTime
    b = data[deltaTime.len..^1]
    statusChannel = b[0]
    status  = statusChannel and 0b1111_0000
    channel = statusChannel and 0b0000_1111
  assert(status in statuses, "MIDIイベントの先頭の文字が不正")

  new result
  result.deltaTime = deltaTime.deltaTimeToOctal
  result.status    = status
  result.channel   = channel
  result.note      = b[1]
  result.velocity  = b[2]

proc parseSysExEvent*(data: openArray[byte]): SysExEvent =
  ## TODO F7型には対応していない。
  let deltaTime = data.parseDeltaTime
  var b = data[deltaTime.len..^1]

  let evType = b[0]
  assert(evType in [0xf0'u8, 0xf7], "SysExイベントの先頭の文字が不正")
  new result
  result.deltaTime = deltaTime.deltaTimeToOctal
  result.eventType = evType

  b = b[1..^1]
  let dl = b.parseDeltaTime
  result.dataLength = dl.deltaTimeToOctal

  b = b[dl.len..^1]
  for v in b[0..<result.dataLength]:
    result.data.add v

proc parseMetaEvent*(data: openArray[byte]): MetaEvent =
  let deltaTime = data.parseDeltaTime
  var b = data[deltaTime.len..^1]
  let mp = b[0] # meta prefix (0xff)
  assert(mp == metaPrefix, "MetaPrefixが不正: " & $mp)

  let mt = b[1] # meta type
  assert(mt in metas, "MIDIイベントの先頭の文字が不正")

  new result
  result.deltaTime = deltaTime.deltaTimeToOctal
  result.metaPrefix = mp
  result.metaType = mt

  b = b[2..^1]
  let dl = b.parseDeltaTime
  result.dataLength = dl.deltaTimeToOctal

  b = b[dl.len..^1]
  for v in b[0..<result.dataLength]:
    result.data.add v

proc parseHeaderChunk*(data: openArray[byte]): HeaderChunk =
  ## ヘッドチャンクを一つ取得する。
  result.chunkType  = data[0..<4]            # 4byte
  result.dataLength = data[4..<8].toUint32   # 4byte
  result.format     = data[8..<10]           # 2byte
  result.trackCount = data[10..<12].toUint16 # 2byte
  result.timeUnit   = data[12..<14].toUint16 # 2byte

proc parseTrackChunk*(data: openArray[byte]): TrackChunk =
  ## 先頭のトラックチャンクを一つ取得する。
  result.chunkType  = data[0..<4]          # 4byte
  result.dataLength = data[4..<8].toUint32 # 4byte
  var startPos = 8
  var part3 = startPos
  while part3+3 <= len(data):
    let part = data[part3..<part3+3]
    if part == endOfTrack:
      # let data = data[startPos..<part3+3]
      ## TODO
      return
    inc part3
