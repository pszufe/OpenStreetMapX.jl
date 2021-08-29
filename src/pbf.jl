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

function process_block(osm::OSMData, block::OSMPBF.HeaderBlock)
    # We don't currently use that information in `OSMData`
    box = block.bbox
    osm.bounds = Bounds(box.bottom / 1e9, box.top / 1e9, box.left / 1e9, box.right / 1e9)
    return
end

function geo(offset, granularity, int)
    return 0.000000001 * (offset + (granularity * int))
end

function tag(osm, element, table, key_id, value_id)
    tag(osm, element, table[key_id + 1], table[value_id + 1])
end

function process_elements(osm::OSMData, nodes::OSMPBF.DenseNodes, table, lat_offset, lon_offset, granularity)
    ids = nodes.id
    cumsum!(ids, ids)
    lat = nodes.lat
    cumsum!(lat, lat)
    lon = nodes.lon
    cumsum!(lon, lon)
    for i in eachindex(ids)
        @assert !haskey(osm.nodes, ids[i])
        osm.nodes[ids[i]] = LLA(
            geo(lat_offset, granularity, lat[i]),
            geo(lon_offset, granularity, lon[i]),
        )
    end
    i = 1
    j = 1
    keys_vals = nodes.keys_vals
    while j <= length(keys_vals)
        if iszero(keys_vals[j])
            i += 1
            j += 1
        else
            tag(osm, ids[i], table, keys_vals[j], keys_vals[j+1])
            j += 2
        end
    end
end

function process_element(osm, pbf_node::OSMPBF.Node, table, lat_offset, lon_offset, granularity)
    id = pbf_node.id
    osm.nodes[id] = LLA(
        geo(lat_offset, granularity, pbf_node.lat),
        geo(lon_offset, granularity, pbf_node.lon),
    )
    keys = pbf_node.keys
    vals = pbf_node.vals
    for i in eachindex(keys)
        tag(osm, id, table, keys[i], vals[i])
    end
end

function process_element(osm, pbf_way::OSMPBF.Way, table, lat_offset, lon_offset, granularity)
    way = Way(pbf_way.id)
    # `refs` is Δ coded
    refs = pbf_way.refs
    cumsum!(refs, refs)
    way.nodes = refs
    if isdefined(pbf_way, :keys)
        keys = pbf_way.keys
        vals = pbf_way.vals
        for i in eachindex(keys)
            tag(osm, way, table, keys[i], vals[i])
        end
    end
    push!(osm.ways, way)
    return
end

function process_element(osm, pbf_relation::OSMPBF.Relation, table, lat_offset, lon_offset, granularity)
    relation = Relation(pbf_relation.id)
    memids = pbf_relation.memids
    cumsum!(memids, memids)
    types = pbf_relation.types
    for i in eachindex(types)
        push!(relation.members, Dict(
            "type" => OSMPBF.Relation_MemberType[types[i] + 1],
            "ref" => string(memids[i]),
        ))
    end
    if isdefined(pbf_relation, :keys)
        keys = pbf_relation.keys
        vals = pbf_relation.vals
        for i in eachindex(keys)
            tag(osm, relation, table, keys[i], vals[i])
        end
    end
    push!(osm.relations, relation)
    return
end

function process_elements(osm, elements::Vector, table, lat_offset, lon_offset, granularity)
    for element in elements
        process_element(osm, element, table, lat_offset, lon_offset, granularity)
    end
end

function process_block(osm, block::OSMPBF.PrimitiveBlock)
    table = String.(block.stringtable.s)
    granularity = block.granularity
    lat_offset = block.lat_offset
    lon_offset = block.lon_offset
    for group in block.primitivegroup
        for key in fieldnames(OSMPBF.PrimitiveGroup)
            if isdefined(group, key)
                process_elements(osm, getproperty(group, key), table, lat_offset, lon_offset, granularity)
            end
        end
    end
end

function parsePBF(filename::AbstractString)
    osm = OSMData()
    open(filename) do io
        while !eof(io)
            block = parseblob(io)
            process_block(osm, block)
        end
    end
    return osm
end
