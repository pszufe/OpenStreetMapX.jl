include("../src/OpenStreetMapX.jl")



mapfile = "map2.osm";
datapath = "../datasets/";
map_data = OpenStreetMapX.get_map_data(datapath, mapfile);


include("map_snippet_plot.jl")
routes = RouteData[]
for i in 1:10
    origin = generate_point_in_bounds(map_data);
    destination = generate_point_in_bounds(map_data);
    push!(routes,find_routes(origin,destination, map_data))
end

p = plotmap(map_data);

plotroutes!(p,map_data,routes);

display(p)
