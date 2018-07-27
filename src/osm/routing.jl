##############################
### Get Edges of the Graph ###
##############################

function getEdges{T<:Union{ENU,ECEF}}(nodes::Dict{Int,T},highways::Vector{Way})
    onewayRoads = map(oneway,highways)
    reverseRoads = map(reverseWay,highways)
	classes = classifyRoadways(highways)
    edges = Dict{Tuple{Int,Int},Int}()
    for i = 1:length(highways)
        for j = 2:length(highways[i].nodes)
            n0 = highways[i].nodes[j-1]
            n1 = highways[i].nodes[j]
            start = n0 * !reverseRoads[i] + n1 * reverseRoads[i]
            fin = n0 * reverseRoads[i] + n1 * !reverseRoads[i]
			edges[(start,fin)] = classes[highways[i].id]
            onewayRoads[i] || (edges[(fin,start)] = classes[highways[i].id])
        end
    end
	return collect(keys(edges)), collect(values(edges))
end

#################################
### Get Vertices of the Graph ###
#################################

function getVertices(edges::Array{Tuple{Int64,Int64},1})
    graphNodes = unique(reinterpret(Int, edges))
    vertices = Dict{Int,Int}(zip(graphNodes, 1:length(graphNodes)))
end

###################################
### Get Distances Between Edges ###
###################################

function getDistances{T<:Union{ENU,ECEF}}(nodes::Dict{Int,T},edges::Array{Tuple{Int64,Int64},1})
    distances = []
    for edge in edges
        dist = distance(nodes[edge[2]],nodes[edge[1]])
        push!(distances,dist)
    end
    return distances
end

############################
### Create Network Graph ###
############################

### Create Network with all nodes ###

function createGraph{T<:Union{ENU,ECEF}}(nodes::Dict{Int,T},highways::Vector{Way})
    e,class = getEdges(nodes,highways)
    v = getVertices(e)
    weights = getDistances(nodes,e)
    edges = [v[id] for id in reinterpret(Int, e)]
    I = edges[1:2:end] 
    J = edges[2:2:end] 
    w = sparse(I, J, weights, length(v), length(v))
    Network(LightGraphs.DiGraph(w),v,e,w,class)
end

### Create Network with Roads intersections only### 

function createGraph(segments::Vector{Segment}, intersections::Dict{Int,Set{Int}},classifiedHighways::Dict{Int,Int})
    vals = Dict((segment.node0,segment.node1) => (segment.distance,segment.parent) for segment in segments)
	e = collect(keys(vals))
	vals = collect(values(vals))
	weights = map(val -> val[1],vals)
	class =  [classifiedHighways[id] for id in map(val -> val[2],vals)]
	v = getVertices(e)
    edges = [v[id] for id in reinterpret(Int, e)]
    I = edges[1:2:end] 
    J = edges[2:2:end] 
    w = sparse(I, J, weights, length(v), length(v))
    Network(LightGraphs.DiGraph(w),v,e,w,class)
end

#########################################
### Find Routes - Auxiliary Functions ###
#########################################

### Dijkstra's Algorithm ###
function dijkstra(network::OpenStreetMap.Network, w::SparseMatrixCSC{Float64,Int64}, startVertex::Int)
    return LightGraphs.dijkstra_shortest_paths(network.g, startVertex, w)
end

### Transpose distances to times ###

function networkTravelTimes(network::OpenStreetMap.Network, class_speeds::Dict{Int,Int})
    @assert length(network.e) == length(network.w.nzval)
    indices = [(network.v[i],network.v[j]) for (i,j) in network.e]
    w = Array{Float64}(length(network.e))
    for i = 1:length(w)
        w[i] = 3.6 * (network.w[indices[i]]/class_speeds[network.class[i]])
    end
    return w
end

### Create a Sparse Matrix for a given vector of weights ###

function createWeightsMatrix(network::OpenStreetMap.Network,weights::Vector{Float64})
    return sparse(map(i -> network.v[i[1]], network.e), map(i -> network.v[i[2]], network.e),weights)
end

### Extract route from Dijkstra results object ###

function extractRoute(dijkstra::LightGraphs.DijkstraState{Float64,Int64}, startIndex::Int, finishIndex::Int)
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

function getRouteNodes(network::OpenStreetMap.Network, routeIndices::Array{Int64,1})
    routeNodes = Array{Int}(length(routeIndices))
    v = map(reverse, network.v)
    for n = 1:length(routeNodes)
        routeNodes[n] = v[routeIndices[n]]
    end
    return routeNodes
end

### Generate an ordered list of edges traversed in route ###

function routeEdges(network::OpenStreetMap.Network, routeNodes::Vector{Int})
	e = Array{Int}(length(routeNodes)-1)
	for i = 2:length(routeNodes)
		e[i-1] = findfirst(network.e, (routeNodes[i-1], routeNodes[i]))
	end
	return e
end

### Calculate distance with a given weights ###

calculateDistance(network::OpenStreetMap.Network, weights::SparseMatrixCSC{Float64,Int64}, routeIndices::Array{Int64,1}) = sum(weights[(routeIndices[i-1], routeIndices[i])] for i = 2:length(routeIndices))


