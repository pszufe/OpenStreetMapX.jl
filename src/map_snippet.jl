
###################################
# Map snippet
###################################

include("open_map/OpenStreetMap.jl")
using OpenStreetMap

using CSV
using DataFrames, DataFramesMeta
using Dates
using Distributions
using FreqTables
using HTTP, HttpCommon
using JSON
using Query
using Revise
using Shapefile
using StatsBase

mutable struct RouteData
    shortest_route
    shortest_distance
    shortest_time
    fastest_route
    fastest_distance
    fastest_time
	p
end

function findRoutes(pointA,pointB,mapD::OpenStreetMap.OSMData,plotting = true, p = :none)::RouteData
    pointA = LLA(pointA[1],pointA[2])
    pointB = LLA(pointB[1],pointB[2])
    if !inBounds(pointA, mapD.bounds) && !inBounds(pointB, mapD.bounds)
        error("pointA or pointB not in the boundaries!")
    end
    #crop!(mapD,cropRelations = false)
    nodes = ENU(mapD.nodes, center(mapD.bounds))
    bounds = ENU(mapD.bounds, center(mapD.bounds))
    highways = filterHighways(extractHighways(mapD.ways))
    roadways = filterRoadways(highways, levels = Set(1:6))
    intersections = findIntersections(roadways)
    segments = findSegments(nodes,roadways,intersections)
    network = createGraph(segments, intersections, classifyRoadways(roadways))
    pointA = nearestNode(nodes, ENU(pointA , center(mapD.bounds)), network)
    pointB = nearestNode(nodes,  ENU(pointB , center(mapD.bounds)), network)
    shortest_route, shortest_distance, shortest_time = shortestRoute(network, pointA, pointB)
    fastest_route, fastest_distance, fastest_time = fastestRoute(network, pointA, pointB)
	if plotting
        if p == :none
            p = plotMap(nodes, bounds, roadways=roadways, roadwayStyle = OpenStreetMap.LAYER_STANDARD)
        end
        addRoute!(p,nodes,fastest_route,routeColor = 0xFF0000)
        addRoute!(p,nodes,shortest_route, routeColor = 0x000053)

    end
    return RouteData(shortest_route, shortest_distance, shortest_time,fastest_route, fastest_distance, fastest_time,p)
end




include("datasetsDictionary.jl")
# include("datasetsParse.jl") # can be run only once to process and export 8 datasets
include("datasetsImport.jl")
include("startingLocation.jl")
include("agentProfile.jl")
include("destinationLocation.jl")
include("additionalActivity.jl")
include("routingModule.jl")



###################################
# functions

>>>>>>> master
function generatePointInBounds(mapD::OpenStreetMap.OSMData)
    boundaries = mapD.bounds
    (rand() * (boundaries.max_y -  boundaries.min_y) + boundaries.min_y,
    rand() * (boundaries.max_x -  boundaries.min_x) + boundaries.min_x)
end

function cityCentreCoordinates(LAT::Float64, LON::Float64)
    city_centre_LLA = LLA(LAT, LON)
    city_centre_ECEF = ECEF(city_centre_LLA)
    return city_centre_ECEF
end



###################################
# parameters

# Winnipeg city centre coordinates
city_centre_ECEF = cityCentreCoordinates(49.895485, -97.138449) # LAT, LON

# maximum distance from DA_home to city_centre to assume DA_home is in the downtown
max_distance_from_cc = 8000

# weight_var - weighting variable name for selecting DA_home
weight_var = :ECYPOWUSUL

# variable name with unique id for each DA
DA_id = :PRCDDA

# shopping probability
p_shopping_F = 2/7 # female - twice a week
p_shopping_M = 1/7 # male - once a week

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
