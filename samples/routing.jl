using OpenStreetMapX

mapfile = "map2.osm";
datapath = "/home/ubuntu/";
map_data = OpenStreetMapX.get_map_data(datapath, mapfile);



function generate_point_in_bounds(map_data::OpenStreetMapX.MapData)
    boundaries = map_data.bounds
    (rand() * (boundaries.max_y -  boundaries.min_y) + boundaries.min_y,
    rand() * (boundaries.max_x -  boundaries.min_x) + boundaries.min_x)
end

function point_to_nodes(point::Tuple{Float64,Float64}, map_data::OpenStreetMapX.MapData)
    point = OpenStreetMapX.LLA(point[1],point[2])
    point = OpenStreetMapX.nearest_node(map_data.nodes,OpenStreetMapX.ENU(point, map_data.bounds), map_data.network)
end




origin = generate_point_in_bounds(map_data);
destination = generate_point_in_bounds(map_data);


pointA = point_to_nodes(origin, map_data)
pointB = point_to_nodes(destination, map_data)

shortest_route, shortest_distance, shortest_time = OpenStreetMapX.shortest_route(map_data.network, pointA, pointB)
fastest_route, fastest_distance, fastest_time = OpenStreetMapX.fastest_route(map_data.network, pointA, pointB)
   

println("shortest_route:",shortest_route)
println("fastest_route",fastest_route)