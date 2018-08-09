
###################################
# Map snippet run
###################################


#cd("C:\\!BIBLIOTEKA\\EA\\OSMsim.jl\\src")
cd("C:\\Users\\Admin\\Documents\\OSMsim.jl\\src")
#path_datasets = "C:\\!BIBLIOTEKA\\EA\\datasets"
path_datasets = "D:\\project ea\\data for simulation"

include("map_snippet.jl")



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
