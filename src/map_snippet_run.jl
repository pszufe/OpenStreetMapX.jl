###################################
# Map snippet run
###################################

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

include("map_snippet.jl")


# WinnipegMap = loadMapData(path_datasets*"\\Winnipeg CMA.osm")
WinnipegMap = parseOSM(path_datasets*"\\winnipeg - city centre only.osm")
createMap(WinnipegMap)


###################################
# Map snippet run
###################################

include("routingModule.jl")

p = :none
p = plotMap(nodes, bounds, roadways = roadways, roadwayStyle = OpenStreetMap.LAYER_STANDARD)

for i in 1:20
    startLocation = startLocationSelector(); # println(startLocation)
    DA_home, pointA = startLocation.DA_id, startLocation.coordinates

    agent_profile = demographicProfileGenerator(); # println(agent_profile)

    destinationLocation = destinationLocationSelectorJM(); # println(destinationLocation)
    DA_work, pointB = destinationLocation.DA_id, destinationLocation.coordinates

    # estimateBusinessEmployees()
    # destinationLocation = destinationLocationSelectorDP(); println(destinationLocation)
    # DA_work, pointB = destinationLocation.DA_id, destinationLocation.coordinates

    d = distance(df_DAcentroids[df_DAcentroids[:PRCDDA] .== DA_home, :ECEF][1],
                 df_DAcentroids[df_DAcentroids[:PRCDDA] .== DA_work, :ECEF][1])
    if d < 2000
        println("Distance between pointA and pointB is less than 2000")
        continue
    end

    AdditionalActivity = DataFrame([String, String, Tuple, String], [:what, :when, :coordinates, :details], 0)
    additionalActivitySelector(); # println(AdditionalActivity)

    mode = routingModuleSelector()
    if mode == "shortest"
        shortest = findRoutes(pointA, pointB, WinnipegMap, network, "shortest")
        addRoute!(p, nodes, shortest.route, routeColor = 0x000053)
    elseif mode == "fastest"
        fastest = findRoutes(pointA, pointB, WinnipegMap, network, "fastest")
        addRoute!(p, nodes, fastest.route, routeColor = 0xFF0000)
#    elseif mode == "googlemaps"
#        googlemaps = googlemapsRoute(pointA, pointB, WinnipegMap, network, "shortest", DateTime(2018,7,31,9,0))
#        addRoute!(p, nodes, googlemaps.route, routeColor = 0xcc00ff)
    end

    println(i)

end


println()
display(p)

# using Winston
# savefig("figure.png")


# before / after

p = :none
p = plotMap(nodes, bounds, roadways = roadways, roadwayStyle = OpenStreetMap.LAYER_STANDARD)

if size(AdditionalActivity[AdditionalActivity[:when] .== "before", :], 1) > 0
    before = AdditionalActivity[AdditionalActivity[:when] .== "before", :what][1]
    point_before = AdditionalActivity[AdditionalActivity[:when] .== "before", :coordinates][1]
end

if size(AdditionalActivity[AdditionalActivity[:when] .== "after", :], 1) > 0
    after = AdditionalActivity[AdditionalActivity[:when] .== "before", :what][1]
    point_after = AdditionalActivity[AdditionalActivity[:when] .== "before", :coordinates][1]
end

mode = "fastest"
if mode == "fastest"
    if length(before) > 0
        shortest = findRoutes(pointA, point_before, WinnipegMap, network, "fastest")
        shortest = findRoutes(point_before, pointB, WinnipegMap, network, "fastest")
        addRoute!(p, nodes, shortest.route, routeColor = 0x000053)
    end
    if length(after) > 0
        shortest = findRoutes(pointA, pointB, WinnipegMap, network, "fastest")
        shortest = findRoutes(pointB, point_after, WinnipegMap, network, "fastest")
        addRoute!(p, nodes, shortest.route, routeColor = 0x000053)
    end
end

display(p)


#for i in 1:5
#    pointA = generatePointInBounds(md);
#    pointB = generatePointInBounds(md);
#    r = findRoutes(pointA,pointB,md,true,r==:none?(:none):(r.p))
#end

#=
res_json = Dict()
open("res3.json", "r") do f
    global res_json
    dicttxt = readstring(f)  # file information to string
    res_json=JSON.parse(dicttxt)  # parse and transform data
end

# res3
pointA = (49.77130, -97.02790)
pointB = (50.0302, -97.5141)

# res4 fastest
pointA = (49.813489, -97.076064)
pointB = (49.960712, -97.206792)

# res5
pointA = (49.89187918088213, -97.17600550176572)
pointB = (49.89029964285568, -97.14410375907607)
=#

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

# 2. Buffering - jeżeli jakaś droga już była wyznaczona - to easy - dodać do statystyk
# 4. Additional activity dodać waypoints - najpierw jedzie before tam gdzie po drodze

# Step 4 Calculate stats for each given intersection
# function agentProfileAgregator
#   a) DA distribution   (simplified)
#   b) demographic distribution (if demographic profile determines moving patterns)
#        - we have agreed to leave out that scenario for a while


# ISSUES

# - women work in constructions?

# - DemoProfile: każda zmienna z innej parafii... --> są liczone dla różnych grup wiekowych, raz dla household,
# raz per osobę,raz per osobę w wieku 15+, dzieci tylko dla par lub samotnych, a raz w ogóle nie wiadomo jak to liczą...

# - vehicles nie uwzględniamy bo są DA gdzie liczba samochodów jest wysoce sprzeczna z census data

# 50% of hh do not have children

# jak optymalnie sie robi ze zbiorem? tuż po wylosowaniu agenta filtruje df_demostat?

# @where w query --> df_recreationComplex

# !!! shopping centres - nowy dataset by się przydał

# żeby jakos do agregowania dodac visited places

# optymalizacja dróg --> A + B + C / A + C jak najmniejsze --> i to determinuje też wybór punktów

# recreation probabilities

# żeby wybierać add activities bardziej po drodze

# jakiś error handling?

# eksport wykresy w dobrej jakości

# ECEF (ja) ENU (Bartek)

# schools - mozna dodać warunek na min dist - że pieszo idę

# add activity  - wyfiltrowałam max 1 przed i max 1 po

# ??? H - before - W - after - H ?
