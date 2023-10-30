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
sample_map_path
sample_map
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
latlon
getX
getY
getZ
WGS84
```


Routing operations
------------------
```@docs
generate_point_in_bounds
point_to_nodes(::Tuple{Float64,Float64}, ::MapData)
point_to_nodes(::LLA, ::MapData)
shortest_route
fastest_route
a_star_algorithm
distance
get_distance
nodes_within_driving_time
nodes_within_driving_distance
nodes_within_weights
nearest_node
nodes_within_range
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


Map objects
-----------
```@docs
Way
Relation
```

Internal library functions
--------------------------
```@docs
boundary_point
centroid
classify_cycleways
classify_walkways
crop!
extract_highways
features_to_graph
filter_cycleways
filter_highways
filter_walkways
find_intersections
find_optimal_waypoint_approx
find_optimal_waypoint_exact
find_route
find_segments
```
