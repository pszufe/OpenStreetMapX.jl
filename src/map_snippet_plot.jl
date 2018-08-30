pth = "osm/";
path = "sim/";
datapath = "../../datasets/";

include(pth*"OpenStreetMap.jl")
include(path*"OSMSim.jl")

using OSMSim

struct MapData
    bounds::OpenStreetMap.Bounds{OpenStreetMap.LLA}
    nodes::Dict{Int,OpenStreetMap.ENU} 
    roadways::Array{OpenStreetMap.Way,1}
    intersections::Dict{Int,Set{Int}}
    network::OpenStreetMap.Network
end

mutable struct RouteData
    shortest_route
    fastest_route
    google_route
    p
end

function generate_point_in_bounds(mapD::MapData)
    boundaries = mapD.bounds
    (rand() * (boundaries.max_y -  boundaries.min_y) + boundaries.min_y,
    rand() * (boundaries.max_x -  boundaries.min_x) + boundaries.min_x)
end

function point_to_nodes(point::Tuple{Float64,Float64}, map_data::MapData)
    point = OpenStreetMap.LLA(point[1],point[2])
    point = OpenStreetMap.nearestNode(map_data.nodes,OpenStreetMap.ENU(point, map_data.bounds), map_data.network)
end

function map_data_to_sim_data(mapD::MapData,googleapi_key::String)::OSMSim.SimData
    return OSMSim.SimData([getfield(map_data,field) for field in fieldnames(map_data)]...,
    Dict{Int,Tuple{String,String}}(),
    Dict{String,Int}(),
    Dict{Int,Int}(),
    Dict{Int,Int}(),
    Dict{Int,Dict{Symbol,Int}}(),
    Array{Dict{Symbol,Union{String, Int,UnitRange{Int}}},1}(),
    Dict{Int,Int}(),
    sparse(I,0,0),
    googleapi_key )
end

function find_routes(pointA::Tuple{Float64,Float64},pointB::Tuple{Float64,Float64},
                    pointC::Tuple{Float64,Float64},
                    mapD::MapData,google = false, googleapi_key::Union{String,Void} = nothing, plotting = true, p = :none)::RouteData
    pointA = point_to_nodes(pointA, mapD)
    pointB = point_to_nodes(pointB, mapD)
    pointC = point_to_nodes(pointC, mapD)
    shortest_route, shortest_distance, shortest_time = OpenStreetMap.shortestRoute(mapD.network, pointA, pointB,pointC)
    fastest_route, fastest_distance, fastest_time = OpenStreetMap.fastestRoute(mapD.network, pointA, pointB,pointC)
	google_route = nothing
	if google
		sim_data = map_data_to_sim_data(mapD,googleapi_key)
		google_route, mode = OSMSim.get_google_route(pointA,pointC,pointB,sim_data)
	end
    if plotting
        if p == :none
            p = OpenStreetMap.plotMap(mapD.nodes, OpenStreetMap.ENU(mapD.bounds), roadways=mapD.roadways,roadwayStyle = OpenStreetMap.LAYER_STANDARD)
        end
        p = OpenStreetMap.addRoute!(p,mapD.nodes,fastest_route, routeColor = "0x000000")
        p = OpenStreetMap.addRoute!(p,mapD.nodes,shortest_route,  routeColor = "0xFF0000")
		if google
			p = OpenStreetMap.addRoute!(p,mapD.nodes,google_route,  routeColor = "0xCC00CC")
		end
    end
    return RouteData(shortest_route,
    fastest_route,
    google_route,
    p)
end

