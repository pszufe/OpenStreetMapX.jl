################################################################
### Different types used in library with proper constructors ###
################################################################

#########################
### Coordinates Types ###
#########################

### Point in Latitude-Longitude-Altitude (LLA) coordinates
# Used to store node data in OpenStreetMap XML files
struct LLA
    lat::Float64
    lon::Float64
    alt::Float64
end
#constructor
LLA(lat, lon) = LLA(lat, lon, 0.0)

### Point in Earth-Centered-Earth-Fixed (ECEF) coordinates
# Global cartesian coordinate system rotating with the Earth
struct ECEF
    x::Float64
    y::Float64
    z::Float64
end

### Point in East-North-Up (ENU) coordinates
# Local cartesian coordinate system
# Linearized about a reference point
struct ENU
    east::Float64
    north::Float64
    up::Float64
end
#constructor
ENU(x, y) = ENU(x, y, 0.0)


### XYZ
# Helper for creating other point types in generic code
# e.g. myfunc{T <: Union(ENU, LLA)}(...) = (x, y = ...; T(XY(x, y)))
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
    Ellipsoid(a, b, e², e′²)
end
#constructor
function Ellipsoid(; a::Float64 = NaN, b::Float64= NaN, f_inv::Float64= NaN)
    if isnan(a) || isnan(b) == isnan(f_inv)
        throw(ArgumentError("Specify parameter 'a' and either 'b' or 'f_inv'"))
    elseif isnan(b)
		b = BigFloat(a) * (1 - inv(BigFloat(f_inv)))
		ellipsoid(BigFloat(a), BigFloat(b))
    else
        ellipsoid(BigFloat(a), BigFloat(b))
    end
end

###################
### Bounds Type ###
###################

type Bounds{T <: Union{LLA, ENU}}
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
    Bounds{LLA}(min_lat, max_lat, min_lon, max_lon)
end

##################
### Main Types ###
##################

type Highway
    @compat class::AbstractString       # Type of highway
    lanes::Int          # Number of lanes (1 if unspecified)
    oneway::Bool        # True if road is one-way
    @compat sidewalk::AbstractString    # Sidewalk classifier, if available
    @compat cycleway::AbstractString    # Cycleway classifier, if available
    @compat bicycle::AbstractString     # Bicycle classifier, if available
    @compat name::AbstractString        # Name, if available
    nodes::Vector{Int}  # List of nodes
end

type Segment
    node0::Int          # Source node ID
    node1::Int          # Target node ID
    nodes::Vector{Int}  # List of nodes falling within node0 and node1
    dist::Real          # Length of the segment
    class::Int          # Class of the segment
    parent::Int         # ID of parent highway
    oneway::Bool        # True if road is one-way
end

type Feature
    @compat class::AbstractString       # Shop, amenity, crossing, etc.
    @compat detail::AbstractString      # Class qualifier
    @compat name::AbstractString        # Name
end

type Building
    @compat class::AbstractString       # Building type (usually "yes")
    @compat name::AbstractString        # Building name (usually unavailable)
    nodes::Vector{Int}  # List of nodes
end

type Intersection
    highways::Set{Int}  # Set of highway IDs
end
Intersection() = Intersection(Set{Int}())

#to moze  wywalic
type HighwaySet # Multiple highways representing a single "street" with a common name
    highways::Set{Int}
end

#######################################
### Graph Representation of Network ###
#######################################

# Transporation network graph data and helpers to increase routing speed (do koniecznej zmiany)
type Network
    g                                   # Graph object
    v::Dict{Int,Int}  					# (node id) => (graph vertex)
    w::Vector{Float64}                  # Edge weights, indexed by edge id
	e::Array{Tuple{Int64,Int64},1}     	#edges in graph, stored as a tuple (source,destination)
    class::Vector{Int}                 	# Road class of each edge
	
end


######################
### OSM Data Types ###
######################

type OSMattributes
    oneway::Bool
    oneway_override::Bool
    oneway_reverse::Bool
    visible::Bool
    lanes::Int

    name::String
    class::String
    detail::String
    cycleway::String
    sidewalk::String
    bicycle::String

    # XML elements
    element::Symbol # :None, :Node, :Way, :Tag[, :Relation]
    parent::Symbol # :Building, :Feature, :Highway
    way_nodes::Vector{Int} # for buildings and highways

    id::Int # Uninitialized
    lat::Float64 # Uninitialized
    lon::Float64 # Uninitialized

    OSMattributes() = new(false,false,false,false,1,"","","","","","",:None,:None,[])
end


type OSMdata
    nodes::Dict{Int,LLA}
    highways::Dict{Int,Highway}
    buildings::Dict{Int,Building}
    features::Dict{Int,Feature}
    attr::OSMattributes 
	
	OSMdata() = new(Dict(),Dict(),Dict(),Dict(),OSMattributes())
end


############################
### Rendering Style Data ###
############################

### Rendering style data (tu moze zmienic bedzie trzeba)
type Style
    @compat color::UInt32
    width::Real
    @compat spec::AbstractString
end
Style(x, y) = Style(x, y, "-")
