
###################################
# Routing module
###################################


mutable struct RouteData
    route 
    distance
    time
end


function create_map(mapD)
    #crop!(mapD, cropRelations = false)
    nodes = ENU(mapD.nodes, center(mapD.bounds))
    bounds = ENU(mapD.bounds, center(mapD.bounds))
    highways = filterHighways(extractHighways(mapD.ways))
    roadways = filterRoadways(highways, levels = Set(1:6))
    intersections = findIntersections(roadways)
    segments = findSegments(nodes,roadways,intersections)
    network = createGraph(segments, intersections, classifyRoadways(roadways))
    return nodes, bounds, highways, roadways, intersections, segments, network
end


###################################
# Fastest, shortest routes from pointA to pointB

"""
Returns fastest/shortest route between two points
    
**Arguments**
* `pointA` : start point - DA_home
* `pointB` : end point - DA_work
* `mapD` : OpenStreetMap.OSMData object representing entire map
* `network` : OpenStreetMap.Network object representing road graph
* `routingMode` : routing functon - fastestRoute/shortestRoute
"""
function findroutes(pointA, pointB, mapD, network, routingMode)::RouteData
    
    pointA_node = nearestNode(nodes, ENU(LLA(pointA[1],pointA[2]), center(mapD.bounds)), network)
    pointB_node = nearestNode(nodes, ENU(LLA(pointB[1],pointB[2]), center(mapD.bounds)), network)

    route, distance, time = routingMode(network, pointA_node, pointB_node)
    
    return RouteData(route, distance, time)
end



###################################
# Fastest, shortest routes with waypoints

"""
Returns fastest/shortest route between two points and waypoints
    
**Arguments**
* `pointA` : start point - DA_home
* `pointB` : end point - DA_work
* `mapD` : OpenStreetMap.OSMData object representing entire map
* `network` : OpenStreetMap.Network object representing road graph
* `routingMode` : routing functon - fastestRoute/shortestRoute
* `additional_activity` : waypoints - maximum one before work point and maximum one after work point 
"""
function findroutes_waypoints(pointA, pointB, mapD, network, routingMode, additional_activity)

    waypoints = additional_activity
    
    if length(waypoints.before) == 0 && length(waypoints.after) == 0
        r = findRoutes(pointA, pointB, mapD, network, routingMode)
        
    # before and after waypoints - route: pointA -> before -> pointB -> after -> pointA 
    elseif length(waypoints.before) > 0 && length(waypoints.after) > 0
        r  = findRoutes(pointA, waypoints.point_before, mapD, network, routingMode)

        r1 = findRoutes(waypoints.point_before, pointB, mapD, network, routingMode)
        r2 = findRoutes(pointB, waypoints.point_after, mapD, network, routingMode)
        r3 = findRoutes(waypoints.point_after, pointA, mapD, network, routingMode)
        
        append!(r.route, append!(r1.route[2:end], append!(r2.route[2:end], r3.route[2:end])))
        r.distance += r1.distance + r2.distance + r3.distance
        r.time     += r1.time     + r2.time     + r3.time
        
    # only before waypoint - route: pointA -> before -> pointB -> pointA 
    elseif length(waypoints.before) > 0 && length(waypoints.after) == 0
        r  = findRoutes(pointA, waypoints.point_before, mapD, network, routingMode)

        r1 = findRoutes(waypoints.point_before, pointB, mapD, network, routingMode)
        r2 = findRoutes(pointB, pointA, mapD, network, routingMode)
        
        append!(r.route, append!(r1.route[2:end], r2.route[2:end]))
        r.distance += r1.distance + r2.distance
        r.time     += r1.time    + r2.time
         
    # only after waypoint - route: pointA - pointB - after - pointA     
    elseif length(waypoints.before) == 0 && length(waypoints.after) > 0
        r = findRoutes(pointA, pointB, mapD, network, routingMode)

        r1 = findRoutes(pointB, waypoints.point_after, mapD, network, routingMode)
        r2 = findRoutes(waypoints.point_after, pointA, mapD, network, routingMode)
        
        append!(r.route, append!(r1.route[2:end], r2.route[2:end]))
        r.distance += r1.distance + r2.distance
        r.time     += r.time      + r2.time
    
    end

    return r
end



###################################
# Google Maps routing with waypoints

apikey = open("googleapi.key") do file
    read(file, String)
end

# change LLA coordinates (x::Float64, y::Float64) to ::String
function changeCoordToString(point)::String
    return string(point[1],",",point[2])
end

