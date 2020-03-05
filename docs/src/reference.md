Reference
=========

```@meta
CurrentModule = OpenStreetMapX
DocTestSetup = quote
    using OpenStreetMapX
end
```

Representing map data
---------------------
```@docs
MapData
get_map_data(::String,::Union{String,Nothing}; ::Set{Int},::Bool,::Bool)
```

Coordinate systems
------------------
```@docs
ECEF
LLA
ENU
Bounds
center
inbounds
onbounds
```


Routing operations
------------------
```@docs
generate_point_in_bounds(::MapData)
point_to_nodes(::Tuple{Float64,Float64}, ::MapData)
point_to_nodes(::LLA, ::MapData)
shortest_route
fastest_route
a_star_algorithm
distance
```

Google API routing
------------------
```@docs
get_google_route(::Int,::Int,::MapData,::String; ::Dict{Symbol,String})
get_google_route(::Int,::Int,::Int,::MapData,::String; ::Dict{Symbol,String})
node_to_string(::Int,::MapData)
googleAPI_parameters
encode_one
encode
decode_one
decode
```


Routing parameters
------------------
```@docs
ROAD_CLASSES
CYCLE_CLASSES
PED_CLASSES
SPEED_ROADS_URBAN
SPEED_ROADS_RURAL
```
