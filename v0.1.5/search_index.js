var documenterSearchIndex = {"docs": [

{
    "location": "#",
    "page": "OpenStreetMapX.jl",
    "title": "OpenStreetMapX.jl",
    "category": "page",
    "text": ""
},

{
    "location": "#OpenStreetMapX.jl-1",
    "page": "OpenStreetMapX.jl",
    "title": "OpenStreetMapX.jl",
    "category": "section",
    "text": "Documentation for OpenStreetMapX.jlFor details please go to the Reference section."
},

{
    "location": "reference/#",
    "page": "Reference",
    "title": "Reference",
    "category": "page",
    "text": ""
},

{
    "location": "reference/#Reference-1",
    "page": "Reference",
    "title": "Reference",
    "category": "section",
    "text": "CurrentModule = OpenStreetMapX\nDocTestSetup = quote\n    using OpenStreetMapX\nend"
},

{
    "location": "reference/#OpenStreetMapX.MapData",
    "page": "Reference",
    "title": "OpenStreetMapX.MapData",
    "category": "type",
    "text": "The MapData represents all data that have been processed from OpenStreetMap osm file This is the main data structure used fot map data analytics.\n\nFields\n\nbounds :  bounds of the area map (stored as a OpenStreetMapX.Bounds object)\nnodes :  dictionary of nodes representing all the objects on the map (with coordinates in East, North, Up system)\nroadways :  unique roads stored as a OpenStreetMapX.Way objects\nintersections : roads intersections\ng : LightGraphs directed graph representing a road network\nv : vertices in the road network\ne : edges in the graph represented as a tuple (source,destination)\nw : edge weights, indexed by graph id\nclass : road class of each edge\n\n\n\n\n\n"
},

{
    "location": "reference/#OpenStreetMapX.get_map_data-Tuple{String,Union{Nothing, String}}",
    "page": "Reference",
    "title": "OpenStreetMapX.get_map_data",
    "category": "method",
    "text": "get_map_data(filepath::String,filename::Union{String,Nothing}=nothing;\n             road_levels::Set{Int} = Set(1:length(OpenStreetMapX.ROAD_CLASSES)),\n			 use_cache::Bool = true, only_intersections::Bool=true)::MapData\n\nHigh level function - parses .osm file and create the road network based on the map data.\n\nArguments\n\nfilepath : path with an .osm file (directory or path to a file)\nfilename : name of the file (when the first argument is a directory)\nroad_levels : a set with the road categories (see: OpenStreetMapX.ROAD_CLASSES for more informations)\nuse_cache : a *.cache file will be crated with a serialized map image in the datapath folder\nonly_intersections : include only road system data\n\n\n\n\n\n"
},

{
    "location": "reference/#OpenStreetMapX.LLA",
    "page": "Reference",
    "title": "OpenStreetMapX.LLA",
    "category": "type",
    "text": "LLA\n\nPoint in Latitude-Longitude-Altitude (LLA) coordinates Used to store node data in OpenStreetMapX XML files\n\nConstructors\n\nLLA(lat::Float64, lon::Float64)\nLLA(lat::Float64, lon::Float64, alt::Float64)\nLLA(xyz::XYZ)\n\nArguments\n\nlat : lattitude\nlon : Longitude\nalt : altitude\n\n\n\n\n\n"
},

{
    "location": "reference/#OpenStreetMapX.ENU",
    "page": "Reference",
    "title": "OpenStreetMapX.ENU",
    "category": "type",
    "text": "ENU\n\nPoint in East-North-Up (ENU) coordinates.\n\nLocal cartesian coordinate system. Linearized about a reference point.\n\nConstructors\n\nENU(east::Float64, north::Float64, up::Float64)\nENU(east::Float64, north::Float64)\nENU(xyz::XYZ)\n\n\n\n\n\n"
},

{
    "location": "reference/#OpenStreetMapX.Bounds",
    "page": "Reference",
    "title": "OpenStreetMapX.Bounds",
    "category": "type",
    "text": "Bounds{T <: Union{LLA, ENU}}\n\nBounds for the LLA or ENUcoordinates.\n\n\n\n\n\n"
},

{
    "location": "reference/#Representing-map-data-1",
    "page": "Reference",
    "title": "Representing map data",
    "category": "section",
    "text": "MapData\nget_map_data(::String,::Union{String,Nothing}; ::Set{Int},::Bool,::Bool)\nLLA\nENU\nBounds"
},

{
    "location": "reference/#OpenStreetMapX.generate_point_in_bounds-Tuple{MapData}",
    "page": "Reference",
    "title": "OpenStreetMapX.generate_point_in_bounds",
    "category": "method",
    "text": "generate_point_in_bounds(m::MapData)\n\nGenerates a random pair of Latitude-Longitude coordinates within boundaries of map m\n\n\n\n\n\n"
},

{
    "location": "reference/#OpenStreetMapX.point_to_nodes-Tuple{Tuple{Float64,Float64},MapData}",
    "page": "Reference",
    "title": "OpenStreetMapX.point_to_nodes",
    "category": "method",
    "text": "point_to_nodes(point::Tuple{Float64,Float64}, m::MapData)\n\nConverts a pair Latitude-Longitude of coordinates  point to a node on a map m The result is a node indentifier.\n\n\n\n\n\n"
},

{
    "location": "reference/#OpenStreetMapX.point_to_nodes-Tuple{LLA,MapData}",
    "page": "Reference",
    "title": "OpenStreetMapX.point_to_nodes",
    "category": "method",
    "text": "point_to_nodes(point::LLA, m::MapData)\n\nConverts a pair of coordinates LLA (Latitude-Longitude-Altitude) point to a node on a map m The result is a node indentifier.\n\n\n\n\n\n"
},

{
    "location": "reference/#OpenStreetMapX.shortest_route-Tuple{MapData,Int64,Int64}",
    "page": "Reference",
    "title": "OpenStreetMapX.shortest_route",
    "category": "method",
    "text": "shortest_route(m::MapData, node1::Int, node2::Int)\n\nFind Shortest route between node1 and node2 on map m.\n\n\n\n\n\n"
},

{
    "location": "reference/#OpenStreetMapX.shortest_route-Tuple{MapData,Int64,Int64,Int64}",
    "page": "Reference",
    "title": "OpenStreetMapX.shortest_route",
    "category": "method",
    "text": "shortest_route(m::MapData, node1::Int, node2::Int, node3::Int)\n\nFind Shortest route between node1 and node2 and node3 on map m.\n\n\n\n\n\n"
},

{
    "location": "reference/#OpenStreetMapX.fastest_route-Tuple{MapData,Int64,Int64,Dict{Int64,Float64}}",
    "page": "Reference",
    "title": "OpenStreetMapX.fastest_route",
    "category": "method",
    "text": "fastest_route(m::MapData, node1::Int, node2::Int,\n              speeds::Dict{Int,Float64}=SPEED_ROADS_URBAN)\n\nFind fastest route between node1 and node2  on map m with assuming speeds for road classes.\n\n\n\n\n\n"
},

{
    "location": "reference/#OpenStreetMapX.fastest_route-Tuple{MapData,Int64,Int64,Int64,Dict{Int64,Float64}}",
    "page": "Reference",
    "title": "OpenStreetMapX.fastest_route",
    "category": "method",
    "text": "fastest_route(m::MapData, node1::Int, node2::Int, node3::Int,\n              speeds::Dict{Int,Float64}=SPEED_ROADS_URBAN)\n\nFind fastest route between node1 and node2 and node3  on map m with assuming speeds for road classes.\n\n\n\n\n\n"
},

{
    "location": "reference/#Routing-operations-1",
    "page": "Reference",
    "title": "Routing operations",
    "category": "section",
    "text": "generate_point_in_bounds(::MapData)\npoint_to_nodes(::Tuple{Float64,Float64}, ::MapData)\npoint_to_nodes(::LLA, ::MapData)\nshortest_route(::MapData, ::Int, ::Int)\nshortest_route(::MapData, ::Int, ::Int, ::Int)\nfastest_route(::MapData, ::Int, ::Int, ::Dict{Int,Float64})\nfastest_route(::MapData, ::Int, ::Int, ::Int, ::Dict{Int,Float64})\n"
},

{
    "location": "reference/#OpenStreetMapX.get_google_route-Tuple{Int64,Int64,MapData,String}",
    "page": "Reference",
    "title": "OpenStreetMapX.get_google_route",
    "category": "method",
    "text": "get_google_route(origin::Int, destination::Int,\n                 map_data:MapData, googleapi_key::String;\n                 googleapi_parameters::Dict{Symbol,String} = googleAPI_parameters)\n\nGet route from to based on Google Distances API with two points (origin and destination) on map map_data using Google API key googleapi_key with optional Google Distances API request parameters googleapi_parameters.\n\n\n\n\n\n"
},

{
    "location": "reference/#OpenStreetMapX.get_google_route-Tuple{Int64,Int64,Int64,MapData,String}",
    "page": "Reference",
    "title": "OpenStreetMapX.get_google_route",
    "category": "method",
    "text": "get_google_route(origin::Int, destination::Int, waypoint::Int,\n                 map_data:MapData, googleapi_key::String;\n                 googleapi_parameters::Dict{Symbol,String} = googleAPI_parameters)\n\nGet route from to based on Google Distances API with three points (origin, destination and waypoint between) on map map_data using Google API key googleapi_key with optional Google Distances API request parameters googleapi_parameters.\n\n\n\n\n\n"
},

{
    "location": "reference/#OpenStreetMapX.node_to_string-Tuple{Int64,MapData}",
    "page": "Reference",
    "title": "OpenStreetMapX.node_to_string",
    "category": "method",
    "text": "node_to_string(node_id::Int,map_data::MapData)\n\nConvert node coordinates (stored in ENU system in the nodes field of map_data) identified by node_id to string with LLA system coordinates\n\n\n\n\n\n"
},

{
    "location": "reference/#OpenStreetMapX.googleAPI_parameters",
    "page": "Reference",
    "title": "OpenStreetMapX.googleAPI_parameters",
    "category": "constant",
    "text": "Dictionary for Google Distances API requests:\n\nKeys\n\n:url : url for google API, only JSON files outputs are accepted\n:mode : transportation mode used in simulation, in the current library scope only driving is accepted\n:avoid : map features to avoid (to mantain compatibility with OSM routes ferries should be avoided)\n:units : unit system for displaing distances (changing to imperial needs deeper changes in both OSMsim and OpenStreetMapX modules)\n\n\n\n\n\n"
},

{
    "location": "reference/#Google-API-routing-1",
    "page": "Reference",
    "title": "Google API routing",
    "category": "section",
    "text": "get_google_route(::Int,::Int,::MapData,::String; ::Dict{Symbol,String})\nget_google_route(::Int,::Int,::Int,::MapData,::String; ::Dict{Symbol,String})\nnode_to_string(::Int,::MapData)\ngoogleAPI_parameters"
},

]}
