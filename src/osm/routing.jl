##############################
### Get Edges of the Graph ###
##############################

function get_edges(nodes::Dict{Int,T},roadways::Vector{OpenStreetMap2.Way}) where T<:Union{OpenStreetMap2.ENU,OpenStreetMap2.ECEF}
    oneway_roads = map(OpenStreetMap2.oneway,roadways)
    reverse_roads = map(OpenStreetMap2.reverseway,roadways)
	classes = OpenStreetMap2.classify_roadways(roadways)
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

function distance(nodes::Dict{Int,T},edges::Array{Tuple{Int64,Int64},1}) where T<:Union{OpenStreetMap2.ENU,OpenStreetMap2.ECEF}
    distances = Float64[]
    for edge in edges
        dist = OpenStreetMap2.distance(nodes[edge[2]],nodes[edge[1]])
        push!(distances,dist)
    end
    return distances
end

####################################################
###	For Each Feature Find the Nearest Graph Node ###
####################################################

function features_to_graph(nodes::Dict{Int,T}, features::Dict{Int,Tuple{String,String}}, network::OpenStreetMap2.Network) where T<:(Union{OpenStreetMap2.ENU,OpenStreetMap2.ECEF})
    features_to_nodes = Dict{Int,Int}()
    sizehint!(features_to_nodes,length(features))
    for (key,value) in features
        if !haskey(network.v,key)
            features_to_nodes[key] = OpenStreetMap2.nearest_node(nodes,nodes[key],network)
        else
            features_to_nodes[key] = key
        end
    end
    return features_to_nodes 
end

############################
### Create Network Graph ###
############################

### Create Network with all nodes ###

function create_graph(nodes::Dict{Int,T},roadways::Vector{OpenStreetMap2.Way}) where T<:Union{OpenStreetMap2.ENU,OpenStreetMap2.ECEF}
    e,class = OpenStreetMap2.get_edges(nodes,roadways)
    v = OpenStreetMap2.get_vertices(e)
    weights = OpenStreetMap2.distance(nodes,e)
    edges = [v[id] for id in reinterpret(Int, e)]
    I = edges[1:2:end] 
    J = edges[2:2:end] 
    w = SparseArrays.sparse(I, J, weights, length(v), length(v))
    OpenStreetMap2.Network(LightGraphs.DiGraph(w),v,e,w,class)
end

### Create Network with Roads intersections only### 

function create_graph(segments::Vector{Segment}, intersections::Dict{Int,Set{Int}},classified_roadways::Dict{Int,Int})
    vals = Dict((segment.node0,segment.node1) => (segment.distance,segment.parent) for segment in segments)
	e = collect(keys(vals))
	vals = collect(values(vals))
	weights = map(val -> val[1],vals)
	class =  [classified_roadways[id] for id in map(val -> val[2],vals)]
	v = OpenStreetMap2.get_vertices(e)
    edges = [v[id] for id in reinterpret(Int, e)]
    I = edges[1:2:end] 
    J = edges[2:2:end] 
    w = SparseArrays.sparse(I, J, weights, length(v), length(v))
    OpenStreetMap2.Network(LightGraphs.DiGraph(w),v,e,w,class)
end

#########################################
### Find Routes - Auxiliary Functions ###
#########################################

### Dijkstra's Algorithm ###
function dijkstra(network::OpenStreetMap2.Network, w::SparseArrays.SparseMatrixCSC{Float64,Int64}, start_vertex::Int)
    return LightGraphs.dijkstra_shortest_paths(network.g, start_vertex, w)
end

### Transpose distances to times ###

function network_travel_times(network::OpenStreetMap2.Network, class_speeds::Dict{Int,Int} = OpenStreetMap2.SPEED_ROADS_URBAN)
    @assert length(network.e) == length(network.w.nzval)
    indices = [(network.v[i],network.v[j]) for (i,j) in network.e]
    w = Array{Float64}(undef,length(network.e))
    for i = 1:length(w)
        w[i] = 3.6 * (network.w[indices[i]]/class_speeds[network.class[i]])
    end
    return w
end

### Create a Sparse Matrix for a given vector of weights ###

function create_weights_matrix(network::OpenStreetMap2.Network,weights::Vector{Float64})
    return SparseArrays.sparse(map(i -> network.v[i[1]], network.e), map(i -> network.v[i[2]], network.e),weights)
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

function get_route_nodes(network::OpenStreetMap2.Network, route_indices::Array{Int64,1})
    route_nodes = Array{Int}(undef,length(route_indices))
    v = Dict{Int,Int}(reverse(p) for p = pairs(network.v))
    for n = 1:length(route_nodes)
        route_nodes[n] = v[route_indices[n]]
    end
    return route_nodes
