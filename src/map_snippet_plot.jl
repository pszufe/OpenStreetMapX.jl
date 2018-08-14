
include("osm\\OpenStreetMap.jl")
if (VERSION >= v"0.7.0")
	using Main.OpenStreetMap
else
    using OpenStreetMap
end

path_datasets = "C:\\!BIBLIOTEKA\\EA\\datasets"
WinnipegMap = parseOSM(path_datasets*"\\sgh.osm");

include("sim/routing_module.jl")
nodes, bounds, highways, roadways, intersections, segments, network = create_map(WinnipegMap);

p = plotMap(nodes, bounds, roadways = roadways, roadwayStyle = OpenStreetMap.LAYER_STANDARD)
display(p)
