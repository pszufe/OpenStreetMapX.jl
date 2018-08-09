
include("osm\\OpenStreetMap.jl")
using OpenStreetMap

path_datasets = "C:\\!BIBLIOTEKA\\EA\\datasets"
WinnipegMap = parseOSM(path_datasets*"\\winnipeg - city centre only.osm");

include("sim/routing_module.jl")
nodes, bounds, highways, roadways, intersections, segments, network = create_map(WinnipegMap);

p = plotMap(nodes, bounds, roadways = roadways, roadwayStyle = OpenStreetMap.LAYER_STANDARD)
display(p)
