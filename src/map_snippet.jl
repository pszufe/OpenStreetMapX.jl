###################################
# Map snippet
###################################


include("osm\\OpenStreetMap.jl")
using OpenStreetMap
using CSV
using DataFrames, DataFramesMeta
using Base.Dates
using Distributions
using FreqTables 
using HTTP, HttpCommon
using JSON
using Query 
using Revise
using Shapefile
using StatsBase


include("datasetsDescDict.jl")
# include("datasetsParse.jl") # can be run only once to process and export 8 datasets
include("datasetsImport.jl")
include("startingLocation.jl")
include("agentProfile.jl")
include("destinationLocation.jl")
include("additionalActivity.jl")
include("routingModule.jl")



###################################
## functions

function generatePointInBounds(mapD::OpenStreetMap.OSMData)
    boundaries = mapD.bounds
    (rand() * (boundaries.max_y -  boundaries.min_y) + boundaries.min_y,
    rand() * (boundaries.max_x -  boundaries.min_x) + boundaries.min_x)
end

function convertPointsToENU(dataset, mapD)
    dataset[:ENU] = ENU.(LLA.(dataset[:LATITUDE], dataset[:LONGITUDE]), center(mapD.bounds))
end



###################################
## parameters

# maximum distance from DA_home to city_centre to assume DA_home is in the downtown
max_distance_from_cc = 8000

# weight_var - weighting variable name for selecting DA_home
weight_var = :ECYPOWUSUL

# quantiles of the home - business distance for agents living in the downtown 
q_centre = 0.5
# quantiles of the home - business distance for agents NOT living in the downtown 
q_other = 0.7

# female shopping probabilities
p_shoppingcentre = 1/28 # once a month
p_drugstore = 1/21 # every three weeks
p_petrol_station = 1/7
p_supermarket = 1/7
p_convinience = 1/7
p_other_retail = 1/28    
p_grocery = 2/7    
p_discount = 1/7
p_mass_merchandise = 1/14
# male shopping probability
p_shoppingMale = 0.6 # males go shopping 40% less frequently than female

# radius around Home/Work within which an agent might go shopping
distance_radius_H = 3000      # metres
distance_radius_W = 2000      # metres

# working-out probabilities 
p_recreation_before = 0.4     # before work
p_recreation_F = 0.5          # for females
p_recreation_M = 0.7          # for males
p_recreation_younger = 0.8    # for younger
p_recreation_older = 0.2      # for older
young_old_limit = 55          # age at which agents get from younger to older
p_recreation_poorer = 0.2     # for poorer     
p_recreation_richer = 0.9     # for richer
poor_rich_limit = 100000      # income at which agents get from poorer to richer



###################################
## parse map

# WinnipegMap = parseOSM(path_datasets*"\\Winnipeg CMA.osm")
WinnipegMap = parseOSM(path_datasets*"\\winnipeg - city centre only.osm")

nodes, bounds, highways, roadways, intersections, segments, network = createMap(WinnipegMap)



###################################
## Create coordinates in osm format

convertPointsToENU(df_business, WinnipegMap)
convertPointsToENU(df_business_popstores, WinnipegMap)
convertPointsToENU(df_DAcentroids, WinnipegMap)
convertPointsToENU(df_recreationComplex, WinnipegMap)
convertPointsToENU(df_schools, WinnipegMap)
convertPointsToENU(df_shopping, WinnipegMap)

# Winnipeg city centre coordinates
city_centre_ENU = convertPointsToENU(DataFrame(LATITUDE = 49.895485, LONGITUDE = -97.138449), 
    WinnipegMap)[1]

	
	
###################################	
## Create dictionaries for datasets

dict_df_business_popstores = Dict()
for i in unique(values(desc_df_business_popstores))
    dict_df_business_popstores[i] = @where(df_business_popstores, :CATEGORY .== i)
end

dict_df_DAcentroids = Dict()
for i in df_DAcentroids[:PRCDDA]
    dict_df_DAcentroids[i] = @where(df_DAcentroids, :PRCDDA .== i)
end

dict_df_demostat = Dict()
for i in df_demostat[:PRCDDA]
    dict_df_demostat[i] = @where(df_demostat, :PRCDDA .== i)
end

dict_df_hwflows = Dict()
for i in unique(df_hwflows[:DA_home])
    dict_df_hwflows[i] = @where(df_hwflows, :DA_home .== i)
end

df_demostat_weight_var = df_demostat[[:PRCDDA, weight_var]]


