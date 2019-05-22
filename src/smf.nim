## SMFのデータ構造
## ----------------
##
## * 一つのヘッダブロックを持つ
## * 複数のトラックブロックを持つ
##
## SMFにはFORMAT 0/1/2 と３つのフォーマットがありますが、
## FORMAT 0 は・・・そう、トラックチャンクは１つしかございません。(Format 0 はすべてのチャンネルのデータを１トラックに全て収めたものですから）
## FORMAT 1/2 は使用しているトラックの数だけトラックチャンクがございます。
##
## ヘッダ
## ^^^^^^
##
## * チャンクタイプ 4byte
## * データ長       4byte
## * フォーマット   2byte
## * トラック数     2byte
## * 時間単位       2byte
##
## チャンクタイプ
##
## * "MThd"で常に固定
## * "MThd" は \x4d \x54 \x68 \x64 になる
##
## データ長
##
## * これから何byteデータが続くかを表す
## * ヘッダチャンクは残り6byte
## * \x00 \x00 \x00 \x06 で常に固定
##
## フォーマット
##
## * SMF には format 0~3 まである
## * ここにはその
##
## 時間単位
##
## * 時間の指定のしかたにはに種類ある
##   * 何小節何泊、という指定の仕方と何分何秒何フレームという指定の仕方がある
##   * 最上位ビット(7ビット)が0のときは前者、1のときは後者
##
## イベント
##
## * デルタタイムとイベントはセットになっている
## * デルタタイム、イベント、デルタタイム、イベントを交互に繰り返す
## * イベントは3種類に分けられる
##   * MIDIイベント
##   * SysExイベント
##   * メタイベント
##
## * チャンネルメッセージ
##   * ノートON  8n aa bb (n: 対象チャンネルナンバー, aa: ノートナンバー, bb: ベロシティ)
##   * ノートOFF 9n aa bb (n: 対象チャンネルナンバー, aa: ノートナンバー, bb: ベロシティ)
##   * コントロールチェンジ Bn aa bb (n: 対象チャンネルナンバー, aa: コントロールナンバー, bb: データ)
##
## データサンプル
##
## イメージとしては以下のような感じ
##
## MThd ...................... (常に1つ)
## MTrk ...................... (1つかもしれないし、それ以上かもしれない)
## MTrk ......................
## MTrk ......................
##
## Basic usage
## ===========
##
## Large example
## -------------
##
## .. code-block:: Nim
##
##    import smf
##
##    var smfObj = newSMF(format0, 480)
##
##    var track = newTrackChunk()
##    for i in 1'u8..20:
##      let n: byte = 0x30'u8 + i
##      track.add newMIDIEvent(0, statusNoteOn, 0, n, 0x64)
##      track.add newMIDIEvent(120, statusNoteOff, 0, n, 0)
##    smfObj.add track
##
##    writeSMFFile("test.mid", smfObj)
##
## See also:
## * http://maruyama.breadfish.jp/tech/smf/
## * https://qiita.com/PianoScoreJP/items/2f03ae61d91db0334d45
## * https://www.g200kg.com/jp/docs/tech/smf.html

from algorithm import reversed
from sequtils import mapIt, foldl
import streams

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
    deltaTime: uint32
    metaType: byte
    data: seq[byte]

  HeaderChunk = object
    chunkType, format: seq[byte]
    dataLength: uint32
    trackCount: uint16
    timeUnit: uint16
  TrackChunk = object
    chunkType, endOfTrack: seq[byte]
    dataLength: uint32
    data: seq[Event]
  SMF* = object
    headerChunk: HeaderChunk
    trackChunks: seq[TrackChunk]

