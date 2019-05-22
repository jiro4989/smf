import types
from algorithm import reversed

proc padZero*(data: openArray[byte], n: int): seq[byte] = 
  result.add data
  let diff = n - len(data)
  for i in 1..diff:
    result.insert(0, 0)

proc deltaTimeToOctal*(deltaTime: openArray[byte]): uint32 =
  ## 1000_0001 0111_1111 ->           1111_1111
  ## 1000_0011 0111_1111 -> 0000_0001 1111_1111
  let rev = deltaTime.reversed
  for i, v in rev:
    result += ((v.uint32 and 0b0111_1111) shl (7 * i))

proc parseDeltaTime*(data: openArray[byte]): seq[byte] =
  ## 先頭のデルタタイムを取得する。
  if data.len < 1: return
  var i: int
  var b = data[i]
  result.add b
  while (b and 0b1000_0000) == 0b1000_0000:
    inc i
    b = data[i]
    result.add b

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

proc toBytes*(n: uint32): seq[byte] =
  if n <= 0: return @[0'u8]
  var m = n
  while 0'u32 < m:
    let x = m and 255
    result.add x.byte
    m = m shr 8
  result = result.reversed

method toBytes*(event: Event): seq[byte] {.base.} = discard

method toBytes*(event: MIDIEvent): seq[byte] =
  result.add event.deltaTime.toDeltaTime
  result.add event.status + event.channel
  result.add event.note
  result.add event.velocity

method toBytes*(event: MetaEvent): seq[byte] =
  result.add event.deltaTime.toDeltaTime
  result.add event.metaPrefix
  result.add event.metaType
  result.add event.dataLength.toDeltaTime
  result.add event.data

proc toBytes*(h: HeaderChunk): seq[byte] =
  result.add h.chunkType
  result.add h.dataLength.toBytes.padZero(4)
  result.add h.format
  result.add h.trackCount.toBytes.padZero(2)
  result.add h.timeUnit.toBytes

proc toBytes*(t: TrackChunk): seq[byte] =
  result.add t.chunkType
  result.add t.dataLength.toBytes.padZero(4)
  for event in t.data:
    result.add event.toBytes
  result.add t.endOfTrack

proc toBytes*(s: SMF): seq[byte] =
  result.add s.headerChunk.toBytes
  for t in s.trackChunks:
    result.add t.toBytes

proc toUint16*(n: seq[byte]): uint16 = (n[0].uint16 shl 8) + n[1].uint16
proc toUint32*(n: seq[byte]): uint32 =
  (n[0].uint32 shl 24) + (n[1].uint32 shl 16) + (n[2].uint32 shl 8) + n[3].uint32
