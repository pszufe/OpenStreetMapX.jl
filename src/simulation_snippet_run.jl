
###################################
# Simulation snippet run
###################################

using CSV
using DataFrames, DataFramesMeta
using FreqTables 
using HTTP, HttpCommon
using JSON
using Query 
using Shapefile
using StatsBase


### TO EDIT

cd("C:\\Users\\Admin\\Documents\\OSMsim.jl\\src")

path_boundaries = "D:\\project ea\\data\\boundaries"
    # map files: .osm, .dbf, .shx, .prj, .shp
        # - winnipeg - city centre only.osm ( = winnipeg.osm from https://szufel.pl/winnipeg.zip)
        # - Winnipeg CMA.osm
        # - Winnipeg DAs PopWeighted Centroids.shp (.dbf, .shx, .prj)

path_datasets = "D:\\project ea\\data\\ea datasets"
    # EA files in path_datasets:
        # - Businesses2018_CMA602
        # - DaytimePop2018_DA_CMA602
        # - DemoStats2018_DA_CMA602
        # - home_work_flows_Winnipeg_Pij_2018
        # - SAMPLE_WinnipegCMA_Schools
        # - SAMPLE_WinnipegCMA_TRAFCAN2017Q1
        # - ShoppingCentres2018_CMA602
        # - vehicles_SAMPLE_RVIO2018_Winnipeg_CMA_by_DA

###

# OpenStreetMap library
include("map_snippet.jl")

## Winnipeg open street map
# WinnipegMap = loadMapData(path_boundaries*"\\Winnipeg CMA.osm")
WinnipegMap = loadMapData(path_boundaries*"\\winnipeg - city centre only.osm")



###################################
# Parse all EA datasets
# can be run only once to export below datasets

# include("parse_EAdata.jl")

# List of exported csv files into path_datasets:
# - data_business
# - data_DAcentroids
# - data_daytimep
# - data_demostat
# - data_hwflows
# - data_shopping
# - data_traffic
# - data_vehicles



###################################
# Import EA files and dictionaries (to change the format Union(..., missing))

data_business = CSV.read(path_datasets * "\\data_business.csv", allowmissing=:auto)
data_daytimep = CSV.read(path_datasets * "\\data_daytimep.csv", allowmissing=:auto)
data_demostat = CSV.read(path_datasets * "\\data_demostat.csv", allowmissing=:auto)
data_hwflows = CSV.read(path_datasets * "\\data_hwflows.csv", allowmissing=:auto)
data_traffic = CSV.read(path_datasets * "\\data_traffic.csv", allowmissing=:auto)
data_schools = CSV.read(path_datasets * "\\data_schools.csv")
data_shopping = CSV.read(path_datasets * "\\data_shopping.csv")
data_vehicles = CSV.read(path_datasets * "\\data_vehicles.csv", allowmissing=:auto)

data_DAcentroids = CSV.read(path_datasets * "\\data_DAcentroids.csv",  allowmissing=:auto)
data_DAcentroids[:LLA] = LLA.(data_DAcentroids[:LATITUDE], data_DAcentroids[:LONGITUDE]) # osm format
data_DAcentroids[:ECEF] = ECEF.(data_DAcentroids[:LLA]) # osm format

# Load variables map for above datasets as dictionaries named "dict_[file_name]"
include("parse_EAdata_Dict.jl")
include("parse_EAdata_DictDemostat.jl")

# :PRCDDA - unique DA id
# :ECYBAS15HP - working population aged 15+
# :ECYBASHPOP = :ECYHMAHPOP .+ :ECYHFAHPOP
# :ECYBASKID = :ECYCHA_0_4 .+ :ECYCHA_5_9 .+ :ECYCHA1014 .+ :ECYCHA1519 .+ :ECYCHA2024 .+ :ECYCHA25P



###################################
### Step 1 Select starting DA agent randomly weighted by demographic attributes

function calculateDAhomeWeights(weight_var::Symbol, 
                                df::DataFrame = data_demostat)::DataFrame
    
    # Calculates :weight_DA_Home for weighting starting DA 
    # Args:
    # weight_var - weighting variable name
    # df - dataframe with data for each :PRCDDA
    
    df[:weight_DA_Home] = df[weight_var]/sum(df[weight_var])
    
    return df
end



mutable struct DA_id_coord
    DA_id::Int64
    coordinates::Tuple{Float64, Float64}
end

function startLocationSelector(df::DataFrame = data_demostat, 
                               df_DACentroids::DataFrame = data_DAcentroids)::DA_id_coord
    
    # Selects starting DA_home for an agent randomly weighted by :weight_DA_Home
    # Args:
    # df - dataframe with :weight_DA_Home for each :PRCDDA
    # df_DACentroids - dataframe with :LATITUDE and :LONGITUDE for each :PRCDDA
    
    da_home = sample(df[:PRCDDA], Weights(df[:weight_DA_Home]))
    index = @where(df_DACentroids, :PRCDDA .== da_home)
    point_da_home = index[:LATITUDE][1], index[:LONGITUDE][1]
    
    return DA_id_coord(da_home, point_da_home)
