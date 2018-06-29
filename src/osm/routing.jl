### Julia OpenStreetMap Package ###
### MIT License                 ###
### Copyright 2014              ###

### Route Planning for OpenStreetMap ###

### Get list of vertices (highway nodes) in specified levels of classes ###
# For all highways
function highwayVertices(highways::Dict{Int,Highway})
    vertices = Set{Int}()

    for highway in values(highways)
        union!(vertices, highway.nodes)
    end

    return vertices
end

# For classified highways
function highwayVertices(highways::Dict{Int,Highway}, classes::Dict{Int,Int})
    vertices = Set{Int}()

    for key in keys(classes)
        union!(vertices, highways[key].nodes)
    end

    return vertices
end

# For specified levels of a classifier dictionary
function highwayVertices(highways::Dict{Int,Highway}, classes::Dict{Int,Int}, levels)
    vertices = Set{Int}()

    for (key, class) in classes
        if in(class, levels)
            union!(vertices, highways[key].nodes)
        end
    end

    return vertices
end


### Form transportation network graph of map ###
function createGraph(nodes, highways::Dict{Int,Highway}, classes, levels, reverse::Bool=false)
    w = Float64[]                                               # Weights
    g_classes = Int[]                                           # Road classes
    verts = highwayVertices(highways, classes, levels)
    g = LightGraphs.DiGraph(length(keys(intersections)))                      # Graph
    v = Dict{Int,Int}(zip(keys(intersections),1:length(keys(intersections))))              # Vertices
    e = Array{Tuple{Int64,Int64},1}()                                         #edges

    for (key, class) in classes
        if in(class, levels)
            highway = highways[key]
            if length(highway.nodes) > 1
                # Add edges to graph and compute weights
                for n = 2:length(highway.nodes)
                    if reverse
                        node0 = highway.nodes[n]
                        node1 = highway.nodes[n-1]
                    else
                        node0 = highway.nodes[n-1]
                        node1 = highway.nodes[n]
                    end
                    LightGraphs.add_edge!(g, v[node0], v[node1])
                    weight = distance(nodes, node0, node1)
                    push!(w, weight)
                    push!(g_classes, class)
                    push!(e,(v[node0],v[node1]))

                    if !highway.oneway
                        LightGraphs.add_edge!(g, v[node1], v[node0])
                        push!(w, weight)
                        push!(g_classes, class)
                        push!(e,(v[node1],v[node0]))
                    end
                end
            end
        end
    end

    return Network(g, v, w, e, g_classes)
end


### Form transportation network graph of map ###
function createGraph(segments::Vector{Segment}, intersections, reverse::Bool=false)
    w = Float64[]                                               # Weights
    class = Int[]                                               # Road class
    g = LightGraphs.DiGraph(length(keys(intersections)))        # Graph
    v = Dict{Int,Int}(zip(keys(intersections),1:length(keys(intersections))))              # Vertices
    e = Array{Tuple{Int64,Int64},1}()                           #Edges
    for segment in segments
        # Add edges to graph and compute weights
        if reverse
            node0 = segment.node1
            node1 = segment.node0
        else
            node0 = segment.node0
            node1 = segment.node1
        end
        LightGraphs.add_edge!(g, v[node0], v[node1])
        weight = segment.dist
        push!(w, weight)
        push!(class, segment.class)
        push!(e,(v[node0],v[node1]))

        if !segment.oneway
            LightGraphs.add_edge!(g, v[node1], v[node0])
            push!(w, weight)
            push!(class, segment.class)
            push!(e,(v[node1],v[node0]))
        end
    end

    return Network(g, v, w, e, class)
end

# Put all edges in network.g in an array
function getEdges( network::Network )
    edges = collect(LightGraphs.edges(network.g))
end

### Get distance between two nodes ###
# ENU Coordinates
function distance{T<:@compat(Union{ENU,ECEF})}(nodes::Dict{Int,T}, node0, node1)
    loc0 = nodes[node0]
    loc1 = nodes[node1]

    return distance(loc0, loc1)
end

### Compute the distance of a route ###
function distance{T<:@compat(Union{ENU,ECEF})}(nodes::Dict{Int,T}, route::Vector{Int})
    if length(route) == 0
        return Inf
    end

    dist = 0.0
    prev_point = nodes[route[1]]
    for i = 2:length(route)
        point = nodes[route[i]]
        dist += distance(prev_point, point)
        prev_point = point
    end

    return dist
end

### Shortest Paths ###
function createWeightsMatrix(network::Network,weights::Vector{Float64} = network.w)
    return sparse(map(i -> i[1], network.e), map(i -> i[2], network.e),weights)
end


