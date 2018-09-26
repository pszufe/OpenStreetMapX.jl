using OpenStreetMapX

mapfile = "mymap.osm";
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


println("shortest_route nodes: ",shortest_route)
println("fastest route nodes: ",fastest_route)

### Create this file if you want to test routing with Google API
### The file should only contain your Google API key
google_api_file = joinpath(datapath,"googleapi.key")


if isfile(google_api_file)
    google_api_key = readlines(google_api_file)[1]

    google_route = OpenStreetMapX.get_google_route(pointA, pointB,map_data,google_api_key)[1]
    println("Google API route nodes : ",google_route)
end
