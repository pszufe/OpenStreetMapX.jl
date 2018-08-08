
###################################
# Map snippet run
###################################


#cd("C:\\!BIBLIOTEKA\\EA\\OSMsim.jl\\src")
cd("C:\\Users\\Admin\\Documents\\OSMsim.jl\\src")
#path_datasets = "C:\\!BIBLIOTEKA\\EA\\datasets"
path_datasets = "D:\\project ea\\data for simulation"

include("map_snippet.jl")



###################################
## functions

"""
Generates a point on the map and returns its LLA coordinates
    
**Arguments**
* `mapD` : OpenStreetMap.OSMData object representing entire map
"""
function generate_point_in_bounds(mapD::OpenStreetMap.OSMData)
    boundaries = mapD.bounds
    (rand() * (boundaries.max_y -  boundaries.min_y) + boundaries.min_y,
    rand() * (boundaries.max_x -  boundaries.min_x) + boundaries.min_x)
end


"""
Converts a vector of LLA coordinates points to ENU format 
    
**Arguments**
* `dataset` : dataset with :LATITUDE and :LONGITUDE coordinates
* `mapD` : OpenStreetMap.OSMData object representing entire map
"""
function convert_points_toENU(dataset, mapD)
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

nodes, bounds, highways, roadways, intersections, segments, network = create_map(WinnipegMap)



###################################
## Create coordinates in osm format

convert_points_toENU(df_business, WinnipegMap)
convert_points_toENU(df_business_popstores, WinnipegMap)
convert_points_toENU(df_DAcentroids, WinnipegMap)
convert_points_toENU(df_recreationComplex, WinnipegMap)
convert_points_toENU(df_schools, WinnipegMap)
convert_points_toENU(df_shopping, WinnipegMap)

# Winnipeg city centre coordinates
city_centre_ENU = convert_points_toENU(DataFrame(LATITUDE = 49.895485, LONGITUDE = -97.138449), 
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



startLocation = start_location_selector(dict_df_DAcentroids, df_demostat_weight_var, weight_var)
DA_home, pointA = startLocation.DA_id, startLocation.coordinates

agent_profile = demographic_profile_generator(city_centre_ENU, DA_home, dict_df_DAcentroids, dict_df_demostat,
                                              max_distance_from_cc); println(agent_profile)

destinationLocation = destination_location_selectorJM(DA_home, dict_df_DAcentroids, dict_df_hwflows)
DA_work, pointB = destinationLocation.DA_id, destinationLocation.coordinates

#destinationLocation = destination_location_selectorDP(agent_profile, DA_home, df_business, dict_df_DAcentroids, 
#                                                    dict_df_demostat, dict_industry, q_centre, q_other)
#DA_work, pointB = destinationLocation.DA_id, destinationLocation.coordinates

dist = distance(dict_df_DAcentroids[DA_home][1, :ENU], dict_df_DAcentroids[DA_work][1, :ENU])

#=
## Buffering
## Condition
if dist < 2000 
    println("Distance between pointA and pointB is less than 2000")
    continue
end
=#

routingMode = route_module_selector(agent_profile, DA_home, DA_work, dict_df_DAcentroids)

additional_activity = additional_activity_selector(routingMode, agent_profile, DA_home, DA_work, 
                                      df_recreationComplex, df_schools, df_shopping,
                                      dict_df_business_popstores, dict_df_DAcentroids, dict_schoolcategory, 
                                      distance_radius_H, distance_radius_W, 
                                      p_shoppingcentre, p_shoppingMale,
                                      p_drugstore, p_petrol_station, p_supermarket, p_convinience, 
                                      p_other_retail, p_grocery, p_discount, p_mass_merchandise, 
                                      p_recreation_before, p_recreation_F, p_recreation_M,
                                      p_recreation_younger, p_recreation_older, young_old_limit,
                                      p_recreation_poorer, p_recreation_richer, poor_rich_limit)


###################################
# routing

p = :none
p = plotMap(nodes, bounds, roadways = roadways, roadwayStyle = OpenStreetMap.LAYER_STANDARD)

shortest = findroutes_waypoints(pointA, pointB, WinnipegMap, network, shortestRoute, additional_activity)
addRoute!(p, nodes, shortest.route, routeColor = 0x000053)

fastest = findroutes_waypoints(pointA, pointB, WinnipegMap, network, fastestRoute, additional_activity)
addRoute!(p, nodes, fastest.route, routeColor = 0xFF0000)

googlemaps = googlemapsroute(pointA, pointB, WinnipegMap, network, shortestRoute, now(), additional_activity)
addRoute!(p, nodes, googlemaps.route, routeColor = 0xcc00ff)

display(p)




###################################
# aggregation
#=
for node_id in list_of_node_ids_for_travel_path
   node_stats = Dict()
   if haskey(sim_stats,node_id)
       node_stats = sim_stats[node_id]
   end
   if  haskey(node_stats, tp.startingDA)
       node_stats[tp.startingDA] += 1
   else
       node_stats[tp.startingDA] = 1
   end
   sim_stats[node_id] = node_stats
end

DemoProfileStats = Dict{Int, Array()}()

node_id = shortest.route

agentProfileStatsAgregator = function(node_id) # :: DemoProfileStats
    if haskey(DemoProfileStats, node_id)
        DemoProfileStats[node_id][1] += 1 # + aggregowanie zmiennych 
    end
    # keys = nodes_id, values = array/df? pointA, pointB, before, after, ...
    
    
end
=#
