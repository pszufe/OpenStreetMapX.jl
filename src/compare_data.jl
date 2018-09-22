pth = "C:\\Users\\p\\Desktop\\OSMsim.jl\\src\\osm"
path = "C:\\Users\\p\\Desktop\\OSMsim.jl\\src\\sim"
datapath = "C:\\Users\\p\\Desktop\\datasets\\"

datafile = "SAMPLE_WinnipegCMA_TRAFCAN2017Q1.csv"
sim_results = "counts.csv"
mapfile = "Winnipeg CMA.osm"

include(joinpath(pth,"OpenStreetMap.jl"))
include(joinpath(path,"OSMsim.jl"))

using Main.OSMSim
using DataFrames
using CSVFiles
using GLM

function compare_data(datapath::String,mapfile::String,resultfile::String, testfile::String)
    bounds,nodes,roadways,intersections,network = OSMSim.read_map_file(datapath,mapfile)
    frame = DataFrames.DataFrame(Node_ID = Int[],empirical = Int[],simulation = Int[])
    traffic = DataFrames.DataFrame(CSVFiles.load(joinpath(datapath,testfile)))
    traffic_data = Dict{Int,Int}()
    for i in 1:nrow(traffic)
        key = OpenStreetMap.nearest_node(nodes,OpenStreetMap.ENU(OpenStreetMap.LLA(traffic[:LATITUDE][i],traffic[:LONGITUDE][i]),bounds),collect(keys(intersections)))
        if haskey(traffic_data, key)
            traffic_data[key] += traffic[i,:TRAFFIC1]
        else
            traffic_data[key] = traffic[i,:TRAFFIC1]
        end
    end
    lines = readlines(open(joinpath(datapath,resultfile)))
    for line in lines
        x = parse.(Int,split(line))
        if haskey(traffic_data, x[1])
            push!(frame,(x[1],traffic_data[x[1]],x[2]))
        end
    end
    model = GLM.lm(@formula(simulation ~ empirical - 1),frame)
    frame[:scaled_emprical] = GLM.predict(model)
    return frame, model
end

dataframe, model = compare_data(datapath,mapfile,sim_results,datafile)