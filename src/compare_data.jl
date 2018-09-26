pth = "C:\\Users\\p\\Desktop\\OSMsim.jl\\src\\osm"
path = "C:\\Users\\p\\Desktop\\OSMsim.jl\\src\\sim"
datapath = "C:\\Users\\p\\Desktop\\datasets\\"

datafile = "SAMPLE_WinnipegCMA_TRAFCAN2017Q1.csv"
sim_results = "counts.csv"
mapfile = "Winnipeg CMA.osm"

include(joinpath(pth,"OpenStreetMap2.jl"))
include(joinpath(path,"OSMsim.jl"))

using Main.OSMSim
using DataFrames
using Nanocsv
using GLM

function compare_data(datapath::String,mapfile::String,resultfile::String, testfile::String)
    bounds,nodes,roadways,intersections,network = OSMSim.read_map_file(datapath,mapfile)
    frame = DataFrames.DataFrame(Node_ID = Int[],latitude = Float64[], longitude = Float64[], empirical = Int[],simulation = Int[])
    traffic = Nanocsv.read_csv(joinpath(datapath,testfile))
    traffic_data = Dict()
    for i in 1:nrow(traffic)
        key = OpenStreetMap2.nearest_node(nodes,OpenStreetMap2.ENU(OpenStreetMap2.LLA(traffic[:LATITUDE][i],traffic[:LONGITUDE][i]),bounds),collect(keys(intersections)))
        if haskey(traffic_data, key)
            traffic_data[key][:TRAFFIC1][1] += traffic[i,:TRAFFIC1]
        else
            traffic_data[key] = traffic[i,[:LATITUDE,:LONGITUDE,:TRAFFIC1]]
        end
    end
    lines = readlines(open(joinpath(datapath,resultfile)))
    for line in lines
        x = parse.(Int,split(line))
        if haskey(traffic_data, x[1])
            push!(frame,(x[1],traffic_data[x[1]][:LATITUDE][1], traffic_data[x[1]][:LONGITUDE][1],traffic_data[x[1]][:TRAFFIC1][1], x[2]))
        end
    end
    model = GLM.lm(@formula(simulation ~ empirical - 1),frame)
    frame[:scaled_empirical] = GLM.predict(model)
    return frame, model
end

dataframe, model = compare_data(datapath,mapfile,sim_results,datafile)