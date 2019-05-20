import unittest
import sequtils, strutils

include smf

const midiFile = "tests/test.mid"

suite "toBytes(HeaderChunk)":
  test "Normal":
    let c = HeaderChunk(chunkType: headerChunkType,
                        dataLength: headerDataLength,
                        format: format1,
                        trackCount: 2,
                        timeUnit: 0x0180)
    var ret = headerChunkType
    ret.add @[0'u8, 0, 0, 6]
    ret.add format1
    ret.add @[0'u8, 2]
    ret.add @[0x01'u8, 0x80]
    check c.toBytes == ret

suite "toBytes":
  test "0 == 0": check 0.toBytes == @[0x0'u8]
  test "1 == 1": check 1.toBytes == @[0x1'u8]
  test "15 == F": check 15.toBytes == @[0xF'u8]
  test "255 == FF": check 255.toBytes == @[0xFF'u8]
  test "256 == 1 0": check 256.toBytes == @[0x1'u8, 0]
  test "65535 == FF FF": check 65535.toBytes == @[0xFF'u8, 0xFF]

suite "toUint16":
  test "0 0 == 0": check @[0'u8, 0].toUint16 == 0
  test "0 1 == 1": check @[0'u8, 1].toUint16 == 1
  test "0 FF == 255": check @[0'u8, 0xFF].toUint16 == 255
  test "1 0 == 256": check @[1'u8, 0].toUint16 == 256
  test "FF FF == 65535": check @[0xFF'u8, 0xFF].toUint16 == 65535

suite "isSMFFile":
  test "SMF file": check midiFile.isSMFFile
  test "Not SMF file": check "smf.nimble".isSMFFile == false
  test "Not exist file": check "not_exist".isSMFFile == false

let data = midiFile.readFile.mapIt(it.byte)

suite "parseHeaderChunk":
  test "Normal":
    let c = HeaderChunk(chunkType: headerChunkType,
                        dataLength: headerDataLength,
                        format: format1,
                        trackCount: 2,
                        timeUnit: 0x0180)
    check data.parseHeaderChunk == c

# suite "parseTrackChunk":
#   test "Normal":
#     let t = TrackChunk(chunkType: trackChunkType,
#                        dataLength: 1,
#                        data: @[],
#                        endOfTrack: endOfTrack)
#     check data[headerChunkLength..^1].parseTrackChunk == t

# suite "readSMFFile":
#   test "1":
#     echo midiFile.readSMFFile

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