#####################################
### Find Route with Given Weights ###
#####################################

function findRoute(network::OpenStreetMap.Network, node0::Int, node1::Int, weights::SparseMatrixCSC{Float64,Int64}, getDistance::Bool = false, getTime::Bool = false)
    result = Any[]
    startVertex = network.v[node0]
    dijkstraResult = OpenStreetMap.dijkstra(network, weights, startVertex)
    finishVertex= network.v[node1]
    routeIndices, routeValues = extractRoute(dijkstraResult, startVertex, finishVertex)
    routeNodes = getRouteNodes(network, routeIndices)
    push!(result, routeNodes, routeValues)
    if getDistance
        distance = isempty(routeIndices) ? 0 : calculateDistance(network, network.w, routeIndices)
        push!(result, distance)
    end
    if getTime
        w = createWeightsMatrix(network,networkTravelTimes(network, SPEED_ROADS_URBAN))
        routeTime = isempty(routeIndices) ? 0 : calculateDistance(network, w, routeIndices)
        push!(result, routeTime)
    end
    return result
end

###########################
### Find Shortest Route ###
###########################

function shortestRoute(network::OpenStreetMap.Network, node0::Int, node1::Int)
	routeNodes, distance, routeTime = findRoute(network,node0,node1,network.w,false,true)
	return routeNodes, distance, routeTime
end

##########################
### Find Fastets Route ###
##########################

function fastestRoute(network::OpenStreetMap.Network, node0::Int, node1::Int, classSpeeds=OpenStreetMap.SPEED_ROADS_URBAN)
	w = createWeightsMatrix(network,networkTravelTimes(network, classSpeeds))
	routeNodes, routeTime, distance = findRoute(network,node0,node1,w,true, false)
	return routeNodes, distance, routeTime
end

########################################################################
### Find Nodes Within Driving Time or Distance - Auxiliary Functions ###
########################################################################

### Bellman Ford's Algorithm ###
function bellmanFord(network::OpenStreetMap.Network, w::SparseMatrixCSC{Float64,Int64}, startVertices::Vector{Int})
    return LightGraphs.bellman_ford_shortest_paths(network.g, startVertices, w)
end

### Filter vertices from BellmanFordStates object ###

function filterVertices(vertices::Dict{Int,Int}, weights::Vector{Float64}, limit::Float64)
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
### Extract Nodes from BellmanFordStates Object Within an (Optional) Limit ###
### Based on Weights													   ###
##############################################################################

function nodesWithinWeights(network::OpenStreetMap.Network, weights::SparseMatrixCSC{Float64,Int64}, startIndices::Vector{Int}, limit::Float64=Inf)
	startVertices = [network.v[i] for i in startIndices]
    bellmanford = bellmanFord(network, weights, startVertices)
    return filterVertices(network.v, bellmanford.dists, limit)
end

nodesWithinWeights{T<:(Union{ENU,ECEF})}(nodes::Dict{Int,T}, network::OpenStreetMap.Network, weights::SparseMatrixCSC{Float64,Int64}, loc::T, limit::Float64=Inf,locRange::Float64=500.0) = nodesWithinWeights(network, weights, nodesWithinRange(nodes, loc, network, locRange), limit)

##############################################################################
### Extract Nodes from BellmanFordStates Object Within an (Optional) Limit ###
### Based on Driving Distance											   ###
##############################################################################

function nodesWithinDrivingDistance(network::OpenStreetMap.Network, startIndices::Vector{Int}, limit::Float64=Inf)
    startVertices = [network.v[i] for i in startIndices]
    bellmanford = bellmanFord(network, network.w, startVertices)
    return filterVertices(network.v, bellmanford.dists, limit)
end

nodesWithinDrivingDistance{T<:(Union{ENU,ECEF})}(nodes::Dict{Int,T}, network::OpenStreetMap.Network, loc::T, limit::Float64=Inf,locRange::Float64=500.0) = nodesWithinDrivingDistance(network, nodesWithinRange(nodes, loc ,network, locRange), limit)

##############################################################################
### Extract Nodes from BellmanFordStates Object Within an (Optional) Limit ###
### Based on Driving Time												   ###
##############################################################################

function nodesWithinDrivingTime(network::OpenStreetMap.Network, startIndices::Vector{Int}, limit::Float64=Inf, classSpeeds::Dict{Int,Int}=OpenStreetMap.SPEED_ROADS_URBAN)
	w = createWeightsMatrix(network,networkTravelTimes(network, classSpeeds))
	startVertices = [network.v[i] for i in startIndices]
    bellmanford = bellmanFord(network, w, startVertices)
    return filterVertices(network.v, bellmanford.dists, limit)
end

function nodesWithinDrivingTime{T<:(Union{ENU,ECEF})}(nodes::Dict{Int,T}, network::OpenStreetMap.Network, loc::T, limit::Float64=Inf, locRange::Float64=500.0, classSpeeds::Dict{Int,Int}=OpenStreetMap.SPEED_ROADS_URBAN)
	w = createWeightsMatrix(network,networkTravelTimes(network, classSpeeds))
	return nodesWithinDrivingTime(network,nodesWithinRange(nodes, loc, network,locRange),limit,classSpeeds)
end
