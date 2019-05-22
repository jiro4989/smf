import types, utils, consts
from sequtils import mapIt, foldl

proc parseMIDIEvent(data: openArray[byte]): MIDIEvent =
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

proc parseSysExEvent(data: openArray[byte]): SysExEvent =
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

proc parseMetaEvent(data: openArray[byte]): MetaEvent =
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

proc parseHeaderChunk(data: openArray[byte]): HeaderChunk =
  ## ヘッドチャンクを一つ取得する。
  result.chunkType  = data[0..<4]            # 4byte
  result.dataLength = data[4..<8].toUint32   # 4byte
  result.format     = data[8..<10]           # 2byte
  result.trackCount = data[10..<12].toUint16 # 2byte
  result.timeUnit   = data[12..<14].toUint16 # 2byte

proc parseTrackChunk(data: openArray[byte]): TrackChunk =
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

proc readSMF*(f: File): SMF =
  ## ファイルからSMFデータを読み込む。
  runnableExamples:
    try:
      var f = open("test.mid")
      var smfObj = f.readSMF()
      ## do something...
      f.close()
    except:
      stderr.writeLine getCurrentExceptionMsg()

  if f.isNil:
    raise newException(OSError, "開けませんでした")
  var data = f.readAll.mapIt(it.byte)
  result.headerChunk = data.parseHeaderChunk

  # ヘッダチャンクは除外
  data = data[headerChunkLength..^1]
  for i in 1'u16..result.headerChunk.trackCount:
    # トラックチャンクの取得
    let track = data.parseTrackChunk
    result.trackChunks.add track
    # 1つ目のトラックチャンクを除外
    data = data[int(8'u32+track.dataLength)..^1]

proc readSMFFile*(path: string): SMF =
  ## SMFファイルを読み込む。
  runnableExamples:
    try:
      var smfObj = readSMFFile("test.mid")
      ## do something...
    except:
      stderr.writeLine getCurrentExceptionMsg()

  var f = open(path)
  if f.isNil:
    raise newException(OSError, path & "を開けませんでした")
  defer: f.close
  result = readSMF(f)

proc writeSMF*(f: File, data: SMF) =
  ## ファイルにSMFのバイナリデータを書き込む。
  runnableExamples:
    from os import removeFile
    var smfObj = newSMF(format0, 480)
    var track = newTrackChunk()
    for i in 1'u8..20:
      let n: byte = 0x30'u8 + i
      track.add newMIDIEvent(0, statusNoteOn, 0, n, 0x64)
      track.add newMIDIEvent(120, statusNoteOff, 0, n, 0)
    smfObj.add track
    var f = open("test.mid", fmWrite)
    f.writeSMF(smfObj)
    f.close()
    removeFile("test.mid")

  var d = data.toBytes
  discard f.writeBytes(d, 0, d.len)
  
proc writeSMFFile*(path: string, data: SMF) =
  ## SMFのバイナリデータを書き込んだファイルを新規生成する。
  runnableExamples:
    from os import removeFile
    var smfObj = newSMF(format0, 480)
    var track = newTrackChunk()
    for i in 1'u8..20:
      let n: byte = 0x30'u8 + i
      track.add newMIDIEvent(0, statusNoteOn, 0, n, 0x64)
      track.add newMIDIEvent(120, statusNoteOff, 0, n, 0)
    smfObj.add track
    writeSMFFile("test.mid", smfObj)
    removeFile("test.mid")

  var f = open(path, fmWrite)
  defer: f.close
  f.writeSMF(data)
  