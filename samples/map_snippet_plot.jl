

using  LinearAlgebra, SparseArrays
#import OpenStreetMapX

mutable struct RouteData
    shortest_route
    fastest_route
end

function generate_point_in_bounds(mapD::OpenStreetMapX.MapData)
    boundaries = mapD.bounds
    (rand() * (boundaries.max_y -  boundaries.min_y) + boundaries.min_y,
    rand() * (boundaries.max_x -  boundaries.min_x) + boundaries.min_x)
end

function point_to_nodes(point::Tuple{Float64,Float64}, map_data::OpenStreetMapX.MapData)
    point = OpenStreetMapX.LLA(point[1],point[2])
    point = OpenStreetMapX.nearest_node(map_data.nodes,OpenStreetMapX.ENU(point, map_data.bounds), map_data.network)
end

function find_routes(pointA::Tuple{Float64,Float64},pointB::Tuple{Float64,Float64},
                    mapD::OpenStreetMapX.MapData)::RouteData
    pointA = point_to_nodes(pointA, mapD)
    pointB = point_to_nodes(pointB, mapD)

    shortest_route, shortest_distance, shortest_time = OpenStreetMapX.shortest_route(mapD.network, pointA, pointB)
    fastest_route, fastest_distance, fastest_time = OpenStreetMapX.fastest_route(mapD.network, pointA, pointB)

    return RouteData(shortest_route, fastest_route)
end


function plotmap(mapD::OpenStreetMapX.MapData; width::Int=600, height::Int=600)::Plots.Plot
    p = OpenStreetMapX.plotmap(mapD.nodes, OpenStreetMapX.ENU(mapD.bounds), roadways=mapD.roadways,roadwayStyle = OpenStreetMapX.LAYER_STANDARD, width=width, height=height)
    return p
end

function plotroutes!(p::Plots.Plot,mapD::OpenStreetMapX.MapData,routes::Vector{RouteData})
    for route in routes
        OpenStreetMapX.addroute!(p,mapD.nodes,route.fastest_route, route_color = "0x000000")
        OpenStreetMapX.addroute!(p,mapD.nodes,route.shortest_route,  route_color = "0xFF0000")
    end
end
