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
## See also:
## * http://maruyama.breadfish.jp/tech/smf/
## * https://qiita.com/PianoScoreJP/items/2f03ae61d91db0334d45

from algorithm import reverse
import streams

type
  HeaderChunk = object
    chunkType, dataLength, format, trackCount, timePart: seq[byte]
  TrackChunk = object
    chunkType, dataLength: seq[byte]
    sections: seq[seq[byte]]
  ChannelMessage* = array[3, byte]
  ChannelMessageType* = enum
    noteOn, noteOff, controlChange
  SysEx* = byte

const
  ## Header chunk
  ## ------------------------------------------------------------
  headerChunkType: seq[byte] = @[0x4d'u8, 0x54, 0x68, 0x64]
    ## "MThd
  headerDataLength: seq[byte] = @[0x00'u8, 0x00, 0x00, 0x06]
    ## 0006
  headerDataFormat: seq[byte] = @[0x00'u8, 0x00]
    ## 00 or 01 or 02
  headerTrackCount: seq[byte] = @[0x00'u8, 0x01]
    ## format0の時は01になる
  headerTimePart: seq[byte] = @[0x00'u8, 0x01]
    ## 時間単位

  ## Track chunk
  ## ------------------------------------------------------------
  trackChunkType: seq[byte] = @[0x4d'u8, 0x54, 0x72, 0x6b]
    ## 4byte
    ## "MTrk" static
  trackDataLength: seq[byte] = @[]
    ## 4byte
  trackDataBody: seq[byte] = @[]
    ## from trackDataLength
  sysExF0: SysEx = 0xF0
  sysExF7: SysEx = 0xf7
  endOfTrack = @[0xFF'u8, 0x2F, 0x00]

proc isSMFFile*(path: string): bool =
  ## pathのファイルがSMFファイルであるかを判定する。
  ## 先頭4byteを読み取って判定する。
  var strm = newFileStream(path)
  if strm.isNil: return
  defer: strm.close

  var buf: array[4, byte]
  discard strm.readData(addr(buf), len(buf))
  result = buf == headerChunkType

proc parseHeaderChunk*(data: seq[byte]): HeaderChunk =
  result.chunkType  = data[0..<4]   # 4byte
  result.dataLength = data[4..<8]   # 4byte
  result.format     = data[8..<10]  # 2byte
  result.trackCount = data[10..<12] # 2byte
  result.timePart   = data[12..<14] # 2byte

proc parseTrackChunk*(data: seq[byte]): TrackChunk =
  result.chunkType  = data[0..<4]   # 4byte
  result.dataLength = data[4..<8]   # 4byte
  var startPos = 8
  var part3 = startPos
  while startPos < len(data):
    let part = data[part3..<part3+3]
    if part == endOfTrack:
      result.sections.add data[startPos..<part3+3]
      part3 += 3
      startPos = part3
      continue
    inc part3

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