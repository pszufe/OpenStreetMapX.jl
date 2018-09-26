######################
### Add a New Node ###
######################

function add_new_node!(nodes::Dict{Int,T},loc::T, start_id::Int = reinterpret((Int), hash(loc))) where T <: (Union{OpenStreetMap2.LLA,OpenStreetMap2.ENU})
    id = start_id
    while id <= typemax(Int)
        if !haskey(nodes, id)
            nodes[id] = loc
            return id
        end
        id += 1
    end

    msg = "Unable to add new node to map, $(typemax(Int)) nodes is the current limit."
    throw(error(msg))
end

#############################
### Find the Nearest Node ###
#############################

### Find the nearest node to a given location ###
function nearest_node(nodes::Dict{Int,T}, loc::T) where T<:(Union{OpenStreetMap2.ENU,OpenStreetMap2.ECEF})
    min_dist = Inf
    best_ind = 0

    for (key, node) in nodes
        dist = OpenStreetMap2.distance(node, loc)
        if dist < min_dist
            min_dist = dist
            best_ind = key
        end
    end

    return best_ind
end

### Find nearest node in a list of nodes ###
function nearest_node(nodes::Dict{Int,T}, loc::T, node_list::Vector{Int}) where T<:(Union{OpenStreetMap2.ENU,OpenStreetMap2.ECEF})
    min_dist = Inf
    best_ind = 0

    for ind in node_list
        dist = OpenStreetMap2.distance(nodes[ind], loc)
        if dist < min_dist
            min_dist = dist
            best_ind = ind
        end
    end

    return best_ind
end


### Find nearest node serving as a vertex in a routing network ###
nearest_node(nodes::Dict{Int,T}, loc::T, network::OpenStreetMap2.Network) where T<:(Union{OpenStreetMap2.ENU,OpenStreetMap2.ECEF}) = OpenStreetMap2.nearest_node(nodes,loc,collect(keys(network.v)))

#############################
### Find Node Within Range###
#############################

### Find all nodes within range of a location ###
function nodes_within_range(nodes::Dict{Int,T}, loc::T, range::Float64 = Inf) where T<:(Union{OpenStreetMap2.ENU,OpenStreetMap2.ECEF})
    if range == Inf
        return keys(nodes)
    end
    indices = Int[]
    for (key, node) in nodes
        dist = OpenStreetMap2.distance(node, loc)
        if dist < range
            push!(indices, key)
        end
    end
    return indices
end

### Find nodes within range of a location using a subset of nodes ###
function nodes_within_range(nodes::Dict{Int,T}, loc::T, node_list::Vector{Int}, range::Float64 = Inf) where T<:(Union{OpenStreetMap2.ENU,OpenStreetMap2.ECEF})
    if range == Inf
        return node_list
    end
    indices = Int[]
    for ind in node_list
        dist = OpenStreetMap2.distance(nodes[ind], loc)
        if dist < range
            push!(indices, ind)
        end
    end
    return indices
end

### Find vertices of a routing network within range of a location ###
nodes_within_range(nodes::Dict{Int,T},loc::T, network::OpenStreetMap2.Network, range::Float64 = Inf) where T <:(Union{OpenStreetMap2.ENU,OpenStreetMap2.ECEF}) = OpenStreetMap2.nodes_within_range(nodes,loc,collect(keys(network.v)),range)

#########################################
### Compute Centroid of List of Nodes ###
#########################################

function centroid(nodes::Dict{Int,T}, node_list::Vector{Int}) where T<:(Union{OpenStreetMap2.LLA,OpenStreetMap2.ENU})
    sum_1 = 0
    sum_2 = 0
    sum_3 = 0
    if typeof(nodes) == Dict{Int,OpenStreetMap2.LLA}
        for k = 1:length(node_list)
            sum_1 += nodes[node_list[k]].lat
            sum_2 += nodes[node_list[k]].lon
            sum_3 += nodes[node_list[k]].alt
        end
        return OpenStreetMap2.LLA(sum_1/length(node_list),sum_2/length(node_list),sum_3/length(node_list))
    else
            for k = 1:length(node_list)
                sum_1 += nodes[node_list[k]].east
                sum_2 += nodes[node_list[k]].north
                sum_3 += nodes[node_list[k]].up
            end
        return OpenStreetMap2.ENU(sum_1/length(node_list),sum_2/length(node_list),sum_3/length(node_list))
    end
end