end




mutable struct DemoProfile1 # to trzeba dopracować potem
    sex
    age_average
    marital_status
    occupation
    income_median
    household_size
    children_number_of
    children_age
    imigrant
    imigrant_since
end

function demographicProfileGenerator(da_home)::DemoProfile1
    
    # Creates socio-demographic profile of an agent
    # Args:
    # df - dataframe with :weight_DA_Home for each :PRCDDA
    # variables - array of variables from df e.g. [:colname1, :colname2] - ordered by DemoProfile
    
    # sex - docelowo trzeba wziąć tylko np population by sex aged 15+ 
    x = data_demostat[data_demostat[:PRCDDA] .== da_home, [:ECYHMAHPOP, :ECYHFAHPOP]]
    sex = sample(["male", "female"], fweights(Array(x)))

    # age_average - to trzeba bardziej fancy
    if sex == "male"
        age_average = data_demostat[data_demostat[:PRCDDA] .== da_home, [:ECYHMAAVG]][1]
    else
        age_average = data_demostat[data_demostat[:PRCDDA] .== da_home, [:ECYHFAAVG]][1]
    end

    # marital_status (only household population aged 15+)
    x = data_demostat[data_demostat[:PRCDDA] .== da_home, [:ECYMARMCL, :ECYMARNMCL]]
    marital_status = sample(["married or living with a common-law partner", 
                             "not married and not living with a common-law partner"], 
                            fweights(Array(x)))

    # occupation - alternatywnie work_industry
    x = data_demostat[data_demostat[:PRCDDA] .== da_home, [:ECYOCCNA, :ECYOCCMGMT, 
                                                           :ECYOCCBFAD, :ECYOCCNSCI, 
                                                           :ECYOCCHLTH, :ECYOCCSSER, 
                                                           :ECYOCCARTS, :ECYOCCSERV, 
                                                           :ECYOCCTRAD, :ECYOCCPRIM, 
                                                           :ECYOCCSCND]]
    occupation = sample(["Occupation Not Applicable",
                         "Management",
                         "Business Finance Administration",
                         "Occupations In Sciences",
                         "Occupations In Health",
                         "Occupations In Social Science, Education, Government, Religion",
                         "Occupations In Art, Culture, Recreation, Sport",
                         "Occupations In Sales And Service",
                         "Occupations In Trades, Transport, Operators",
                         "Occupations Unique To Primary Industries",
                         "Occupations Unique To Manufacture And Utilities"], 
                        fweights(Array(x)))

    # income_median
    income_median = data_demostat[data_demostat[:PRCDDA] .== da_home, [:ECYHRIMED]][1]

    # household_size
    x = data_demostat[data_demostat[:PRCDDA] .== da_home, [:ECYHSZ1PER, :ECYHSZ2PER, 
                                                           :ECYHSZ3PER, :ECYHSZ4PER, 
                                                           :ECYHSZ5PER]]
    household_size = sample(["1 Person", "2 Persons", "3 Persons", "4 Persons", "5 Persons"], 
                            fweights(Array(x)))

    # children_number_of - do ustalenia która zmienna bo jest ich milion?  # na razie metodą delficką :)
    children_number_of = sample([1, 2, 3, 4, 5], fweights([10, 10, 5, 2, 0.5]))

    # children_age
    children_age = []
    for i in 1:children_number_of
        x = data_demostat[data_demostat[:PRCDDA] .== da_home, [:ECYCHA_0_4, :ECYCHA_5_9, 
                                                               :ECYCHA1014, :ECYCHA1519, 
                                                               :ECYCHA2024, :ECYCHA25P]]
        children_age = push!(children_age, sample(["0 To 4", "5 To 9", "10 To 14", 
                                                   "15 To 19", "20 To 24", "25 Or More"], 
                                                  fweights(Array(x)))) 
    end

    # imigrant
    x = data_demostat[data_demostat[:PRCDDA] .== da_home, [:ECYPIMNI, :ECYPIMIM]]
    imigrant = sample(["Non-Immigrants", "Immigrants"], fweights(Array(x)))

    # imigrant_since
    if imigrant == "Immigrants"
        x = data_demostat[data_demostat[:PRCDDA] .== da_home, [:ECYPIMP01, :ECYPIM0105,
                                                               :ECYPIM0611, :ECYPIM12CY]]
        imigrant_since = "immigration date: " * sample(["Before 2001", "2001 To 2005", 
                                                 "2006 To 2011", "2012 To Present"], 
                                                fweights(Array(x)))
    else
        imigrant_since = ""
    end
    
    return DemoProfile(sex, age_average, marital_status, occupation, income_median, 
                       household_size, children_number_of, children_age, imigrant, imigrant_since)
    
