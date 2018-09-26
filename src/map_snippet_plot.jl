
include("osm/OpenStreetMap2.jl")

using  LinearAlgebra, SparseArrays
#import OpenStreetMap2

mutable struct RouteData
    shortest_route
    fastest_route
    p
end

function generate_point_in_bounds(mapD::OpenStreetMap2.MapData)
    boundaries = mapD.bounds
    (rand() * (boundaries.max_y -  boundaries.min_y) + boundaries.min_y,
    rand() * (boundaries.max_x -  boundaries.min_x) + boundaries.min_x)
end

function point_to_nodes(point::Tuple{Float64,Float64}, map_data::OpenStreetMap2.MapData)
    point = OpenStreetMap2.LLA(point[1],point[2])
    point = OpenStreetMap2.nearest_node(map_data.nodes,OpenStreetMap2.ENU(point, map_data.bounds), map_data.network)
end

function find_routes(pointA::Tuple{Float64,Float64},pointB::Tuple{Float64,Float64},
                    pointC::Tuple{Float64,Float64},
                    mapD::OpenStreetMap2.MapData, plotting = true, p = :none; width::Int=600, height::Int=600)::RouteData
    pointA = point_to_nodes(pointA, mapD)
    pointB = point_to_nodes(pointB, mapD)
    pointC = point_to_nodes(pointC, mapD)
    shortest_route, shortest_distance, shortest_time = OpenStreetMap2.shortest_route(mapD.network, pointA, pointB,pointC)
    fastest_route, fastest_distance, fastest_time = OpenStreetMap2.fastest_route(mapD.network, pointA, pointB,pointC)
    if plotting
        if p == :none
            p = OpenStreetMap2.plotmap(mapD.nodes, OpenStreetMap2.ENU(mapD.bounds), roadways=mapD.roadways,roadwayStyle = OpenStreetMap2.LAYER_STANDARD, width=width, height=height)
        end
        p = OpenStreetMap2.addroute!(p,mapD.nodes,fastest_route, route_color = "0x000000")
        p = OpenStreetMap2.addroute!(p,mapD.nodes,shortest_route,  route_color = "0xFF0000")
    end
    return RouteData(shortest_route,
    fastest_route,
    p)
end
