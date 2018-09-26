#################################################
### Polyline Algorithm Format encoder/decoder ###
#################################################


"""
Encode single coordinate (multiplied by 1e5 and rounded)

**Arguments**
* `val` : single coordinate (multiplied by 1e5 and rounded)

"""
function encode_one(val::Int)
    val <<= 1
    val = val < 0 ? ~val : val
    res = ""
    while val >= 0x20
        res *= Char((0x20 | (val & 0x1f)) + 63)
        val >>= 5
    end
    res *= Char(val + 63)
end

"""
Encode coordinates 

**Arguments**
* `coords` : coordinates in LLA system stored as a tuple

"""
function encode(coords::Tuple{Float64,Float64}...)
    prev_lat, prev_lon = 0,0
    res = ""
    for coord in coords
        lat,lon = trunc(Int, coord[1] *1e5), trunc(Int, coord[2]  *1e5) 
        res *= OpenStreetMapX.encode_one(lat - prev_lat) * encode_one(lon - prev_lon)
        prev_lat, prev_lon = lat,lon
    end
    return res
end

"""
Decode single coordinate

**Arguments**
* `polyline` : coordinates in Polyline Algorithm Format stored as an array of characters
* `index` : position of each single coordinate in polyline array

"""
function decode_one(polyline::Array{Char,1}, index::Int)
    byte = nothing
    res = 0
    shift = 0
    while isa(byte, Nothing) || byte >= 0x20
        byte = Int(polyline[index]) - 63
        index += 1
        res |= (byte & 0x1f) << shift
        shift += 5
    end
    res = Bool(res & 1) ? ~(res >> 1) : (res >> 1)
    return res, index
end

"""
Decode coordinates 

**Arguments**
* `polyline` : string containing coordinates in Polyline Algorithm Format

"""
function decode(polyline::String)
    polyline = collect(polyline)
    coords = Tuple{Float64,Float64}[]
    index = 1 
    lat, lon = 0.0,0.0
    while index < length(polyline)
        lat_change, index = OpenStreetMapX.decode_one(polyline,index)
        lon_change, index = OpenStreetMapX.decode_one(polyline,index)
        lat += lat_change
        lon += lon_change
        push!(coords, (lat/1e5,lon/1e5))
    end
    return coords
end