const
  headerChunkType* = @[0x4d'u8, 0x54, 0x68, 0x64] ## MThd
  headerDataLength* = 6
  format0* = @[0x00'u8, 0x00] ## 00
  format1* = @[0x00'u8, 0x01] ## 01
  format2* = @[0x00'u8, 0x02] ## 02
  headerChunkLength = 14      ## 14byte

  trackChunkType*: seq[byte] = @[0x4d'u8, 0x54, 0x72, 0x6b] ## MTrk
  metaPrefix = 0xFF'u8
  endOfTrack* = @[metaPrefix, 0x2F, 0x00]

  statusNoteOff*       = 0x80'u8 ## MIDI event status
  statusNoteOn*        = 0x90'u8 ## MIDI event status
  statusPKPresure*     = 0xA0'u8 ## MIDI event status
  statusControlChange* = 0xB0'u8 ## MIDI event status
  statusProgramChange* = 0xC0'u8 ## MIDI event status
  statusCKPresure*     = 0xD0'u8 ## MIDI event status
  statusPitchBend*     = 0xE0'u8 ## MIDI event status

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

# ------------------------------------------------------------------------------
#   utilities
# ------------------------------------------------------------------------------

proc padZero(data: openArray[byte], n: int): seq[byte] = 
  result.add data
  let diff = n - len(data)
  for i in 1..diff:
    result.insert(0, 0)

proc deltaTimeToOctal(deltaTime: openArray[byte]): uint32 =
  ## 1000_0001 0111_1111 ->           1111_1111
  ## 1000_0011 0111_1111 -> 0000_0001 1111_1111
  let rev = deltaTime.reversed
  for i, v in rev:
    result += ((v.uint32 and 0b0111_1111) shl (7 * i))

proc parseDeltaTime(data: openArray[byte]): seq[byte] =
  ## 先頭のデルタタイムを取得する。
  if data.len < 1: return
  var i: int
  var b = data[i]
  result.add b
  while (b and 0b1000_0000) == 0b1000_0000:
    inc i
    b = data[i]
    result.add b

proc toDeltaTime(n: uint32): seq[byte] = 
  ## 10進数をデルタタイムに変換する。
  ## デルタタイムは1byteのデータのうち、8bit目をデータが継続しているか、のフラグに使用する。
  ## よって1byteで表現できるデータは127までになる。
  ## 128のときは以下のようになる。
  ##
  ## 127             0b0111_1111
  ## 128 0b1000_0001 0b0000_0000
  if n <= 0: return @[0'u8]
  var m = n
  var i: int
  while 0'u32 < m:
    var b = byte(m and 0b0111_1111)
    if 0 < i:
      b += 0b1000_0000
    result.add b
    m = m shr 7
    inc i
  result = result.reversed

proc toBytes(n: uint32): seq[byte] =
  if n <= 0: return @[0'u8]
  var m = n
  while 0'u32 < m:
    let x = m and 255
    result.add x.byte
    m = m shr 8
  result = result.reversed

method toBytes(event: Event): seq[byte] {.base.} = discard

method toBytes(event: MIDIEvent): seq[byte] =
  result.add event.deltaTime.toDeltaTime
  result.add event.status + event.channel
  result.add event.note
  result.add event.velocity

method toBytes(event: MetaEvent): seq[byte] =
  result.add event.deltaTime.toDeltaTime
  result.add event.metaType
  result.add event.data.len.uint32.toDeltaTime
  result.add event.data

proc toBytes(h: HeaderChunk): seq[byte] =
  result.add h.chunkType
  result.add h.dataLength.toBytes.padZero(4)
  result.add h.format
  result.add h.trackCount.toBytes.padZero(2)
  result.add h.timeUnit.toBytes

proc toBytes(t: TrackChunk): seq[byte] =
  result.add t.chunkType
  result.add t.dataLength.toBytes.padZero(4)
  for event in t.data:
    result.add event.toBytes
  result.add t.endOfTrack

proc toBytes(s: SMF): seq[byte] =
  result.add s.headerChunk.toBytes
  for t in s.trackChunks:
    result.add t.toBytes

proc toUint16(n: seq[byte]): uint16 = (n[0].uint16 shl 8) + n[1].uint16
proc toUint32(n: seq[byte]): uint32 =
  (n[0].uint32 shl 24) + (n[1].uint32 shl 16) + (n[2].uint32 shl 8) + n[3].uint32

# ------------------------------------------------------------------------------
#   public procedures
# ------------------------------------------------------------------------------

proc newSMF*(format: seq[byte], timeUnit: uint16): SMF =
  ## SMFオブジェクトを生成する。
  ##
  ## See also:
  ## * `newTrackChunk proc <#newTrackChunk>`_ creates a TrachChunk
  ## * `add proc <#add,SMF,TrackChunk>`_ adds TrackChunk to SMF
  result.headerChunk = HeaderChunk(chunkType: headerChunkType,
                                   dataLength: headerDataLength,
                                   format: format,
                                   timeUnit: timeUnit)

proc newTrackChunk*(): TrackChunk =
  ## トラックチャンクを生成する。
  result.chunkType = trackChunkType
  result.endOfTrack = endOfTrack

proc newMIDIEvent*(deltaTime: uint32, status, channel, note, velocity: byte): MIDIEvent =
  ## MIDIイベントを生成する。
  ##
  ## See also:
  ## * `newMetaEvent proc <#newMetaEvent>`_ creates a MIDIEvent
  ## * `newTrackChunk proc <#newTrackChunk>`_ creates a TrachChunk
  ## * `add proc <#add,TrackChunk,MIDIEvent>`_ adds MIDIEvent to TrackChunk
  runnableExamples:
    var track = newTrackChunk()
    track.add newMIDIEvent(0, statusNoteOn, 0, 0x31, 0x64)

  result = MIDIEvent(deltaTime: deltaTime, status: status,
                     channel: channel, note: note, velocity: velocity)

proc newMetaEvent*(deltaTime: uint32, metaType: byte, data: seq[byte]): MetaEvent =
  ## メタイベントを生成する。
  runnableExamples:
    ## Meta event "End of Track"
    var event = newMetaEvent(0, metaEndOfTrack, @[])

  result = MetaEvent(deltaTime: deltaTime, metaType: metaType, data: data)

proc newMetaEvent*(deltaTime: uint32, metaType: byte, data: string): MetaEvent =
  ## テキスト情報を保持するタイプのメタイベントを生成する。
  runnableExamples:
    var event = newMetaEvent(0, metaInstrumentName, "Guitar")

  case metaType
  of metaText, metaCopyrightNotice, metaSequenceTrackName, metaInstrumentName, metaLyric:
    result = newMetaEvent(deltaTime, metaType, data.mapIt(it.byte))
  else:
    raise newException(ValueError ,"illegal metaType: " & $metaType)

proc add*(self: var SMF, track: TrackChunk) =
  ## SMFにトラックチャンクを追加する。
  if self.headerChunk.format == format0 and 1 <= self.trackChunks.len:
    assert(false, "FORMAT0ではトラックは1つしかもてません")
  self.trackChunks.add track
  self.headerChunk.trackCount.inc

proc add*(self: var TrackChunk, event: Event) =
  ## トラックチャンクにMIDIイベントを追加する。
  self.data.add event
  self.dataLength += uint32(event.toBytes.len)

proc delete*(self: var SMF, index: int) =
  ## TODO error
  self.headerChunk.trackCount.dec
  self.trackChunks.delete(index)

proc delete*(self: var TrackChunk, index: int) =
  ## TODO error
  let delData = self.data[index]
  let b = delData.toBytes
  self.dataLength -= b.len.uint32
  self.data.delete(index)

proc isSMFFile*(path: string): bool =
  ## pathのファイルがSMFファイルであるかを判定する。
  ## 先頭4byteを読み取って判定する。
  var strm = newFileStream(path)
  if strm.isNil: return
  defer: strm.close

  var buf: array[4, byte]
  discard strm.readData(addr(buf), len(buf))
  result = buf == headerChunkType

# ------------------------------------------------------------------------------
#   read/write file
# ------------------------------------------------------------------------------

proc parseMIDIEvent(data: openArray[byte]): MIDIEvent =
  new result
  discard

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
  new result
  discard

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
  