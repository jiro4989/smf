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

include smf/types, smf/consts, smf/utils, smf/ios

import streams

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

proc insert*(self: var SMF, track: TrackChunk, i: Natural = 0) =
  discard

proc insert*(self: var TrackChunk, track: Event, i: Natural = 0) =
  discard

proc delete*(self: var SMF, i: Natural = 0) =
  ## TODO error
  self.headerChunk.trackCount.dec
  self.trackChunks.delete(i)

proc delete*(self: var TrackChunk, i: Natural = 0) =
  ## TODO error
  let delData = self.data[i]
  let b = delData.toBytes
  self.dataLength -= b.len.uint32
  self.data.delete(i)

proc isSMFFile*(path: string): bool =
  ## pathのファイルがSMFファイルであるかを判定する。
  ## 先頭4byteを読み取って判定する。
  var strm = newFileStream(path)
  if strm.isNil: return
  defer: strm.close

  var buf: array[4, byte]
  discard strm.readData(addr(buf), len(buf))
  result = buf == headerChunkType
