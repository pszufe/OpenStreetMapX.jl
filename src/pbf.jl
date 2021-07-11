include("OSMPBF.jl")

using ProtoBuf, CodecZlib

const BLOCK = Dict(
    "OSMHeader" => OSMPBF.HeaderBlock(),
    "OSMData" => OSMPBF.PrimitiveBlock(),
)

function parseblob(io::IO)
    len = ntoh(read(io, Int32))
    h = read(io, len)
    bh = readproto(IOBuffer(h), OSMPBF.BlobHeader())
    blob_buf = IOBuffer(read(io, bh.datasize))
    b = readproto(blob_buf, OSMPBF.Blob())
    ok = transcode(ZlibDecompressor, b.zlib_data)
    if length(ok) != b.raw_size
        @warn("Uncompressed size $(length(ok)) bytes does not match $(b.raw_size).")
    end
    readproto(IOBuffer(ok), BLOCK[bh._type])
end

function read_pbf(filename)
    open(filename) do io
        while !eof(io)
            block = parseblob(io)
            @show typeof(block)
            # TODO do something with it
        end
    end
end
