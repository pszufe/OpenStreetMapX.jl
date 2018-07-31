
###################################
# Routing module
###################################


mutable struct RouteData
    route 
    distance
    time
end


function createMap(mapD::OpenStreetMap.OSMData)
    global nodes, bounds, highways, roadways, intersections, segments, network
    #crop!(mapD, cropRelations = false)
    nodes = ENU(mapD.nodes, center(mapD.bounds))
    bounds = ENU(mapD.bounds, center(mapD.bounds))
    highways = filterHighways(extractHighways(mapD.ways))
    roadways = filterRoadways(highways, levels = Set(1:6))
    intersections = findIntersections(roadways)
    segments = findSegments(nodes,roadways,intersections)
    network = createGraph(segments, intersections, classifyRoadways(roadways))
end


###################################
# Fastest, shortest routes

function findRoutes(pointA::Tuple{Float64,Float64}, pointB::Tuple{Float64,Float64}, 
                    mapD::OpenStreetMap.OSMData, network::OpenStreetMap.Network, 
                    routeMode::String)::RouteData
    # routeMode = "fastest" / "shortest"
    
    if !inBounds(LLA(pointA[1],pointA[2]), mapD.bounds) && !inBounds(LLA(pointB[1],pointB[2]), mapD.bounds)
        error("pointA or pointB not in the boundaries!")
    end

    pointA_node = nearestNode(nodes, ENU(LLA(pointA[1],pointA[2]), center(mapD.bounds)), network)
    pointB_node = nearestNode(nodes, ENU(LLA(pointB[1],pointB[2]), center(mapD.bounds)), network)

    if routeMode == "shortest"
        shortest_route, shortest_distance, shortest_time = shortestRoute(network, pointA_node, pointB_node)
        return RouteData(shortest_route, shortest_distance, shortest_time)
    end
    if routeMode == "fastest"
        fastest_route, fastest_distance, fastest_time = fastestRoute(network, pointA_node, pointB_node)
        return RouteData(fastest_route, fastest_distance, fastest_time)
    end
end



###################################
# Google Maps routing

apikey = open("googleapi.key") do file
    read(file, String)
end

function googlemapsRoute(pointA::Tuple{Float64,Float64}, pointB::Tuple{Float64,Float64}, 
                         mapD::OpenStreetMap.OSMData, network::OpenStreetMap.Network, 
                         routeMatchMode::String, arrival_dt::DateTime = now())::RouteData
   
    # routeMatchMode = "fastest" / "shortest"s
    # arrival_dt - full date e.g. DateTime(2018,8,20,9,0) 
    
    if !inBounds(LLA(pointA[1],pointA[2]), mapD.bounds) && !inBounds(LLA(pointB[1],pointB[2]), mapD.bounds)
        error("pointA or pointB not in the boundaries!")
    end
    
    pointA_str = string(pointA[1],",",pointA[2])
    pointB_str = string(pointB[1],",",pointB[2])

    # arrival_time — Specifies the desired time of arrival for transit directions, 
    # in seconds since midnight, January 1, 1970 UTC; Winnipeg = UTC - 5h (6h in winter time)
    arrival_time = round(Int, Dates.value(arrival_dt + Dates.Hour(5) - DateTime(1970,1,1,0,0,0))/1000)
    url = "https://maps.googleapis.com/maps/api/directions/json?origin="*pointA_str*
        "&destination="*pointB_str*"&arrival_time="*string(arrival_time)*"&key="*apikey    

    res = HTTP.request("GET", url; verbose = 0); println(res.status)
    res_json = JSON.parse(join(readlines(IOBuffer(res.body))," "))
    
    open("res4.json","w") do f
        JSON.print(f, res_json)
    end
    
    routeNodes_arr = []
    routeTime = res_json["routes"][1]["legs"][1]["duration"]["value"] # in seconds
    distance = res_json["routes"][1]["legs"][1]["distance"]["value"] # in metres
    
    n = size(res_json["routes"][1]["legs"][1]["steps"], 1)
    osm_distance, osm_routeTime = 0, 0

    for i in 0:n+1

        if i == 0 # from pointA on osm to pointA on googlemaps
            start_lat, start_lon = pointA
            end_lat = res_json["routes"][1]["legs"][1]["steps"][1]["start_location"]["lat"]
            end_lon = res_json["routes"][1]["legs"][1]["steps"][1]["start_location"]["lng"]  

        elseif i == n+1 # from pointB on googlemaps to pointB on osm
            start_lat = res_json["routes"][1]["legs"][1]["steps"][n]["start_location"]["lat"]
            start_lon = res_json["routes"][1]["legs"][1]["steps"][n]["start_location"]["lng"]
            end_lat, end_lon = pointB

        else
            start_lat = res_json["routes"][1]["legs"][1]["steps"][i]["start_location"]["lat"]
            start_lon = res_json["routes"][1]["legs"][1]["steps"][i]["start_location"]["lng"]
            end_lat   = res_json["routes"][1]["legs"][1]["steps"][i]["end_location"]["lat"]
            end_lon   = res_json["routes"][1]["legs"][1]["steps"][i]["end_location"]["lng"]    
        end

        start_osmnode = nearestNode(nodes, ENU(LLA(start_lat, start_lon), center(mapD.bounds)), network)
        end_osmnode   = nearestNode(nodes, ENU(LLA(end_lat, end_lon), center(mapD.bounds)), network)

        if start_osmnode != end_osmnode
            if routeMatchMode == "shortest"
                r = shortestRoute(network, start_osmnode, end_osmnode)
            else
                r = fastestRoute(network, start_osmnode, end_osmnode)
            end
            append!(routeNodes_arr, r[1])
            osm_distance += r[2]
            osm_routeTime += r[3]
        end
    end  
    println(osm_distance, "\n", osm_routeTime)
    routeNodes  = Array{Int}(routeNodes_arr)
    
    return RouteData(routeNodes, distance, routeTime)
end



function routingModuleSelector(pointA = DA_home, pointB = DA_work)::String
    
    d =  distance(df_DAcentroids[df_DAcentroids[:PRCDDA] .== DA_home, :ECEF][1], 
                  df_DAcentroids[df_DAcentroids[:PRCDDA] .== DA_work, :ECEF][1])
    popsize = df_demostat[df_demostat[DA_id] .== DA_home, weight_var][1]
    med_popsize = median(df_demostat[weight_var])
    
    if d < 5000
        mode = "shortest"
        
    elseif d < 15000
        if rand() > 0.4 
            mode = "fastest" 
            else 
            mode = "shortest" 
        end
        
    elseif popsize > med_popsize
        mode = "googlemaps"
    else
        mode = "fastest"
    end
    
    return mode
end


