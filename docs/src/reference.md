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
LLA
ENU
Bounds
```


Routing operations
------------------
```@docs
generate_point_in_bounds(::MapData)
point_to_nodes(::Tuple{Float64,Float64}, ::MapData)
point_to_nodes(::LLA, ::MapData)
shortest_route(::MapData, ::Int, ::Int)
shortest_route(::MapData, ::Int, ::Int, ::Int)
fastest_route(::MapData, ::Int, ::Int, ::Dict{Int,Float64})
fastest_route(::MapData, ::Int, ::Int, ::Int, ::Dict{Int,Float64})

```

Google API routing
------------------
```@docs
get_google_route(::Int,::Int,::MapData,::String; ::Dict{Symbol,String})
get_google_route(::Int,::Int,::Int,::MapData,::String; ::Dict{Symbol,String})
node_to_string(::Int,::MapData)
googleAPI_parameters
```