"""
Requests google maps API for directions between points and parses the response into OSM nodes
    
**Arguments**
* `pointA` : start point - DA_home
* `pointB` : end point - DA_work
* `mapD` : OpenStreetMap.OSMData object representing entire map
* `network` : OpenStreetMap.Network object representing road graph
* `routingMatchMode` : the way google API nodes are mapped with OSM nodes - fastestRoute/shortestRoute
* `arrival_dt` : arrival time in DateTime format (e.g. DateTime(2018,8,20,9,0) ) 
* `additional_activity` : waypoints - maximum one before work point and maximum one after work point 
   (google accepts up to 8 waipoints per request)
"""
function googlemapsroute(pointA, pointB, mapD, network, routingMatchMode, arrival_dt, additional_activity)::RouteData

    # time in seconds since midnight, January 1, 1970 UTC; Winnipeg = UTC - 5h (6h in winter time)
    arrival_time = round(Int, Dates.value(arrival_dt + Dates.Hour(5) - DateTime(1970,1,1,0,0,0))/1000)
    
    pointA_str = changeCoordToString(pointA)
    pointB_str = changeCoordToString(pointB)
    
    waypoints = additional_activity
    
    if length(waypoints.before) == 0 && length(waypoints.after) == 0
        url = "https://maps.googleapis.com/maps/api/directions/json?origin="*pointA_str*
                  "&destination="*pointB_str*"&arrival_time="*string(arrival_time)*"&key="*apikey
    
    # before and after waypoints - route: pointA -> before -> pointB -> after -> pointA 
    elseif length(waypoints.before) > 0 && length(waypoints.after) > 0
        before_str = changeCoordToString(waypoints.point_before)
        after_str  = changeCoordToString(waypoints.point_after)
        waypoints  = before_str*"|"*pointB_str*"|"*after_str
        url = "https://maps.googleapis.com/maps/api/directions/json?origin="*pointA_str*
               "&destination="*pointA_str*"&waypoints="*waypoints*"&arrival_time="*
               string(arrival_time)*"&key="*apikey
        
    # only before waypoint - route: pointA -> before -> pointB -> pointA 
    elseif length(waypoints.before) > 0 && length(waypoints.after) == 0
        before_str = changeCoordToString(waypoints.point_before)
        waypoints  = before_str*"|"*pointB_str
        url = "https://maps.googleapis.com/maps/api/directions/json?origin="*pointA_str*
               "&destination="*pointA_str*"&waypoints="*waypoints*"&arrival_time="*
               string(arrival_time)*"&key="*apikey
         
    # only after waypoint - route: pointA - pointB - after - pointA     
    elseif length(waypoints.before) == 0 && length(waypoints.after) > 0
        after_str = changeCoordToString(waypoints.point_after)
        waypoints  = pointB_str*"|"*after_str
        url = "https://maps.googleapis.com/maps/api/directions/json?origin="*pointA_str*
               "&destination="*pointA_str*"&waypoints="*waypoints*"&arrival_time="*
               string(arrival_time)*"&key="*apikey 
    end 

    res = HTTP.request("GET", url; verbose = 0); println(res.status)
    res_json = JSON.parse(join(readlines(IOBuffer(res.body))," "))
    
    response  = res_json["routes"][1]["legs"]
    route     = [0]
    time      = 0 # in seconds 
    distance  = 0 # in metres

    osm_distance, osm_time = 0, 0 # calculated by osm routing

    # iterate through points/waypoints
    for k in 1:size(response, 1)
        distance += response[k]["distance"]["value"]
        time     += response[k]["duration"]["value"]

        # iterate through nodes between 2 points/waypoints
        for i in 1:size(response[k]["steps"], 1)
            start_lat = response[k]["steps"][i]["start_location"]["lat"]
            start_lon = response[k]["steps"][i]["start_location"]["lng"]
            end_lat   = response[k]["steps"][i]["end_location"]["lat"]
            end_lon   = response[k]["steps"][i]["end_location"]["lng"]    

            start_osmnode = nearestNode(nodes, ENU(LLA(start_lat, start_lon), center(mapD.bounds)), network)
            end_osmnode   = nearestNode(nodes, ENU(LLA(end_lat, end_lon), center(mapD.bounds)), network)

            if start_osmnode != end_osmnode
                r = routingMode(network, start_osmnode, end_osmnode)
                route[end] != r[1][1] ? append!(route, r[1]) : append!(route, r[1][2:end])
                osm_distance += r[2]
                osm_time += r[3] 
            end

        end
    end

    route = route[2:end]
    
    println("osm_dist: ", osm_distance, "\nosm_routeTime: ", osm_time)
    println("google_dist: ", distance,     "\ngoogle_time: ", time)
    
    return RouteData(route, distance, time)
end



###################################
# Route Module Selector

"""
Selects routing mode from the following options: fastest route, shortest route, googlemaps route and returns a function
    
**Arguments**
* `agent_profile` : agent_profile along with age
* `DA_home` : DA_home unique id selected for an agent
* `DA_work` : DA_work unique id selected for an agent
* `dict_df_DAcentroids` : dictionary of dataframes with :LATITUDE and :LONGITUDE for each DA
"""
function route_module_selector(agent_profile, DA_home, DA_work, dict_df_DAcentroids)
    
    dist =  distance(dict_df_DAcentroids[DA_home][1, :ENU], dict_df_DAcentroids[DA_work][1, :ENU])
    
    if dist < 4000
        rand() < 0.6 ? mode = shortestRoute :  mode = fastestRoute
        
    elseif dist < 12000
        rand() < 0.6 ? mode = fastestRoute :  mode = shortestRoute
        
    else
        mode = sample([fastestRoute, googlemapsroute], fweights([agent_profile.age, 100 - agent_profile.age]))
        
    end
    
    return mode
end


