from algorithm import reversed

proc toDeltaTime*(n: uint32): seq[byte] = 
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