end

### Generate an ordered list of edges traversed in route ###

function route_edges(network::OpenStreetMap2.Network, route_nodes::Vector{Int})
	e = Array{Int}(undef,length(route_nodes)-1)
	for i = 2:length(route_nodes)
		e[i-1] = findfirst(isequal((route_nodes[i-1], route_nodes[i])), network.e)
	end
	return e
end

### Calculate distance with a given weights ###

calculate_distance(network::OpenStreetMap2.Network, weights::SparseArrays.SparseMatrixCSC{Float64,Int64}, route_indices::Array{Int64,1}) = sum(weights[(route_indices[i-1], route_indices[i])] for i = 2:length(route_indices))


#####################################
### Find Route with Given Weights ###
#####################################

function find_route(network::OpenStreetMap2.Network, node0::Int, node1::Int, weights::SparseArrays.SparseMatrixCSC{Float64,Int64}, get_distance::Bool = false, get_time::Bool = false)
    result = Any[]
    start_vertex = network.v[node0]
    dijkstra_result = OpenStreetMap2.dijkstra(network, weights, start_vertex)
    finish_vertex= network.v[node1]
    route_indices, route_values = OpenStreetMap2.extract_route(dijkstra_result, start_vertex, finish_vertex)
    route_nodes = OpenStreetMap2.get_route_nodes(network, route_indices)
    push!(result, route_nodes, route_values)
    if get_distance
		if isempty(route_indices)
			distance = Inf
		elseif length(route_indices) == 1
			distance = 0 
		else
			distance = OpenStreetMap2.calculate_distance(network, network.w, route_indices)
		end
        push!(result, distance)
    end
    if get_time
        w = OpenStreetMap2.create_weights_matrix(network,network_travel_times(network))
		if isempty(route_indices)
			route_time = Inf
		elseif length(route_indices) == 1
			route_time = 0
        else
			route_time = OpenStreetMap2.calculate_distance(network, w, route_indices)
		end
        push!(result, route_time)
    end
    return result
end


#########################################################
### Find Route Connecting 3 Points with Given Weights ###
#########################################################

function find_route(network::OpenStreetMap2.Network, node0::Int, node1::Int, node2::Int, weights::SparseArrays.SparseMatrixCSC{Float64,Int64}, get_distance::Bool = false, get_time::Bool = false)
	result = Any[]
	route1 = OpenStreetMap2.find_route(network, node0, node1, weights, get_distance, get_time)
	route2 = OpenStreetMap2.find_route(network, node1, node2, weights, get_distance, get_time)
	push!(result,vcat(route1[1],route2[1]))
	for i = 2:length(route1)
		push!(result,route1[i] + route2[i])
	end
	return result
end

###########################
### Find Shortest Route ###
###########################

function shortest_route(network::OpenStreetMap2.Network, node0::Int, node1::Int)
	route_nodes, distance, route_time = OpenStreetMap2.find_route(network,node0,node1,network.w,false,true)
	return route_nodes, distance, route_time
end

##################################################################
### Find Shortest Route Connecting 3 Points with Given Weights ###
##################################################################

function shortest_route(network::OpenStreetMap2.Network, node0::Int, node1::Int, node2::Int)
	route_nodes, distance, route_time = OpenStreetMap2.find_route(network,node0,node1, node2, network.w,false,true)
	return route_nodes, distance, route_time
end

##########################
### Find Fastest Route ###
##########################

function fastest_route(network::OpenStreetMap2.Network, node0::Int, node1::Int, speeds=OpenStreetMap2.SPEED_ROADS_URBAN)
	w = OpenStreetMap2.create_weights_matrix(network,network_travel_times(network, speeds))
	route_nodes, route_time, distance = OpenStreetMap2.find_route(network,node0,node1,w,true, false)
	return route_nodes, distance, route_time
end

#################################################################
### Find Fastest Route Connecting 3 Points with Given Weights ###
#################################################################

function fastest_route(network::OpenStreetMap2.Network, node0::Int, node1::Int, node2::Int, speeds=OpenStreetMap2.SPEED_ROADS_URBAN)
	w = OpenStreetMap2.create_weights_matrix(network,network_travel_times(network, speeds))
	route_nodes, route_time, distance = OpenStreetMap2.find_route(network,node0,node1, node2, w,true, false)
	return route_nodes, distance, route_time
end

###########################################
### Find  waypoint minimizing the route ###
###########################################

### Approximate solution ###

