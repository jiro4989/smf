import unittest
import sequtils, strutils

include smf

const midiFile = "tests/test.mid"

suite "padZero":
  test "Normal":
    check [0'u8].padZero(2) == @[0'u8, 0]
    check [1'u8].padZero(2) == @[0'u8, 1]
    check [1'u8, 2].padZero(2) == @[1'u8, 2]
    check [1'u8, 2].padZero(4) == @[0'u8, 0, 1, 2]

suite "deltaTimeToOctal":
  test "127 (1 element)":
    check @[127'u8].deltaTimeToOctal == 127
  test "128 ~ 16383 (2 element)":
    check @[129'u8, 0].deltaTimeToOctal == 128
    check @[129'u8, 1].deltaTimeToOctal == 129
    check @[129'u8, 127].deltaTimeToOctal == 255
    check @[130'u8, 0].deltaTimeToOctal == 256
    check @[0b1111_1111'u8, 0b0111_1111].deltaTimeToOctal == 16383
  test "16384 (3 element)":
    check @[0b1000_0001'u8, 0b1000_0000, 0b0000_0000].deltaTimeToOctal == 16384

suite "parseDeltaTime":
  test "0 ~ 127 (1 elements)":
    check [0'u8, 2, 3].parseDeltaTime == @[0'u8]
    check [1'u8, 2, 3].parseDeltaTime == @[1'u8]
    check [127'u8, 2, 3].parseDeltaTime == @[127'u8]
  test "128 ~ (2 elements)":
    check [129'u8, 0, 3].parseDeltaTime == @[129'u8, 0]
    check [129'u8, 127, 3].parseDeltaTime == @[129'u8, 127]
  test "(3 elements)":
    check [129'u8, 129, 0].parseDeltaTime == @[129'u8, 129, 0]
    check [129'u8, 129, 1].parseDeltaTime == @[129'u8, 129, 1]
  test "Empty data":
    var empty: seq[byte]
    check empty.parseDeltaTime == empty

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

suite "toBytes(uint32)":
  test "0 == 0":
    check 0.toBytes == @[0x0'u8]
  test "1 == 1":
    check 1.toBytes == @[0x1'u8]
  test "15 == F":
    check 15.toBytes == @[0xF'u8]
  test "255 == FF":
    check 255.toBytes == @[0xFF'u8]
  test "256 == 1 0":
    check 256.toBytes == @[0x1'u8, 0]
  test "65535 == FF FF":
    check 65535.toBytes == @[0xFF'u8, 0xFF]

suite "toBytes(MIDIEvent)":
  test "Normal":
    let evt = MIDIEvent(deltaTime: 128, status: statusNoteOn, channel: 15, note: 0, velocity: 0)
    var data = @[0b1000_0001'u8, 0]
    data.add statusNoteOn + 15
    data.add 0
    data.add 0
    check evt.toBytes == data

suite "toBytes(MetaEvent)":
  test "Normal":
    discard

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

suite "toBytes(TrackChunk)":
  test "Normal":
    discard

suite "toBytes(SMF)":
  test "Normal":
    discard

suite "toUint16":
  test "0 0 == 0":
    check @[0'u8, 0].toUint16 == 0
  test "0 1 == 1":
    check @[0'u8, 1].toUint16 == 1
  test "0 FF == 255":
    check @[0'u8, 0xFF].toUint16 == 255
  test "1 0 == 256":
    check @[1'u8, 0].toUint16 == 256
  test "FF FF == 65535":
    check @[0xFF'u8, 0xFF].toUint16 == 65535

suite "toUint32":
  discard

suite "add(SMF)":
  test "Normal":
    var smfObj = newSMF(format0, 480)
    var track = newTrackChunk()
    smfObj.add track
    var smfObj2 = newSMF(format0, 480)
    check smfObj.headerChunk.trackCount == 1
    check smfObj.trackChunks[0] == track

# suite "add(TrackChunk)":
#   test "Normal":
#     var track = newTrackChunk()
#     track.add newMetaEvent(0, metaText, @[1'u8])
#     var track2 = newTrackChunk()
#     track2.dataLength += 
#     check track == track2

suite "delete(SMF)":
  test "Normal":
    var smfObj = newSMF(format1, 480)
    var track = newTrackChunk()
    smfObj.add track
    smfObj.add track
    smfObj.delete(1)
    check smfObj.headerChunk.trackCount == 1

    smfObj.delete(0)
    check smfObj.headerChunk.trackCount == 0

    expect(RangeError):
      smfObj.delete(0)

suite "isSMFFile":
  test "SMF file":
    check midiFile.isSMFFile
  test "Not SMF file":
    check "smf.nimble".isSMFFile == false
  test "Not exist file":
    check "not_exist".isSMFFile == false

suite "parseSysExEvent":
  test "F0":
    check @[0xf0'u8, 1, 0xf7].parseSysExEvent[] == SysExEvent(eventType: 0xf0, dataLength: 1, data: @[0xf7'u8])[]
  test "F0 (data length is 2)":
    var data = @[0xf0'u8, 129, 0]
    data.add 0'u8.repeat(127)
    data.add 0xf7

    var ret = 0'u8.repeat(127)
    ret.add 0xf7
    check data.parseSysExEvent[] == SysExEvent(eventType: 0xf0, dataLength: 128, data: ret)[]

suite "Read/Write example":
  test "Normal":
    var smfObj = newSMF(format0, 480)

    var track = newTrackChunk()
    for i in 1'u8..20:
      let n: byte = 0x30'u8 + i
      track.add newMIDIEvent(0, statusNoteOn, 0, n, 0x64)
      track.add newMIDIEvent(120, statusNoteOff, 0, n, 0)
    smfObj.add track

    writeSMFFile(midiFile, smfObj)

    let smfObj2 = readSMFFile(midiFile)
    echo "---------------"
    echo smfObj.headerChunk
    echo smfObj.trackChunks
    echo "---------------"
    echo smfObj2.headerChunk
    echo smfObj2.trackChunks
