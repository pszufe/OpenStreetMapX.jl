#############################
### Google routing module ###
#############################

"""
Dictionary for Google Distances API requests:

**Keys**
* `:url` : url for google API, only JSON files outputs are accepted
* `:mode` : transportation mode used in simulation, in the current library scope only driving is accepted
* `:avoid` : map features to avoid (to mantain compatibility with OSM routes ferries should be avoided)
* `:units` : unit system for displaing distances (changing to *imperial* needs deeper changes in both OSMsim and OpenStreetMapX modules)

"""
const googleAPI_parameters = Dict{Symbol,String}(
:url => "https://maps.googleapis.com/maps/api/directions/json?",
:mode  => "driving",
:avoid => "ferries",
:units => "metric",
)


"""
    node_to_string(node_id::Int,map_data::MapData)

Convert node coordinates (stored in ENU system in the `nodes` field of `map_data`)
identified by `node_id` to string with LLA system coordinates

"""
function node_to_string(node_id::Int,map_data::MapData)
    coords = LLA(map_data.nodes[node_id],map_data.bounds)
    return string(coords.lat,",",coords.lon)
end

"""
Gets Google Distances API request url with three points (origin, destination, waypoint between)

**Arguments**
* `origin` : unique node id
* `destination` : unique node id
* `waypoint` : unique node id
* `map_data` : `OpenStreetMapX.MapData` object
* `googleapi_key`: Goole API key
* `googleapi_parameters` : dictionary with assumptions about Google Distances API request

"""
function get_googleapi_url(origin::Int,destination::Int, waypoint::Int,
                            map_data::OpenStreetMapX.MapData, googleapi_key::String;
                            googleapi_parameters::Dict{Symbol,String} = OpenStreetMapX.googleAPI_parameters)
    origin = OpenStreetMapX.node_to_string(origin, map_data)
    destination = OpenStreetMapX.node_to_string(destination, map_data)
    waypoint = OpenStreetMapX.node_to_string(waypoint, map_data)
    return googleapi_parameters[:url]*"origin="*origin*"&destination="*destination*"&waypoints="*waypoint*
    "&avoid="*googleapi_parameters[:avoid]*"&units="*googleapi_parameters[:units]*
    "&mode="*googleapi_parameters[:mode]*"&key="*googleapi_key
end

"""
Gets Google Distances API request url with two points (origin and destination)

**Arguments**
* `origin` : unique node id
* `destination` : unique node id
* `map_data` : `OpenStreetMapX.MapData;` object
* `googleapi_key`: Google API key
* `googleapi_parameters` : dictionary with assumptions about Google Distances API request

"""
function get_googleapi_url(origin::Int,destination::Int,
                            map_data::OpenStreetMapX.MapData, googleapi_key::String;
                            googleapi_parameters::Dict{Symbol,String} = OpenStreetMapX.googleAPI_parameters)
    origin = OpenStreetMapX.node_to_string(origin, map_data)
    destination = OpenStreetMapX.node_to_string(destination, map_data)
    return googleapi_parameters[:url]*"origin="*origin*"&destination="*destination*
    "&avoid="*googleapi_parameters[:avoid]*"&units="*googleapi_parameters[:units]*
    "&mode="*googleapi_parameters[:mode]*"&key="*googleapi_key
end

"""
Get JSON file from Google Distances API request and extract results

**Arguments**
* `url` : string with proper url

"""
function parse_google_url(url::String)
    status, routes = nothing, nothing
    res_json = JSON.parse(String(HTTP.get(url).body))
    status, routes = res_json["status"], res_json["routes"]
    return status, routes
end

"""
Extract route from Google API results

**Arguments**
* `routes` : dictionary with informations about the route

"""
function extract_google_route(routes::Dict)
    res = Array{Tuple{Float64,Float64},1}[]
    legs = routes["legs"]
    for leg in legs
        steps = leg["steps"]
        for step in steps
            push!(res,OpenStreetMapX.decode(step["polyline"]["points"]))
        end
    end
    return vcat(res...)
end

