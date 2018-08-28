pth = "osm/";
path = "sim/";
datapath = "../../datasets/";

include(pth*"OpenStreetMap.jl")
include(path*"OSMSim.jl")

using OSMSim

N = 1000

sim_data = get_sim_data(datapath);
nodes, buffer = run_simulation(sim_data,true,N)
