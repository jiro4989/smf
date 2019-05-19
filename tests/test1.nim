import unittest
import sequtils, strutils, streams

include smf

const midiFile = "tests/test.mid"

suite "isSMFFile":
  test "SMF file":
    check midiFile.isSMFFile
  test "Not SMF file":
    check "smf.nimble".isSMFFile == false
  test "Not exist file":
    check "not_exist".isSMFFile == false

suite "parseHeaderChunk":
  test "1":
    var strm = newFileStream(midiFile)
    defer: strm.close

    var buf: array[100, byte]
    discard strm.readData(addr(buf), len(buf))
    echo buf.parseHeaderChunk

suite "toDeltaTime":
  when false:
    for i in 0..128*128:
      echo i, ": ", i.toDeltaTime.mapIt(it.BiggestInt.toBin(8)).join(",")
  test "1byte (0~127) 7bit":
    check 0.toDeltaTime == @[0b0000_0000'u8]
    check 1.toDeltaTime == @[0b0000_0001'u8]
    check 127.toDeltaTime == @[0b0111_1111'u8]
  test "2byte (128~32767) 15bit":
    check 128.toDeltaTime == @[0b1000_0001'u8, 0b0000_0000]
    check 129.toDeltaTime == @[0b1000_0001'u8, 0b0000_0001]
    check 130.toDeltaTime == @[0b1000_0001'u8, 0b0000_0010]
    check 255.toDeltaTime == @[0b1000_0001'u8, 0b0111_1111]
    check 256.toDeltaTime == @[0b1000_0010'u8, 0b0000_0000]
    check 257.toDeltaTime == @[0b1000_0010'u8, 0b0000_0001]
    check 16383.toDeltaTime == @[0b1111_1111'u8, 0b0111_1111] # 128 * 128 - 1
  test "3byte (32768~8388607) 23bit":
    check 16384.toDeltaTime == @[0b1000_0001'u8, 0b1000_0000, 0b0000_0000]
    check 16385.toDeltaTime == @[0b1000_0001'u8, 0b1000_0000, 0b0000_0001]
    check 2097151.toDeltaTime == @[0b1111_1111'u8, 0b1111_1111, 0b0111_1111]