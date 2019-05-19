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
## See also:
## * http://maruyama.breadfish.jp/tech/smf/
## * https://qiita.com/PianoScoreJP/items/2f03ae61d91db0334d45

from algorithm import reverse
from sequtils import mapIt, foldl
import streams

type
  Track = object

  HeaderChunk = object
    chunkType, dataLength, format, trackCount: seq[byte]
    timeUnit: uint16
  TrackChunk = object
    chunkType, dataLength, data: seq[byte]
  SMF* = object
    headerChunk: HeaderChunk
    trackChunks: seq[TrackChunk]
  ChannelMessage* = array[3, byte]
  ChannelMessageType* = enum
    noteOn, noteOff, controlChange
  SysEx* = byte
  MIDIEvent* = object
    status*: byte
    deltaTime*: uint32
    channel*, note*, velocity*: byte

const
  headerChunkType* = @[0x4d'u8, 0x54, 0x68, 0x64] ## MThd
  headerDataLength* = @[0x00'u8, 0x00, 0x00, 0x06] ## 6
  headerFormat0* = @[0x00'u8, 0x00] ## 00
  headerFormat1* = @[0x00'u8, 0x01] ## 01
  headerFormat2* = @[0x00'u8, 0x02] ## 02
  # headerTrackCount* = @[0x00'u8, 0x01]
  #   ## format0の時は01になる
  headerTimeUnit = @[0x00'u8, 0x01]
    ## 時間単位
  headerChunkLength = 14 ## 14byte

  trackChunkType*: seq[byte] = @[0x4d'u8, 0x54, 0x72, 0x6b] ## MTrk
  trackDataLength: seq[byte] = @[] ## 4byte
  sysExF0: SysEx = 0xF0
  sysExF7: SysEx = 0xF7
  metaPrefix = 0xFF'u8
  endOfTrack* = @[metaPrefix, 0x2F, 0x00]

  statusNoteOn*        = 0x80'u8
  statusNoteOff*       = 0x90'u8
  statusPKPresure*     = 0xA0'u8
  statusControlChange* = 0xB0'u8
  statusProgramChange* = 0xC0'u8
  statusCKPresure*     = 0xD0'u8
  statusPitchBend*     = 0xE0'u8

proc toDeltaTime(n: uint32): seq[byte] = 
  ## 10進数をデルタタイムに変換する。
  ## デルタタイムは1byteのデータのうち、8bit目をデータが継続しているか、のフラグに使用する。
  ## よって1byteで表現できるデータは127までになる。
  ## 128のときは以下のようになる。
  ##
  ## 127             0b0111_1111
  ## 128 0b1000_0001 0b0000_0000
  if n <= 0:
    return @[0'u8]
  var m = n
  var i: int
  while 0'u32 < m:
    var b = byte(m and 0b0111_1111)
    if 0 < i:
      b += 0b1000_0000
    result.add b
    m = m shr 7
    inc i
  result.reverse

proc toBytes(n: uint16): seq[byte] =
  if n <= 0: return @[0'u8]
  var m = n
  while 0'u16 < m:
    let x = m and 255
    result.add x.byte
    m = m shr 8
  result.reverse

proc toUint16(n: seq[byte]): uint16 = (n[0].uint16 shl 8) + n[1].uint16

proc newSMF*(format: seq[byte], timeUnit: uint16): SMF =
  result.headerChunk = HeaderChunk(chunkType: headerChunkType,
                                   dataLength: headerDataLength,
                                   format: format,
                                   timeUnit: timeUnit)

proc newMIDITrack*(): Track = discard

proc newMIDIEvent*(deltaTime: uint32, status, channel, note, velocity: byte): MIDIEvent =
  discard

proc newMetaEvent*(): Track = discard

proc isSMFFile*(path: string): bool =
  ## pathのファイルがSMFファイルであるかを判定する。
  ## 先頭4byteを読み取って判定する。
  var strm = newFileStream(path)
  if strm.isNil: return
  defer: strm.close

  var buf: array[4, byte]
  discard strm.readData(addr(buf), len(buf))
  result = buf == headerChunkType

proc chunkSize(t: TrackChunk): int =
  result = 8 + t.dataLength.mapIt(it.int).foldl(a+b)

proc addMetaSeqNo*(t: var TrackChunk) =
  t.data.add metaPrefix
  t.data.add 0x0
  t.data.add 0x2

proc getMetaData(n: byte, s: string): seq[byte] =
  result.add metaPrefix
  result.add n
  result.add s.len.byte
  result.add s.mapIt(it.byte)

proc addMetaText*(t: var TrackChunk, text: string) =
  t.data.add getMetaData(0x1, text)

proc addMetaCopyright*(t: var TrackChunk, copyright: string) =
  t.data.add getMetaData(0x2, copyright)

proc addMetaSeqTrackName*(t: var TrackChunk, trackName: string) =
  t.data.add getMetaData(0x3, trackName)

proc addMetaInstrumentName*(t: var TrackChunk, instrumentName: string) =
  t.data.add getMetaData(0x4, instrumentName)

proc addMetaLylic*(t: var TrackChunk, lylic: string) =
  t.data.add getMetaData(0x5, lylic)

proc addMetaEndOfTrack*(t: var TrackChunk) =
  t.data.add metaPrefix
  t.data.add 0x2F
  t.data.add 0x0

proc addMetaTempo*(t: var TrackChunk) =
  discard

proc addMetaTimeSignature*(t: var TrackChunk) =
  discard

proc addMetaKeySignature*(t: var TrackChunk) =
  discard

proc newChannelMessage(t: ChannelMessageType,
                       channelNo, noteNo, velocity: byte): ChannelMessage =
  result = case t
           of noteOn: [8'u8 + channelNo, noteNo, velocity]
           of noteOff: [9'u8 + channelNo, noteNo, velocity]
           of controlChange: [0xB'u8 + channelNo, noteNo, velocity]

proc toBytes(h: HeaderChunk): seq[byte] =
  result.add h.chunkType
  result.add h.dataLength
  result.add h.format
  result.add h.trackCount
  result.add h.timeUnit.toBytes

proc toBytes(t: TrackChunk): seq[byte] =
  result.add t.chunkType
  result.add t.dataLength

proc toBytes(s: SMF): seq[byte] =
  result.add s.headerChunk.toBytes
  for t in s.trackChunks:
    result.add t.toBytes

proc parseHeaderChunk(data: openArray[byte]): HeaderChunk =
  result.chunkType  = data[0..<4]            # 4byte
  result.dataLength = data[4..<8]            # 4byte
  result.format     = data[8..<10]           # 2byte
  result.trackCount = data[10..<12]          # 2byte
  result.timeUnit   = data[12..<14].toUint16 # 2byte

proc parseTrackChunk(data: openArray[byte]): TrackChunk =
  result.chunkType  = data[0..<4] # 4byte
  result.dataLength = data[4..<8] # 4byte
  var startPos = 8
  var part3 = startPos
  while part3+3 <= len(data):
    let part = data[part3..<part3+3]
    if part == endOfTrack:
      result.data = data[startPos..<part3+3]
      return
    inc part3

proc readSMF*(f: File): SMF =
  discard

proc readSMFFile*(path: string): SMF =
  var data = readFile(path).mapIt(it.byte)
  result.headerChunk = data.parseHeaderChunk

  data = data[headerChunkLength..^1]
  while 0 < len(data):
    let track = data.parseTrackChunk
    result.trackChunks.add track
    data = data[track.chunkSize..^1]

proc writeSMF*(f: File, data: SMF) =
  let d = data.toBytes
  discard f.writeBytes(d, 0, d.len)
  
proc writeSMFFile*(path: string, data: SMF) =
  var f = open(path, fmWrite)
  defer: f.close
  f.writeSMF(data)
  