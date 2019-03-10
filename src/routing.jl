##############################
### Get Edges of the Graph ###
##############################

function get_edges(nodes::Dict{Int,T},roadways::Vector{OpenStreetMapX.Way}) where T<:Union{OpenStreetMapX.ENU,OpenStreetMapX.ECEF}
    oneway_roads = map(OpenStreetMapX.oneway,roadways)
    reverse_roads = map(OpenStreetMapX.reverseway,roadways)
	classes = OpenStreetMapX.classify_roadways(roadways)
    edges = Dict{Tuple{Int,Int},Int}()
    for i = 1:length(roadways)
        for j = 2:length(roadways[i].nodes)
            n0 = roadways[i].nodes[j-1]
            n1 = roadways[i].nodes[j]
            start = n0 * !reverse_roads[i] + n1 * reverse_roads[i]
            fin = n0 * reverse_roads[i] + n1 * !reverse_roads[i]
			edges[(start,fin)] = classes[roadways[i].id]
            oneway_roads[i] || (edges[(fin,start)] = classes[roadways[i].id])
        end
    end
	return collect(keys(edges)), collect(values(edges))
end

#################################
### Get Vertices of the Graph ###
#################################

function get_vertices(edges::Array{Tuple{Int64,Int64},1})
    graph_nodes = unique(reinterpret(Int, edges))
    vertices = Dict{Int,Int}(zip(graph_nodes, 1:length(graph_nodes)))
end

###################################
### Get Distances Between Edges ###
###################################

function distance(nodes::Dict{Int,T},edges::Array{Tuple{Int64,Int64},1}) where T<:Union{OpenStreetMapX.ENU,OpenStreetMapX.ECEF}
    distances = Float64[]
    for edge in edges
        dist = OpenStreetMapX.distance(nodes[edge[2]],nodes[edge[1]])
        push!(distances,dist)
    end
    return distances
end

####################################################
###	For Each Feature Find the Nearest Graph Node ###
####################################################

function features_to_graph(m::OpenStreetMapX.MapData, features::Dict{Int,Tuple{String,String}}) where T<:(Union{OpenStreetMapX.ENU,OpenStreetMapX.ECEF})
    features_to_nodes = Dict{Int,Int}()
    sizehint!(features_to_nodes,length(features))
    for (key,value) in features
        if !haskey(m.v,key)
            features_to_nodes[key] = OpenStreetMapX.nearest_node(m,features[key])
        else
            features_to_nodes[key] = key
        end
    end
    return features_to_nodes
end




#########################################
### Find Routes - Auxiliary Functions ###
#########################################

### Dijkstra's Algorithm ###
function dijkstra(m::OpenStreetMapX.MapData, w::SparseArrays.SparseMatrixCSC{Float64,Int64}, start_vertex::Int)
    return LightGraphs.dijkstra_shortest_paths(m.g, start_vertex, w)
end

### Transpose distances to times ###

function network_travel_times(m::OpenStreetMapX.MapData, class_speeds::Dict{Int,Float64} = OpenStreetMapX.SPEED_ROADS_URBAN)
    @assert length(m.e) == length(m.w.nzval)
    indices = [(m.v[i],m.v[j]) for (i,j) in m.e]
    w = Array{Float64}(undef,length(m.e))
    for i = 1:length(w)
        w[i] = 3.6 * (m.w[indices[i]]/class_speeds[m.class[i]])
    end
    return w
end

### Create a Sparse Matrix for a given vector of weights ###

function create_weights_matrix(m::OpenStreetMapX.MapData,weights::Vector{Float64})
    w = Dict{Tuple{Int,Int},Float64}()
    sizehint!(w,length(weights))
    for (i,edge) in enumerate(m.e)
        w[m.v[edge[1]],m.v[edge[2]]] = weights[i]
    end
    return SparseArrays.sparse(map(x->getfield.(collect(keys(w)), x),
        fieldnames(eltype(collect(keys(w)))))..., 
        collect(values(w)),length(m.v),length(m.v))