function find_optimal_waypoint_approx(network::OpenStreetMap2.Network, weights::SparseArrays.SparseMatrixCSC{Float64,Int64}, node0::Int, node1::Int, waypoints::Dict{Int,Int})
    dists_start_waypoint = LightGraphs.dijkstra_shortest_paths(network.g, network.v[node0], weights).dists
    dists_waypoint_fin = LightGraphs.dijkstra_shortest_paths(network.g, network.v[node1], weights).dists
    node_id = NaN
    min_dist = Inf
    for (key,value) in waypoints
        dist  = dists_start_waypoint[network.v[value]] + dists_waypoint_fin[network.v[value]] 
        if dist < min_dist
            min_dist = dist
            node_id = value
        end
    end
    return node_id
end

### Exact solution ###

function find_optimal_waypoint_exact(network::OpenStreetMap2.Network, weights::SparseArrays.SparseMatrixCSC{Float64,Int64}, node0::Int, node1::Int, waypoints::Dict{Int,Int})
    dists_start_waypoint = LightGraphs.dijkstra_shortest_paths(network.g, network.v[node0], weights).dists
    node_id = NaN
    min_dist = Inf
    for (key,value) in waypoints
        dist_to_fin = LightGraphs.dijkstra_shortest_paths(network.g, network.v[value], weights).dists[network.v[node1]]
        dist  = dists_start_waypoint[network.v[value]] + dist_to_fin
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
function bellman_ford(network::OpenStreetMap2.Network, w::SparseArrays.SparseMatrixCSC{Float64,Int64}, start_vertices::Vector{Int})
    return LightGraphs.bellman_ford_shortest_paths(network.g, start_vertices, w)
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

function nodes_within_weights(network::OpenStreetMap2.Network, weights::SparseArrays.SparseMatrixCSC{Float64,Int64}, start_indices::Vector{Int}, limit::Float64=Inf)
	start_vertices = [network.v[i] for i in start_indices]
    bellman_ford = OpenStreetMap2.bellman_ford(network, weights, start_vertices)
    return OpenStreetMap2.filter_vertices(network.v, bellman_ford.dists, limit)
end

nodes_within_weights(nodes::Dict{Int,T}, network::OpenStreetMap2.Network, weights::SparseArrays.SparseMatrixCSC{Float64,Int64}, loc::T, limit::Float64=Inf,locrange::Float64=500.0) where T<:(Union{OpenStreetMap2.ENU,OpenStreetMap2.ECEF}) = OpenStreetMap2.nodes_within_weights(network, weights, nodes_within_range(nodes, loc, network, locrange), limit)

##############################################################################
### Extract Nodes from bellman_fordStates Object Within an (Optional) Limit ###
### Based on Driving Distance											   ###
##############################################################################

function nodes_within_driving_distance(network::OpenStreetMap2.Network, start_indices::Vector{Int}, limit::Float64=Inf)
    start_vertices = [network.v[i] for i in start_indices]
    bellman_ford = OpenStreetMap2.bellman_ford(network, network.w, start_vertices)
    return OpenStreetMap2.filter_vertices(network.v, bellman_ford.dists, limit)
end

nodes_within_driving_distance(nodes::Dict{Int,T}, network::OpenStreetMap2.Network, loc::T, limit::Float64=Inf,locrange::Float64=500.0) where T<:(Union{OpenStreetMap2.ENU,OpenStreetMap2.ECEF})= OpenStreetMap2.nodes_within_driving_distance(network, nodes_within_range(nodes, loc ,network, locrange), limit)

##############################################################################
### Extract Nodes from bellman_fordStates Object Within an (Optional) Limit ###
### Based on Driving Time												   ###
##############################################################################

function nodes_within_driving_time(network::OpenStreetMap2.Network, start_indices::Vector{Int}, limit::Float64=Inf, speeds::Dict{Int,Int}=OpenStreetMap2.SPEED_ROADS_URBAN)
	w = OpenStreetMap2.create_weights_matrix(network,network_travel_times(network, speeds))
	start_vertices = [network.v[i] for i in start_indices]
    bellman_ford = OpenStreetMap2.bellman_ford(network, w, start_vertices)
    return OpenStreetMap2.filter_vertices(network.v, bellman_ford.dists, limit)
end

function nodes_within_driving_time(nodes::Dict{Int,T}, network::OpenStreetMap2.Network, loc::T, limit::Float64=Inf, locrange::Float64=500.0, speeds::Dict{Int,Int}=OpenStreetMap2.SPEED_ROADS_URBAN) where T<:(Union{OpenStreetMap2.ENU,OpenStreetMap2.ECEF})
	w = OpenStreetMap2.create_weights_matrix(network,network_travel_times(network, speeds))
	return OpenStreetMap2.nodes_within_driving_time(network,nodes_within_range(nodes, loc, network,locrange),limit,speeds)
end
