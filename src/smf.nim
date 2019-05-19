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
    chunkType, dataLength, format, trackCount, timePart: seq[byte]
  TrackChunk = object
    chunkType, dataLength, data: seq[byte]
  SMF* = object
    headerChunk: HeaderChunk
    trackChunks: seq[TrackChunk]
  ChannelMessage* = array[3, byte]
  ChannelMessageType* = enum
    noteOn, noteOff, controlChange
  SysEx* = byte

const
  headerChunkType* = @[0x4d'u8, 0x54, 0x68, 0x64] ## MThd
  headerDataLength* = @[0x00'u8, 0x00, 0x00, 0x06] ## 6
  headerFormat0* = @[0x00'u8, 0x00] ## 00
  headerFormat1* = @[0x00'u8, 0x01] ## 01
  headerFormat2* = @[0x00'u8, 0x02] ## 02
  # headerTrackCount* = @[0x00'u8, 0x01]
  #   ## format0の時は01になる
  headerTimePart = @[0x00'u8, 0x01]
    ## 時間単位
  headerChunkLength = 14 ## 14byte

  trackChunkType*: seq[byte] = @[0x4d'u8, 0x54, 0x72, 0x6b] ## MTrk
  trackDataLength: seq[byte] = @[] ## 4byte
  sysExF0: SysEx = 0xF0
  sysExF7: SysEx = 0xF7
  endOfTrack* = @[0xFF'u8, 0x2F, 0x00]

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

proc parseHeaderChunk(data: openArray[byte]): HeaderChunk =
  result.chunkType  = data[0..<4]   # 4byte
  result.dataLength = data[4..<8]   # 4byte
  result.format     = data[8..<10]  # 2byte
  result.trackCount = data[10..<12] # 2byte
  result.timePart   = data[12..<14] # 2byte

proc parseTrackChunk(data: openArray[byte]): TrackChunk =
  result.chunkType  = data[0..<4]   # 4byte
  result.dataLength = data[4..<8]   # 4byte
  var startPos = 8
  var part3 = startPos
  while part3+3 <= len(data):
    let part = data[part3..<part3+3]
    if part == endOfTrack:
      result.data = data[startPos..<part3+3]
      return
    inc part3

proc readSMFFile*(path: string): SMF =
  var data = readFile(path).mapIt(it.byte)
  result.headerChunk = data.parseHeaderChunk

  data = data[headerChunkLength..^1]
  while 0 < len(data):
    let track = data.parseTrackChunk
    result.trackChunks.add track
    data = data[track.chunkSize..^1]

proc toDeltaTime(n: int): seq[byte] = 
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
  while 0 < m:
    var b = byte(m and 0b0111_1111)
    if 0 < i:
      b += 0b1000_0000
    result.add b
    m = m shr 7
    inc i
  result.reverse

proc newChannelMessage(t: ChannelMessageType,
                       channelNo, noteNo, velocity: byte): ChannelMessage =
  result = case t
           of noteOn: [8'u8 + channelNo, noteNo, velocity]
           of noteOff: [9'u8 + channelNo, noteNo, velocity]
           of controlChange: [0xB'u8 + channelNo, noteNo, velocity]