end

### Get velocities matrix ###

function get_velocities(m::OpenStreetMapX.MapData, 
            class_speeds::Dict{Int,Float64} = OpenStreetMapX.SPEED_ROADS_URBAN)
    @assert length(m.e) == length(m.w.nzval)
    indices = [(m.v[i],m.v[j]) for (i,j) in m.e]
    V = Array{Float64}(undef,length(m.e))
    for i = 1:length(indices)
        V[i] = class_speeds[m.class[i]]/3.6
    end
    return SparseArrays.sparse(map(i -> m.v[i[1]], m.e), map(i -> m.v[i[2]], m.e),V)
end

### Extract route from Dijkstra results object ###

function extract_route(dijkstra::LightGraphs.DijkstraState{Float64,Int64}, startIndex::Int, finishIndex::Int)
    route = Int[]
    distance = dijkstra.dists[finishIndex]
    if distance != Inf
        index = finishIndex
        push!(route, index)
        while index != startIndex
            index = dijkstra.parents[index]
            push!(route, index)
        end
    end
    reverse!(route)
    return route, distance
end

### Extract nodes ID's from route object ###

function get_route_nodes(m::OpenStreetMapX.MapData, route_indices::Array{Int64,1})
    route_nodes = Array{Int}(undef,length(route_indices))
    v = Dict{Int,Int}(reverse.(collect(m.v)))
    for n = 1:length(route_nodes)
        route_nodes[n] = v[route_indices[n]]
    end
    return route_nodes
end

### Generate an ordered list of edges traversed in route ###

function route_edges(m::OpenStreetMapX.MapData, route_nodes::Vector{Int})
	e = Array{Int}(undef,length(route_nodes)-1)
	for i = 2:length(route_nodes)
		e[i-1] = findfirst(isequal((route_nodes[i-1], route_nodes[i])), m.e)
	end
	return e
end

### Calculate distance with a given weights ###

calculate_distance(m::OpenStreetMapX.MapData, weights::SparseArrays.SparseMatrixCSC{Float64,Int64}, route_indices::Array{Int64,1}) = sum(weights[(route_indices[i-1], route_indices[i])] for i = 2:length(route_indices))


#####################################
### Find Route with Given Weights ###
#####################################

function find_route(m::OpenStreetMapX.MapData, node0::Int, node1::Int, 
                    weights::SparseArrays.SparseMatrixCSC{Float64,Int64};
                    routing::Symbol = :astar, heuristic::Function = n -> zero(Float64),
                    get_distance::Bool = false, get_time::Bool = false)
    result = Any[]
	start_vertex = m.v[node0]
	finish_vertex= m.v[node1]
    if routing == :dijkstra
        dijkstra_result = OpenStreetMapX.dijkstra(m, weights, start_vertex)
        route_indices, route_values = OpenStreetMapX.extract_route(dijkstra_result, start_vertex, finish_vertex)
        route_nodes = OpenStreetMapX.get_route_nodes(m, route_indices)
        push!(result, route_nodes, route_values)
    elseif routing == :astar
        route_indices, route_values = OpenStreetMapX.a_star_algorithm(m.g, start_vertex, finish_vertex, weights, heuristic)
        route_nodes = OpenStreetMapX.get_route_nodes(m, route_indices)
        push!(result, route_nodes, route_values)
    else
        @warn "routing module declared wrongly - a star algorithm will be used instead!"
        route_indices, route_values = OpenStreetMapX.a_star_algorithm(m.g, start_vertex, finish_vertex, weights, heuristic)
        route_nodes = OpenStreetMapX.get_route_nodes(m, route_indices)
        push!(result, route_nodes, route_values)
    end
    if get_distance
        if isempty(route_indices)
            distance = Inf
        elseif length(route_indices) == 1
            distance = 0
        else
            distance = OpenStreetMapX.calculate_distance(m, m.w, route_indices)
        end
        push!(result, distance)
    end
    if get_time
        w = OpenStreetMapX.create_weights_matrix(m,network_travel_times(m))
        if isempty(route_indices)
            route_time = Inf
        elseif length(route_indices) == 1
            route_time = 0
        else
            route_time = OpenStreetMapX.calculate_distance(m, w, route_indices)
        end
        push!(result, route_time)
    end
    return result
