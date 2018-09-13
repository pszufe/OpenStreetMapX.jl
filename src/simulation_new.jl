
using Distributed
Distributed.addprocs(2)

@everywhere begin
    using Random
    using Dates
    using Distributed
    using CSVFiles
    pth = "osm/";
    path = "sim/";
    datapath = "/home/ubuntu/datasets/";
    include(joinpath(pth,"OpenStreetMap.jl"))
    include(joinpath(path,"OSMSim.jl"))
    using Main.OSMSim
    mode = "business";
    resultspath="/home/ubuntu/results/"
end

N = 100;

sim_data = get_sim_data(datapath);


include("sim_new_run.jl")