# Dijkstra's Algorithm
function dijkstra(network, w, start_vertex)
    return LightGraphs.dijkstra_shortest_paths(network.g, start_vertex, createWeightsMatrix(network,w))
end

# Bellman Ford's Algorithm
function bellmanFord(network, w, start_vertices)
    return LightGraphs.bellman_ford_shortest_paths(network.g, start_vertex, createWeightsMatrix(network,w))
end


# Extract route from Dijkstra results object
function extractRoute(dijkstra, start_index, finish_index)
    route = Int[]

    distance = dijkstra.dists[finish_index]

    if distance != Inf
        index = finish_index
        push!(route, index)
        while index != start_index
            index = dijkstra.parents[index]
            push!(route, index)
        end
    end

    reverse!(route)

    return route, distance
end



### Generate an ordered list of edges traversed in route (moze do zrobienia kiedys)
#function routeEdges(network::Network, route::Vector{Int})
    #e = Array{Int}(length(route)-1)

    # For each node pair, find matching edge
    #for n = 1:length(route)-1
        #s = route[n]
        #t = route[n+1]

        #for e_candidate in Graphs.out_edges(network.v[s],network.g)
            #if t == e_candidate.target.key
                #e[n] = e_candidate.index
                #break
            #end
        #end
    #end

    #return e
#end

function getRouteNodes(network, route_indices)
    route_nodes = Array{Int}(length(route_indices))
    v = map(reverse, network.v)
    for n = 1:length(route_indices)
        route_nodes[n] = v[route_indices[n]]
    end

    return route_nodes
end

function networkTravelTimes(network, class_speeds)
    w = Array{Float64}(length(network.w))
    for k = 1:length(w)
        w[k] = network.w[k] / class_speeds[network.class[k]]
        w[k] *= 3.6 # (3600/1000) unit conversion to seconds
    end
    return w
end


calculateDistance(network, weights, route_indices) = sum(weights[findfirst(x -> x == (route_indices[i], route_indices[i+1]),network.e)] for i = 1:length(route_indices)-1)


### Shortest Route ###
function shortestRoute(network, node0, node1,class_speeds=SPEED_ROADS_URBAN)
    start_vertex = network.v[node0]
    w = networkTravelTimes(network, class_speeds)
    dijkstra_result = dijkstra(network, network.w, start_vertex)
    start_index = network.v[node0]
    finish_index = network.v[node1]
    route_indices, distance = extractRoute(dijkstra_result, start_index, finish_index)

    route_nodes = getRouteNodes(network, route_indices)

    route_time = calculateDistance(network, w, route_indices)

    return route_nodes, distance, route_time
end


### Fastest Route ###
function fastestRoute(network, node0, node1, class_speeds=SPEED_ROADS_URBAN)
    start_vertex = network.v[node0]

    # Modify weights to be times rather than distances
    w = networkTravelTimes(network, class_speeds)
    dijkstra_result = dijkstra(network, w, start_vertex)

    start_index = network.v[node0]
    finish_index = network.v[node1]
    route_indices, route_time = extractRoute(dijkstra_result, start_index, finish_index)

    route_nodes = getRouteNodes(network, route_indices)

    distance = calculateDistance(network, network.w, route_indices)

    return route_nodes, distance, route_time
end

function filterVertices(vertices, weights, limit)
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


# Extract nodes from BellmanFordStates object within an (optional) limit
# based on driving distance
function nodesWithinDrivingDistance(network::Network, start_indices, limit=Inf)
    start_vertices = [network.v[i] for i in start_indices]
    bellmanford = bellmanFord(network, network.w, start_vertices)
    return filterVertices(network.v, bellmanford.dists, limit)
end


function nodesWithinDrivingDistance(network::Network,
                                    loc::ENU,
                                    limit=Inf,
                                    loc_range=100.0)
    return nodesWithinDrivingDistance(network,
                                      nodesWithinRange(network.v, loc, loc_range),
                                      limit)
end


# Extract nodes from BellmanFordStates object within a (optional) limit,
# based on driving time
function nodesWithinDrivingTime(network,
                                start_indices,
                                limit=Inf,
                                class_speeds=SPEED_ROADS_URBAN)
    # Modify weights to be times rather than distances
    w = networkTravelTimes(network, class_speeds)
    start_vertices = [network.v[i] for i in start_indices]
    bellmanford = bellmanFord(network, w, start_vertices)
    return filterVertices(network.v, bellmanford.dists, limit)
end


function nodesWithinDrivingTime(network::Network,
                                loc::ENU,
                                limit=Inf,
                                class_speeds=SPEED_ROADS_URBAN,
                                loc_range=100.0)
    return nodesWithinDrivingTime(network,
                                  nodesWithinRange(network.v, loc, loc_range),
                                  limit)
end