end


#########################################################
### Find Route Connecting 3 Points with Given Weights ###
#########################################################

function find_route(m::OpenStreetMapX.MapData, node0::Int, node1::Int, node2::Int, 
                    weights::SparseArrays.SparseMatrixCSC{Float64,Int64};
                    routing::Symbol = :astar, heuristic::Function = n -> zero(Float64), 
                    get_distance::Bool = false, get_time::Bool = false)
    result = Any[]
    route1 = OpenStreetMapX.find_route(m, node0, node1, weights,
                                        routing = routing, heuristic = heuristic,
                                        get_distance = get_distance, get_time = get_time)
    route2 = OpenStreetMapX.find_route(m, node1, node2, weights,
                                        routing = routing, heuristic = heuristic,
                                        get_distance = get_distance, get_time = get_time)
    push!(result,vcat(route1[1],route2[1]))
    for i = 2:length(route1)
        push!(result,route1[i] + route2[i])
    end
    return result
end

###########################
###  ###
###########################
"""
    shortest_route(m::MapData, node1::Int, node2::Int; routing::Symbol = :astar)

Find Shortest route between `node1` and `node2` on map `m`.

"""
function shortest_route(m::MapData, node1::Int, node2::Int; routing::Symbol = :astar)
    route_nodes, distance, route_time = OpenStreetMapX.find_route(m,node1,node2,m.w,
                                                                routing = routing, heuristic = (u,v) -> OpenStreetMapX.get_distance(u, v, m.nodes, m.n), 
                                                                get_distance =false, get_time = true)
    return route_nodes, distance, route_time
end
"""
    shortest_route(m::MapData, node1::Int, node2::Int, node3::Int; routing::Symbol = :astar)

Find Shortest route between `node1` and `node2` and `node3` on map `m`.

"""
function shortest_route(m::MapData, node1::Int, node2::Int, node3::Int; routing::Symbol = :astar)
    route_nodes, distance, route_time = OpenStreetMapX.find_route(m,node1,node2, node3, m.w,
                                                                routing = routing, heuristic = (u,v) -> OpenStreetMapX.get_distance(u, v, m.nodes, m.n), 
                                                                get_distance =false, get_time = true)
    return route_nodes, distance, route_time
end

"""
    ffastest_route(m::MapData, node1::Int, node2::Int;
                        routing::Symbol = :astar, 
                        speeds::Dict{Int,Float64}=SPEED_ROADS_URBAN)

Find fastest route between `node1` and `node2`  on map `m` with assuming `speeds` for road classes.

"""
function fastest_route(m::MapData, node1::Int, node2::Int;
                        routing::Symbol = :astar,
                        speeds::Dict{Int,Float64}=SPEED_ROADS_URBAN)
    w = OpenStreetMapX.create_weights_matrix(m,network_travel_times(m, speeds))
    route_nodes, route_time, distance = OpenStreetMapX.find_route(m, node1, node2, w,
                                                                routing = routing, 
																heuristic = (u,v) -> OpenStreetMapX.get_distance(u, v, m.nodes, m.n) / maximum(values(speeds)), 
                                                                get_distance = true, get_time = false)
    return route_nodes, distance, route_time
end

