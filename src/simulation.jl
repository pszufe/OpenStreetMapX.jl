pth = "osm/";
path = "sim/";
datapath = "../../datasets/";

include(pth*"OpenStreetMap.jl")
include(path*"OSMSim.jl")

using Main.OSMSim

N = 50;
mode = "business";

sim_data = get_sim_data(datapath);
nodes, buffer = run_simulation(sim_data,mode,N);

nodeids = collect(keys(nodes));
sort!(nodeids, by = (nodeid -> nodes[nodeid].count), rev=true);
for i in nodeids[1:5]
    show(nodes[i]); println();
end