end



not finished
###################################
### Step 2 Select Destination DA
# function destinationLocationSelector(da_home, stage)


## a) 1st stage randomly weighted by Pij journey matrix  (simplest option)
index = data_hwflows[:DA_Home] .== da_home
da_work = sample(data_hwflows[index, :DA_Work], Weights(data_hwflows[index, :weight_DA_Work]))
index = @where(data_DAcentroids, :PRCDDA .== da_work)
point_da_work = index[:LATITUDE][1], index[:LONGITUDE][1]



## b) second stage: extend on the destination selection on some demographic profile variable
# wagi przez liczbę biznesów + work_industry + funkcja przyporządkowująca starszym bliskie DA a młodszym bardziej centrum
@by(data_business, :PRCDDA, x = size(:BUSNAME)[1])

dict_IEMP_DESC = Dict()
for i in 1:size(levels(data_business[:IEMP_DESC]))[1]
    x = split(replace(levels(data_business[:IEMP_DESC])[i], "," => ""))
    # assumption: if there is no information concerning number of employees, this number is set to 1
    # there are 323 such businesses in Winnipeg, most of them ATMs
    if x[1] == "NA"
        y = 1 
    else 
        y = mean([parse(Int, x[1]), parse(Int, x[3])])
    end
    dict_IEMP_DESC[levels(data_business[:IEMP_DESC_est])[i]] = y
end

data_business[:IEMP_DESC_estimate] = 1.0

for i in 1:size(data_business, 1)
    data_business[i, :IEMP_DESC_estimate] = dict_IEMP_DESC[data_business[i, :IEMP_DESC]]
end



# c) third stage: include travel triangles home-work-activity-home
# function additionalActivitySelector 
# zwraca null, albo lokalizacja przedszkola, szkoły, sklepu itp --> na podstawie profilu demograficznego


# 2. Buffering - jeżeli jakaś droga już była wyznaczona
# 3. Żeby nie było drogi z da-n do da-n

levels!(data_business[:IEMP_DESC], ["1 - 4", "5 - 9", "10 - 19", "20 - 49", 
    "50 - 99", "100 - 249", "250 - 499", "500 - 999", "1,000 - 4,999", 
    "5,000 - 9,999"])

###################################
# Step 3 For a given starting point-destination pair select route choosing among the options

# a) shortest
# b) fastest
# c) Route indicated by Google API for different times of day (due to API restrictions this will be used for popular DA pairs)

# function findGoogleMapsApiPath(pointA::String, pointB::String, apikey::String)::Vector{Int64} Ktora zwraca listę 
# identyfikatorów skrzyżowań z biblioteki Bartosza. Jako parametry bierze to co zostanie wyszukane w Google maps api

# functions ... Routing modules (shortest, fastest, Google API, ...)

# function routingModuleSelector



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

url = "https://maps.googleapis.com/maps/api/distancematrix/json?origins="*pointA*"&destinations="*pointB*"&key="*apikey
# &departure_time=1343641500 - to po destination ale pewnie bez rożnicy

res = HTTP.request("GET", url; verbose=3)

println(res.status)
println(String(res.body))

res_json = JSON.parse(join(readlines(IOBuffer(res.body))," "))

open("res.json","w") do f
    JSON.print(f, res_json)
end

res_json # a gdzie są jakieś nodes? :-O

###################################
# DO SIMULATION SNIPPET

data_demostat = calculateDAhomeWeights("ECYPOWUSUL")


r = :none

for i in 1:3
    pointA = startLocationSelector().coordinates;
    pointB = destinationLocationSelector().coordinates;
    r = findRoute(pointA, pointB, WinnipegMap, true, r==:none?(:none):(r.p))
end

display(r.p)

# Przemek pytania

# MERYTORYCZNE:

# 1) Żeby nie było drogi z da-n do da-n --> tylko dla tych samych start_da i end_da, czy robimy jakiś dystans?
# np jak odległość od start_da do end_da < 1km to nie wyznaczamy drogi?

# 2) b) second stage: extend on the destination selection on some demographic profile variable --> to tylko 
# na podstawie demogaphic variable, całkowicie bez używania home-work matrix? 
# coś w stylu: starsi ludzie nie jeżdżą do DA oddalonych od DA_home o więcej niż 10km, a młodsi z większym
# prawdopodobieństem jeźdżą do cetrum i do miejsc gdzie jest dużo businesses

# 3) DemoProfile: każda zmienna z innej parafii... --> są liczone dla różnych grup wiekowych, raz dla household, raz per osobę, 
# raz per osobę w wieku 15+, dzieci tylko dla par lub samotnych, a raz w ogóle nie wiadomo jak to liczą... 

# Z JULII:

# 1) na ile to ma być ufunkcjonowane - np. czy zbiór danych też ma być w argumentach funkcji?

# 2) co to jest to verbose?

