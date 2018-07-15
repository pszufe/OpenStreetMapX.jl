
###################################
### TO EDIT

cd("C:\\Users\\Admin\\Documents\\OSMsim.jl\\src")

path_boundaries = "D:\\project ea\\data\\boundaries"
# map files: .osm, .dbf, .shx, .prj, .shp
# - winnipeg - city centre only.osm ( = winnipeg.osm from https://szufel.pl/winnipeg.zip)
# - Winnipeg CMA.osm

path_datasets = "D:\\project ea\\data\\ea datasets"
# EA files:
# - data_DAcentroids.csv
# - data_demostat.csv
# - data_hwflows.csv


###################################
using CSV, DataFrames, DataFramesMeta, Query, StatsBase

# Parse all EA datasets
#= will be useful later, right now only 3 EA csv files mentioned above needed
include("parse_EAdata.jl")
=#

include("map_snippet.jl")


data_DAcentroids = CSV.read(path_datasets * "\\data_DAcentroids.csv") # 1229 DAs centroids
data_demostat = CSV.read(path_datasets * "\\data_demostat.csv") # household population size per DA and DA_Home weights
data_hwflows = CSV.read(path_datasets * "\\data_hwflows.csv") # DA_Home-DA_Work flows and DA_Work weights

WinnipegCMA = loadMapData(path_boundaries*"\\Winnipeg CMA.osm")


r = :none

for i in 1:3
    pointA = generatePointInBounds(WinnipegCMA);
    pointB = generatePointInBounds(WinnipegCMA);
    r = findRoute(pointA,pointB,WinnipegCMA,true,r==:none?(:none):(r.p))
end

display(r.p)
