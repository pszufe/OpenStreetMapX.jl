
###################################
# to idzie do map snippet
###################################


using CSV
using DataFrames, DataFramesMeta
using Distributions
using FreqTables 
using HTTP, HttpCommon
using JSON
using Query 
using Revise
using Shapefile
using StatsBase


###################################
# to edit

cd("C:\\Users\\Admin\\Documents\\OSMsim.jl\\src")

path_datasets = "D:\\project ea\\data for simulation"
    # datasets:
        # Businesses2018_CMA602,       DaytimePop2018_DA_CMA602,
        # DemoStats2018_DA_CMA602,     home_work_flows_Winnipeg_Pij_2018,
        # SAMPLE_WinnipegCMA_Schools,  SAMPLE_WinnipegCMA_TRAFCAN2017Q1,
        # ShoppingCentres2018_CMA602,  vehicles_SAMPLE_RVIO2018_Winnipeg_CMA_by_DA
    # map files: .osm, .dbf, .shx, .prj, .shp
        # winnipeg - city centre only.osm, Winnipeg CMA.osm, 
        # Winnipeg DAs PopWeighted Centroids.shp .dbf, .shx, .prj
    # *8 datasets processed by datasets_parse.jl 


###################################
# parameters

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


###################################
# modules and functions

include("map_snippet.jl")

include("datasets_dictionary.jl")
# include("datasets_parse.jl") # can be run only once to process and export 8 datasets
include("datasets_import.jl")

include("starting_location.jl")
include("agent_profile.jl")
include("destination_location.jl")
include("additional_activity.jl")

# WinnipegMap = loadMapData(path_datasets*"\\Winnipeg CMA.osm")
WinnipegMap = loadMapData(path_datasets*"\\winnipeg - city centre only.osm")

# Winnipeg city centre coordinates
function cityCentreCoordinates(LAT::Float64, LON::Float64)
    city_centre_LLA = LLA(LAT, LON)
    city_centre_ECEF = ECEF(city_centre_LLA)
    return city_centre_ECEF
end

function additionalActivitySelector()
    additionalActivitySchools()
    additionalActivityShopping()
    additionalActivityRecreation()
end



###################################
# Map snippet run
###################################


city_centre_ECEF = cityCentreCoordinates(49.895485, -97.138449) # LAT, LON

DA_home            = startLocationSelector(:ECYPOWUSUL).DA_id
agent_profile      = demographicProfileGenerator(); print(agent_profile)

DA_work            = destinationLocationSelectorJM().DA_id

estimateBusinessEmployees()
DA_work            = destinationLocationSelectorDP().DA_id


AdditionalActivity = DataFrame([String, String, Tuple, String], [:what, :when, :coordinates, :details], 0)

additionalActivitySelector()

AdditionalActivity


###################################
# Step 3 For a given starting point-destination pair select route choosing among the options

# a) shortest
# b) fastest
# c) Route indicated by Google API for different times of day (due to API restrictions this will be used for popular DA pairs)

# function findGoogleMapsApiPath(pointA::String, pointB::String, apikey::String)::Vector{Int64} Ktora zwraca listę 
# identyfikatorów skrzyżowań z biblioteki Bartosza. Jako parametry bierze to co zostanie wyszukane w Google maps api

# functions ... Routing modules (shortest, fastest, Google API, ...)

# function routingModuleSelector

# 2. Buffering - jeżeli jakaś droga już była wyznaczona
# 3. Żeby nie było drogi z da-n do da-n
# Żeby nie było drogi z da-n do da-n --> tylko dla tych samych start_da i end_da, czy robimy jakiś dystans?
# np jak odległość od start_da do end_da < 1km to nie wyznaczamy drogi? - zrobię dystans

r = :none

for i in 1:3
    pointA = startLocationSelector().coordinates;
    pointB = destinationLocationSelector().coordinates;
    r = findRoute(pointA, pointB, WinnipegMap, true, r==:none?(:none):(r.p))
end

display(r.p)



###################################
# Step 4 Calculate stats for each given intersection

# function agentProfileAgregator

#   a) DA distribution   (simplified)
#   b) demographic distribution (if demographic profile determines moving patterns)
#        - we have agreed to leave out that scenario for a while



###################################
# Google maps API

apikey = open("googleapi.key") do file
    read(file, String)
end

pointA = "49.77130,-97.02790"
pointB = "50.0302,-97.5141"

url = "https://maps.googleapis.com/maps/api/directions/json?origin="*pointA*"&destination="*pointB*"&key="*apikey
# arrival_time::Int -> check which TZ

res = HTTP.request("GET", url; verbose = 0)

