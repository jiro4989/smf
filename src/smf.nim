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
## See also:
## * http://maruyama.breadfish.jp/tech/smf/

const
  ## Header chunk
  ## ------------------------------------------------------------
  chunkType: seq[byte] = @[0x4d'u8, 0x54, 0x68, 0x64]
    ## "MThd
  dataLength: seq[byte] = @[0x00'u8, 0x00, 0x00, 0x06]
    ## 0006
  dataFormat: seq[byte] = @[0x00'u8, 0x00]
    ## 00 or 01 or 02
  trackCount: seq[byte] = @[0x00'u8, 0x01]
    ## format0の時は01になる
  timePart: seq[byte] = @[0x00'u8, 0x01]
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

proc toDeltaTime(n: int): seq[byte] = 
  ## octal to deltatime
  ## delta time format is 
  ## 0b1000_0000 0b0000_0000
  var m = n
  var i: int
  var data: byte
  var x: int
  while 1 <= (m / 128):
    x += 1
    m -= 128
  if 0 < x:
    result.add (x + 0b1000_0000).byte
  result.add m.byte