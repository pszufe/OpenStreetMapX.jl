pth = "osm/";
path = "sim/";
datapath = "../../datasets/";

include(pth*"OpenStreetMap.jl")
include(path*"OSMSim.jl")

using OSMSim

mutable struct RouteData
    shortest_route
    fastest_route
    google_route
    p
end

 const files = Dict{Symbol,Union{String,Array{String,1}}}(:osm => "map.osm", #smaller map
:features => [ "df_popstores.csv",
  "df_schools.csv",
  "df_recreationComplex.csv",
  "df_shopping.csv",],
:flows =>"df_hwflows.csv",
:DAs => "df_DA_centroids.csv",
:demo_stats => "df_demostat.csv",
:business_stats => "df_business.csv",
:googleapi_key => "googleapi.key"
)
 
 
function find_routes(sim_data::OSMSim.SimData,
                    google = false,plotting = true, p = :none)::RouteData
    loc = OSMSim.start_location(sim_data.demographic_data)
    agent = OSMSim.demographic_profile(loc, sim_data.demographic_data[loc])
    OSMSim.destination_location!(agent,sim_data.business_data)
    activity = OSMSim.additional_activity(agent,false)
    start_node = sim_data.DAs_to_intersection[agent.DA_home]
    fin_node = sim_data.DAs_to_intersection[agent.DA_work]
    shortest_route,fastest_route,google_route = nothing,nothing,nothing
    if isa(activity,Void)
        if google
            google_route, mode = OSMSim.get_google_route(start_node,fin_node,sim_data)
        end
        shortest_route, shortest_distance, shortest_time = OpenStreetMap.shortestRoute(sim_data.network, start_node,fin_node)
        fastest_route, fastest_distance, fastest_time = OpenStreetMap.fastestRoute(sim_data.network, start_node,fin_node)
    else
        waypoint = OSMSim.get_waypoint(start_node,fin_node,activity,sim_data,false)
        if google
            google_route, mode = OSMSim.get_google_route(start_node,fin_node,waypoint,sim_data)
        end
        shortest_route, shortest_distance, shortest_time = OpenStreetMap.shortestRoute(sim_data.network, start_node, waypoint,fin_node)
        fastest_route, fastest_distance, fastest_time = OpenStreetMap.fastestRoute(sim_data.network, start_node, waypoint,fin_node)
    end
    if plotting
        if p == :none
            p = OpenStreetMap.plotMap(sim_data.nodes, OpenStreetMap.ENU(sim_data.bounds), roadways=sim_data.roadways)
        end
        p = OpenStreetMap.addRoute!(p,sim_data.nodes,fastest_route, routeColor = "0x000000")
        p = OpenStreetMap.addRoute!(p,sim_data.nodes,shortest_route,  routeColor = "0xFF0000")
        if google
            p = OpenStreetMap.addRoute!(p,sim_data.nodes,google_route,  routeColor = "0xCC00CC")
        end
    end
    return RouteData(shortest_route,
    fastest_route,
    google_route,
    p)    
        
end

########################################################################
sim_data = get_sim_data(datapath, filenames = files, google = true);

r = :none
r = find_routes(sim_data, true,true,r==:none?(:none):(r.p))

display(r.p)