"""
Match Google route with vertices of map network

**Arguments**
* `route` : array with LLA coordinates of crucial route points
* `map_data` : `OpenStreetMapX.MapData;` object


"""
function google_route_to_network(route::Array{Tuple{Float64,Float64},1},map_data::MapData)
    route = [ENU(LLA(coords[1], coords[2]),map_data.bounds) for coords in route]
    res = [nearest_node(map_data, route[1])]
    index = 2
    for i = 2:length(route)
        node = OpenStreetMapX.nearest_node(map_data, route[i])
        if node != res[index-1]
            push!(res,node)
            index += 1
        end
    end
    return res
end

"""
    get_google_route(origin::Int, destination::Int, waypoint::Int,
                     map_data:MapData, googleapi_key::String;
                     googleapi_parameters::Dict{Symbol,String} = googleAPI_parameters)

Get route from to based on Google Distances API with three points
(`origin`, `destination` and `waypoint` between)
on map `map_data` using Google API key `googleapi_key` with optional
Google Distances API request parameters `googleapi_parameters`.

"""
function get_google_route(origin::Int,destination::Int,waypoint::Int,
                            map_data::OpenStreetMapX.OpenStreetMapX.MapData, googleapi_key::String;
                            googleapi_parameters::Dict{Symbol,String} = googleAPI_parameters)
    url = OpenStreetMapX.get_googleapi_url(origin, destination, waypoint,map_data,googleapi_key,googleapi_parameters = googleapi_parameters)
    status, routes = OpenStreetMapX.parse_google_url(url)
    if status == "OK"
        route = OpenStreetMapX.extract_google_route(routes[1])
        return OpenStreetMapX.google_route_to_network(route,map_data), "google"
    elseif status =="ZERO_RESULTS"
        return Int[], "google"
    elseif status == "OVER_QUERY_LIMIT"
        sleep(0.5)
        return OpenStreetMapX.get_google_route(origin,destination,waypoint,map_data,googleapi_key,googleapi_parameters = googleapi_parameters)
    else
        #get route based on OSM routing
        @warn "Google Distances API cannot get a proper results - route will be calculated with OSMSim Routing module"
		if rand() < 0.5
			route_nodes, distance, route_time = OpenStreetMapX.shortest_route(map_data, origin, waypoint, destination)
			return route_nodes, "shortest"
		else
			route_nodes, distance, route_time = OpenStreetMapX.fastest_route(map_data, origin, waypoint, destination)
			return route_nodes, "fastest"
		end
    end
end

"""
    get_google_route(origin::Int, destination::Int,
                     map_data:MapData, googleapi_key::String;
                     googleapi_parameters::Dict{Symbol,String} = googleAPI_parameters)

Get route from to based on Google Distances API with two points (`origin` and `destination`)
on map `map_data` using Google API key `googleapi_key` with optional
Google Distances API request parameters `googleapi_parameters`.

"""
function get_google_route(origin::Int,destination::Int,
                            map_data::MapData,googleapi_key::String;
                            googleapi_parameters::Dict{Symbol,String} = googleAPI_parameters)
    url = OpenStreetMapX.get_googleapi_url(origin, destination,map_data,googleapi_key,googleapi_parameters = googleapi_parameters)
    status, routes = OpenStreetMapX.parse_google_url(url)
    if status == "OK"
        route = OpenStreetMapX.extract_google_route(routes[1])
        return OpenStreetMapX.google_route_to_network(route,map_data), "google"
    elseif status =="ZERO_RESULTS"
        return Int[],"google"
    elseif status == "OVER_QUERY_LIMIT"
        sleep(0.5)
        return OpenStreetMapX.get_google_route(origin,destination,map_data,googleapi_key,googleapi_parameters = googleapi_parameters)
    else
        #get route based on OSM routing
        @warn "Google Distances API cannot get a proper results - route will be calculated with OSMSim Routing module"
		if rand() < 0.5
			route_nodes, distance, route_time = OpenStreetMapX.shortest_route(map_data, origin, destination)
			return route_nodes, "shortest"
		else
			route_nodes, distance, route_time = OpenStreetMapX.fastest_route(map_data, origin, destination)
			return route_nodes, "fastest"
		end
    end
end
