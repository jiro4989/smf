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

import smf/[smfread, smfwrite]
export smfread, smfwrite