"""
    fastest_route(m::MapData, node1::Int, node2::Int, node3::Int;
                        routing::Symbol = :astar, 
                        speeds::Dict{Int,Float64}=SPEED_ROADS_URBAN)

Find fastest route between `node1` and `node2` and `node3`  on map `m` with assuming `speeds` for road classes.

"""
function fastest_route(m::MapData, node1::Int, node2::Int, node3::Int;
                        routing::Symbol = :astar, 
                        speeds::Dict{Int,Float64}=SPEED_ROADS_URBAN)
    w = OpenStreetMapX.create_weights_matrix(m,network_travel_times(m, speeds))
    route_nodes, route_time, distance = OpenStreetMapX.find_route(m, node1, node2, node3, w,
                                                                routing = routing, heuristic = (u,v) -> OpenStreetMapX.get_distance(u, v, m.nodes, m.n) / maximum(values(speeds)), 
                                                                get_distance = true, get_time = false)
    return route_nodes, distance, route_time
end

###########################################
### Find  waypoint minimizing the route ###
###########################################

### Approximate solution ###

function find_optimal_waypoint_approx(m::OpenStreetMapX.MapData, weights::SparseArrays.SparseMatrixCSC{Float64,Int64}, node0::Int, node1::Int, waypoints::Dict{Int,Int})
    dists_start_waypoint = LightGraphs.dijkstra_shortest_paths(m.g, m.v[node0], weights).dists
    dists_waypoint_fin = LightGraphs.dijkstra_shortest_paths(m.g, m.v[node1], weights).dists
    node_id = NaN
    min_dist = Inf
    for (key,value) in waypoints
        dist  = dists_start_waypoint[m.v[value]] + dists_waypoint_fin[m.v[value]]
        if dist < min_dist
            min_dist = dist
            node_id = value
        end
    end
    return node_id
end

### Exact solution ###

function find_optimal_waypoint_exact(m::OpenStreetMapX.MapData, weights::SparseArrays.SparseMatrixCSC{Float64,Int64}, node0::Int, node1::Int, waypoints::Dict{Int,Int})
    dists_start_waypoint = LightGraphs.dijkstra_shortest_paths(m.g, m.v[node0], weights).dists
    node_id = NaN
    min_dist = Inf
    for (key,value) in waypoints
        dist_to_fin = LightGraphs.dijkstra_shortest_paths(m.g, m.v[value], weights).dists[m.v[node1]]
        dist  = dists_start_waypoint[m.v[value]] + dist_to_fin
        if dist < min_dist
            min_dist = dist
            node_id = value
        end
    end
    return node_id
end

########################################################################
### Find Nodes Within Driving Time or Distance - Auxiliary Functions ###
########################################################################

### Bellman Ford's Algorithm ###
function bellman_ford(m::OpenStreetMapX.MapData, w::SparseArrays.SparseMatrixCSC{Float64,Int64}, start_vertices::Vector{Int})
    return LightGraphs.bellman_ford_shortest_paths(m.g, start_vertices, w)
end

### Filter vertices from bellman_fordStates object ###

function filter_vertices(vertices::Dict{Int,Int}, weights::Vector{Float64}, limit::Float64)
    if limit == Inf
        @assert length(vertices) == length(weights)
        return keys(vertices), weights
    end
    indices = Int[]
    distances = Float64[]
    for vertex in keys(vertices)
        distance = weights[vertices[vertex]]
        if distance < limit
            push!(indices, vertex)
            push!(distances, distance)
        end
    end
    return indices, distances
end

##############################################################################
### Extract Nodes from bellman_fordStates Object Within an (Optional) Limit ###
### Based on Weights													   ###
##############################################################################

function nodes_within_weights(m::OpenStreetMapX.MapData, weights::SparseArrays.SparseMatrixCSC{Float64,Int64}, start_indices::Vector{Int}, limit::Float64=Inf)
	start_vertices = [m.v[i] for i in start_indices]
    bellman_ford = OpenStreetMapX.bellman_ford(m, weights, start_vertices)
    return OpenStreetMapX.filter_vertices(m.v, bellman_ford.dists, limit)
