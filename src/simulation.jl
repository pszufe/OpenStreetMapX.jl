pth = "osm/";
path = "sim/";
datapath = "../../datasets/";

include(pth*"OpenStreetMap.jl")
include(path*"OSMSim.jl")

using Main.OSMSim

N = 1000;
mode = "business";

sim_data = get_sim_data(datapath);
nodes, buffer = run_simulation(sim_data,mode,N)
