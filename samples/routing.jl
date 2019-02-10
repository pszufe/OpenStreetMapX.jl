using OpenStreetMapX

mapfile = "reno_east3.osm";  # This file can be found in test/data folder
datapath = "/home/ubuntu/";
map_data = get_map_data(datapath, mapfile,use_cache=false);

using Random
Random.seed!(0);

origin = generate_point_in_bounds(map_data);
destination = generate_point_in_bounds(map_data);

pointA = point_to_nodes(origin, map_data)
pointB = point_to_nodes(destination, map_data)

shortest_route1, shortest_distance1, shortest_time1 = shortest_route(map_data, pointA, pointB)
fastest_route1, fastest_distance1, fastest_time1 = fastest_route(map_data, pointA, pointB)

println("shortest_route nodes: ",shortest_route1)
println("fastest route nodes: ",fastest_route1)

### Create this file if you want to test routing with Google API
### The file should only contain your Google API key
google_api_file = joinpath(datapath,"googleapi.key")

if isfile(google_api_file)
    google_api_key = readlines(google_api_file)[1]
    google_route = get_google_route(pointA, pointB,map_data,google_api_key)[1]
    println("Google API route nodes : ",google_route)
end
