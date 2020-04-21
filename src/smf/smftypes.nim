import streams

type
  HeaderChunk* = ref object
    chunkType*: string
    dataLength*: uint32
    format*: uint16
    trackCount*: uint16
    timeUnit*: uint16
  TrackChunk* = ref object
    chunkType*: string
    dataLength*: uint32
    data*: Stream

const
  headerChunkType* = "MThd"
  trackChunkType* = "MTrk"
