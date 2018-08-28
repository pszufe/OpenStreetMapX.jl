#pth = "C:\\Users\\p\\Desktop\\OSMsim.jl\\src\\osm\\";
#path = "C:\\Users\\p\\Desktop\\OSMsim.jl\\src\\sim\\";
#datapath = "C:\\Users\\p\\Desktop\\data for simulation\\";

include(path*"OpenStreetMap.jl")
include(path*"OSMSim.jl")

using OSMSim

N = 1000

sim_data = get_sim_data(datapath);
nodes, buffer = run_simulation(sim_data,true,N)
