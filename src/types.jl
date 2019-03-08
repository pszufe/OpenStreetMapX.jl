################################################################
### Different types used in library with proper constructors ###
################################################################

#########################
### Coordinates Types ###
#########################

"""
    LLA

Point in Latitude-Longitude-Altitude (LLA) coordinates
Used to store node data in OpenStreetMapX XML files

**Constructors**

    LLA(lat::Float64, lon::Float64)
	LLA(lat::Float64, lon::Float64, alt::Float64)
	LLA(xyz::XYZ)

**Arguments**

* `lat` : lattitude
* `lon` : Longitude
* `alt` : altitude

"""
struct LLA
    lat::Float64
    lon::Float64
    alt::Float64
end
LLA(lat, lon) = LLA(lat, lon, 0.0)


"""
    ECEF

Point in Earth-Centered-Earth-Fixed (ECEF) coordinates.
Global cartesian coordinate system rotating with the Earth.

**Constructors**

	ECEF(x::Float64, y::Float64, z::Float64)

"""
struct ECEF
    x::Float64
    y::Float64
    z::Float64
end


"""
    ENU

Point in East-North-Up (ENU) coordinates.

Local cartesian coordinate system.
Linearized about a reference point.

**Constructors**

	ENU(east::Float64, north::Float64, up::Float64)
	ENU(east::Float64, north::Float64)
	ENU(xyz::XYZ)

"""
struct ENU
    east::Float64
    north::Float64
    up::Float64
end
ENU(east, north) = ENU(east, north, 0.0)


### XYZ
#
"""
    XYZ

Helper for creating other point types in generic code
e.g. myfunc{T <: Union(ENU, LLA)}(...) = (x, y = ...; T(XY(x, y)))

**Constructors**

	XYZ(x::Float64, y::Float64, z::Float64)
	XY(x::Float64, y::Float64)
"""
struct XYZ
    x::Float64
    y::Float64
    z::Float64
end

XY(x, y) = XYZ(x, y, 0.0)
LLA(xyz::XYZ) = LLA(xyz.y, xyz.x, xyz.z)
ENU(xyz::XYZ) = ENU(xyz.x, xyz.y, xyz.z)


### Ellipsoid
# Specify datum for translation between LLA and other coordinate systems
struct Ellipsoid
    a::Float64        # Semi-major axis
    b::Float64        # Semi-minor axis
    e²::Float64       # Eccentricity squared
    e′²::Float64      # Second eccentricity squared
end

#auxiliary function
function ellipsoid(a::BigFloat, b::BigFloat)
    e² = (a^2 - b^2) / a^2
    e′² = (a^2 - b^2) / b^2
    OpenStreetMapX.Ellipsoid(a, b, e², e′²)
end
#constructor
function Ellipsoid(; a::Float64 = NaN, b::Float64= NaN, f_inv::Float64= NaN)
    if isnan(a) || isnan(b) == isnan(f_inv)
        throw(ArgumentError("Specify parameter 'a' and either 'b' or 'f_inv'"))
    elseif isnan(b)
        b = BigFloat(a) * (1 - inv(BigFloat(f_inv)))
        OpenStreetMapX.ellipsoid(BigFloat(a), BigFloat(b))
    else
        OpenStreetMapX.ellipsoid(BigFloat(a), BigFloat(b))
    end
end

"""
    Bounds{T <: Union{LLA, ENU}}

Bounds for the `LLA` or `ENU `coordinates.
"""
struct Bounds{T <: Union{LLA, ENU}}
    min_y::Float64
    max_y::Float64
    min_x::Float64
    max_x::Float64
end

function Bounds(min_lat, max_lat, min_lon, max_lon)
    if !(-90 <= min_lat <= max_lat <= 90 &&
         -180 <= min_lon <= 180 &&
         -180 <= max_lon <= 180)
        throw(ArgumentError("Bounds out of range of LLA coordinate system. " *
                            "Perhaps you're looking for Bounds{ENU}(...)"))
    end
    OpenStreetMapX.Bounds{OpenStreetMapX.LLA}(min_lat, max_lat, min_lon, max_lon)