println(res.status)
println(String(res.body))

res_json = JSON.parse(join(readlines(IOBuffer(res.body))," "))

open("res.json","w") do f
    JSON.print(f, res_json)
end

duration = res_json["routes"][1]["legs"][1]["duration"]["value"] # in seconds
distance = res_json["routes"][1]["legs"][1]["distance"]["value"] # in metres

steps = DataFrame([Float64, Float64, Float64, Float64], [:start_lat, :start_lon, :end_lat, :end_lon], 0)
for i in 1:size(res_json["routes"][1]["legs"][1]["steps"], 1)
    start_lat = res_json["routes"][1]["legs"][1]["steps"][i]["start_location"]["lat"]
    start_lon = res_json["routes"][1]["legs"][1]["steps"][i]["start_location"]["lng"]
    end_lat = res_json["routes"][1]["legs"][1]["steps"][i]["end_location"]["lat"]
    end_lon = res_json["routes"][1]["legs"][1]["steps"][i]["end_location"]["lng"]
    push!(steps, [start_lat, start_lon, end_lat, end_lon])
end

steps

# &waypoints=via:San Francisco|via:Mountain View|... = AdditionalActivities
# Requests using 10 or more waypoints, or waypoint optimization, are billed at a higher rate
# &waypoints=optimize:true|Barossa+Valley,SA|Clare,SA|Connawarra,SA|McLaren+Vale,SA&key=YOUR_API_KEY

# arrival_time::Int -> check in which TZ


# findGoogleMapsApiPath(pointA::String, pointB::String, apikey::String)::Vector{Int64}

nodes = ENU( mapD.osmData[1], center(mapD.bounds))
highways = mapD.osmData[2]
roads = roadways(highways)
bounds = ENU( mapD.bounds, center(mapD.bounds))

#cropMap!(nodes, bounds, highways=highways, buildings=mapD.osmData[3], features=mapD.osmData[4], delete_nodes=false)

intersections = findClassIntersections(highways, roads)
network = createGraph(segmentHighways(nodes, highways,  intersections, roads),intersections)

# rekursja jakoś żeby wybierało dalsze end punkty w razie powielania się nodesów i będzie cacy
function check()
    if pointA == pointB
        pointB = LLA(steps[i+1, :end_lat], steps[i+1, :end_lon])
        return(pointB)
    end
    check()
end

fastest_route = []


for i in 1:size(steps, 1)
    pointA = LLA(steps[i, :start_lat], steps[i, :start_lon])
    pointB = LLA(steps[i, :end_lat], steps[i, :end_lon])

    pointA = nearestNode(nodes, ENU(pointA , center(mapD.bounds)), network)
    pointB = nearestNode(nodes,  ENU(pointB , center(mapD.bounds)), network)
    

    
    push!(fastest_route, fastestRoute(network, pointA, pointB)[1])

end

x = [1,2,3,4,4,5,5,5,6]
y = [2,3,4,4,5,5,5,6,8]

function a(x)
    z = x * 2
    function b(z)
        z += 1
    end
    b(z)
end

for i in 1:size(x, 1)
    pointA = x[i]
    pointB = y[i]
    print(i, " --- pointA: ", pointA, " - pointB: ", pointB, "\n")
    
    function check()
        if pointA == pointB
            pointB = y[i+1]
        end
        check()
        return(pointB)
    end
    pointB = check()
    print(i, " --- pointA: ", pointA, " - pointB: ", pointB, "\n")
end

# ISSUES

# - women work in constructions?

# - DemoProfile: każda zmienna z innej parafii... --> są liczone dla różnych grup wiekowych, raz dla household, 
# raz per osobę,raz per osobę w wieku 15+, dzieci tylko dla par lub samotnych, a raz w ogóle nie wiadomo jak to liczą... 

# - vehicles nie uwzględniamy bo są DA gdzie liczba samochodów jest wysoce sprzeczna z census data

# 50% of hh do not have children

# jak optymalnie sie robi ze zbiorem? tuż po wylosowaniu agenta filtruje df_demostat?

# @where w query --> df_recreationComplex

# !!! shopping centres - nowy dataset by się przydał

# żeby jakos do agent_profile dodac visited places

# optymalizacja dróg --> A + B + C / A + C jak najmniejsze --> i to determinuje też wybór punktów 

# recreation probabilities

# żeby wybierać add activities bardziej po drodze

# jakiś error handling?

może się gdzieś przyda

    μ = (parse(Int, sex_age[7:8]) + parse(Int, sex_age[9:10]))/2
    σ = (parse(Int, sex_age[9:10]) - μ)/3
    age = rand(Normal(μ, σ))


