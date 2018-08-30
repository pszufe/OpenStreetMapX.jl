include("map_snippet_plot.jl")

mapfile = "map.osm";
apikey = "googleapi.key";

map_data = MapData(OSMSim.read_map_file(datapath, mapfile)...);
googleapi_key = open(datapath*apikey) do file
    read(file, String)
end

r = :none

for i in 1:1
    origin = generate_point_in_bounds(map_data);
    destination = generate_point_in_bounds(map_data);
    waypoint = generate_point_in_bounds(map_data);
    r = find_routes(origin,waypoint,destination, map_data, true, googleapi_key,true,r==:none?(:none):(r.p))
end

display(r.p)