end

##################
### Main Types ###
##################

abstract type
    OSMElement
end

mutable struct Way <: OSMElement
    id::Int
    nodes::Vector{Int}
    tags::Dict{String,String}
    Way(id::Int) = new(id, Vector{Int}(), Dict{String,String}())
end
tags(w::Way) = w.tags

mutable struct Relation <: OSMElement
    id::Int
    members::Vector{Dict{String,String}}
    tags::Dict{String,String}
    Relation(id::Int) = new(id, Vector{Dict{String,String}}(), Dict{String,String}())
end
tags(r::Relation) = r.tags

mutable struct Segment
    node0::Int          # Source node ID
    node1::Int          # Target node ID
    nodes::Vector{Int}  # List of nodes falling within node0 and node1
    distance::Real      # Length of the segment
    parent::Int         # ID of parent highway
end




######################
### OSM Data Types ###
######################

mutable struct OSMData
    nodes::Dict{Int,OpenStreetMapX.LLA}
    ways::Vector{OpenStreetMapX.Way}
    relations::Vector{OpenStreetMapX.Relation}
    features::Dict{Int,Tuple{String,String}}
    bounds::OpenStreetMapX.Bounds
    way_tags::Set{String}
    relation_tags::Set{String}
end
OSMData() = OSMData(Dict{Int, OpenStreetMapX.LLA}(), Vector{OpenStreetMapX.Way}(),
	            Vector{OpenStreetMapX.Relation}(), Dict{Int,String}(),
	            Bounds(0.0, 0.0, 0.0, 0.0), Set{String}(), Set{String}())

mutable struct DataHandle
    element::Symbol
    osm::OpenStreetMapX.OSMData
    node::Tuple{Int64,OpenStreetMapX.LLA} # initially undefined
    way::OpenStreetMapX.Way # initially undefined
    relation::OpenStreetMapX.Relation # initially undefined
    bounds::OpenStreetMapX.Bounds # initially undefined
    DataHandle() = new(:None, OpenStreetMapX.OSMData())
end

"""
The `MapData` represents all data that have been processed from OpenStreetMap osm file
This is the main data structure used fot map data analytics.

**Fields**

* `bounds` :  bounds of the area map (stored as a OpenStreetMapX.Bounds object)
* `nodes` :  dictionary of nodes representing all the objects on the map (with coordinates in East, North, Up system)
* `roadways` :  unique roads stored as a OpenStreetMapX.Way objects
* `intersections` : roads intersections
* `g` : `LightGraphs` directed graph representing a road network
* `v` : vertices in the road network
* `e` : edges in the graph represented as a tuple (source,destination)
* `w` : edge weights, indexed by graph id
* `class` : road class of each edge
"""
struct MapData
    bounds::Bounds{LLA}
    nodes::Dict{Int,ENU}
    roadways::Array{Way,1}
    intersections::Dict{Int,Set{Int}}
    # Transporation network graph data and helpers to increase routing speed
    g::LightGraphs.SimpleGraphs.SimpleDiGraph{Int64} # Graph object
    v::Dict{Int,Int}                             # (node id) => (graph vertex)
	n::Dict{Int,Int}                             # (graph vertex) => (node id)
    e::Array{Tuple{Int64,Int64},1}                # Edges in graph, stored as a tuple (source,destination)
    w::SparseArrays.SparseMatrixCSC{Float64, Int}   # Edge weights, indexed by graph id
    class::Vector{Int}                           # Road class of each edge
	#MapData(bounds, nodes, roadways, intersections) = new(bounds, nodes, roadways, intersections, LightGraphs.SimpleGraphs.SimpleDiGraph{Int64}(), Dict{Int,Int}(), Tuple{Int64,Int64}[],  SparseMatrixCSC(Matrix{Float64}(undef,0,0)),Int[])
end