end

nodes_within_weights(nodes::Dict{Int,T}, m::OpenStreetMapX.MapData, weights::SparseArrays.SparseMatrixCSC{Float64,Int64}, loc::T, limit::Float64=Inf,locrange::Float64=500.0) where T<:(Union{OpenStreetMapX.ENU,OpenStreetMapX.ECEF}) = OpenStreetMapX.nodes_within_weights(m, weights, nodes_within_range(nodes, loc, network, locrange), limit)

##############################################################################
### Extract Nodes from bellman_fordStates Object Within an (Optional) Limit ###
### Based on Driving Distance											   ###
##############################################################################

function nodes_within_driving_distance(m::OpenStreetMapX.MapData, start_indices::Vector{Int}, limit::Float64=Inf)
    start_vertices = [m.v[i] for i in start_indices]
    bellman_ford = OpenStreetMapX.bellman_ford(m, m.w, start_vertices)
    return OpenStreetMapX.filter_vertices(m.v, bellman_ford.dists, limit)
end

nodes_within_driving_distance(nodes::Dict{Int,T}, m::OpenStreetMapX.MapData, loc::T, limit::Float64=Inf,locrange::Float64=500.0) where T<:(Union{OpenStreetMapX.ENU,OpenStreetMapX.ECEF})= OpenStreetMapX.nodes_within_driving_distance(m, nodes_within_range(nodes, loc ,network, locrange), limit)

##############################################################################
### Extract Nodes from bellman_fordStates Object Within an (Optional) Limit ###
### Based on Driving Time												   ###
##############################################################################

function nodes_within_driving_time(m::OpenStreetMapX.MapData, start_indices::Vector{Int}, limit::Float64=Inf, speeds::Dict{Int,Float64}=SPEED_ROADS_URBAN)
	w = OpenStreetMapX.create_weights_matrix(m,network_travel_times(m, speeds))
	start_vertices = [m.v[i] for i in start_indices]
    bellman_ford = OpenStreetMapX.bellman_ford(m, w, start_vertices)
    return OpenStreetMapX.filter_vertices(m.v, bellman_ford.dists, limit)
end

function nodes_within_driving_time(nodes::Dict{Int,T}, m::OpenStreetMapX.MapData, loc::T, limit::Float64=Inf, locrange::Float64=500.0, speeds::Dict{Int,Float64}=SPEED_ROADS_URBAN) where T<:(Union{OpenStreetMapX.ENU,OpenStreetMapX.ECEF})
	w = OpenStreetMapX.create_weights_matrix(m,network_travel_times(m, speeds))
	return OpenStreetMapX.nodes_within_driving_time(m,nodes_within_range(nodes, loc, m,locrange),limit,speeds)
end

"""
    generate_point_in_bounds(m::MapData)

Generates a random pair of Latitude-Longitude coordinates within
boundaries of map `m`
"""
function generate_point_in_bounds(m::MapData)
    boundaries = m.bounds
    (rand() * (boundaries.max_y -  boundaries.min_y) + boundaries.min_y,
    rand() * (boundaries.max_x -  boundaries.min_x) + boundaries.min_x)
end

"""
    point_to_nodes(point::Tuple{Float64,Float64}, m::MapData)

Converts a pair Latitude-Longitude of coordinates 
`point` to a node on a map `m`
The result is a node indentifier.

"""
function point_to_nodes(point::Tuple{Float64,Float64}, m::MapData)
    pointLLA = LLA(point[1],point[2])
    point_to_nodes(pointLLA, m)
end
"""
    point_to_nodes(point::LLA, m::MapData)

Converts a pair of coordinates LLA (Latitude-Longitude-Altitude) `point` to a node on a map `m`
The result is a node indentifier.

"""
function point_to_nodes(point::LLA, m::MapData)
    nearest_node(m,OpenStreetMapX.ENU(point, m.bounds))
end
