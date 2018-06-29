### Julia OpenStreetMap Package ###
### MIT License                 ###
### Copyright 2014              ###

### Crop map elements without copying data ###
function cropMap!(nodes::@compat(Union{Dict{Int,LLA},Dict{Int,ENU}}), bounds::Bounds;
                  highways::@compat(Union{@compat(Void),Dict{Int,Highway}}) = nothing,
                  buildings::@compat(Union{@compat(Void),Dict{Int,Building}}) = nothing,
                  features::@compat(Union{@compat(Void),Dict{Int,Feature}}) = nothing,
                  delete_nodes::Bool=true)

    if !isa(highways, @compat(Void))
        crop!(nodes, bounds, highways)
    end
    if !isa(buildings, @compat(Void))
        crop!(nodes, bounds, buildings)
    end
    if !isa(features, @compat(Void))
        crop!(nodes, bounds, features)
    end

    if delete_nodes
        crop!(nodes, bounds)
    end

    return nothing
end

### Crop nodes ###
function crop!(nodes::Dict, bounds::Bounds)
    for (key, node) in nodes
        if !inBounds(node, bounds)
            delete!(nodes, key)
        end
    end

    return nothing
end

### Crop highways ###
function crop!(nodes::Dict, bounds::Bounds, highways::Dict{Int,Highway})
    missing_nodes = Int[]

    for (key, highway) in highways
        valid = falses(length(highway.nodes))
        n = 1
        while n <= length(highway.nodes)
            if haskey(nodes, highway.nodes[n])
                valid[n] = inBounds(nodes[highway.nodes[n]], bounds)
                n += 1
            else
                push!(missing_nodes, highway.nodes[n])
                splice!(highway.nodes, n)
                splice!(valid, n)
            end
        end

        nodes_in_bounds = sum(valid)

        if nodes_in_bounds == 0
            delete!(highways, key)   # Remove highway from list
        elseif nodes_in_bounds < length(valid)
            cropHighway!(nodes, bounds, highway, valid) # Crop highway length
        end
    end

    if length(missing_nodes) > 0
        warn("$(length(missing_nodes)) missing nodes were removed from highways.")
    end

    return missing_nodes
end

### Crop buildings ###
function crop!(nodes::Dict, bounds::Bounds, buildings::Dict{Int,Building})
    for (key, building) in buildings
        valid = falses(length(building.nodes))
        for n = 1:length(building.nodes)
            if haskey(nodes, building.nodes[n])
                valid[n] = inBounds(nodes[building.nodes[n]], bounds)
            end
        end

        nodes_in_bounds = sum(valid)
        if nodes_in_bounds == 0
            delete!(buildings, key)   # Remove building from list
        elseif nodes_in_bounds < length(valid)
            # TODO: Interpolate buildings to bounds?
            delete!(buildings, key)   # Remove building from list
        end
    end

    return nothing
end

### Crop features ###
function crop!(nodes::Dict, bounds::Bounds, features::Dict{Int,Feature})
    for key in keys(features)
        if !haskey(nodes, key) || !inBounds(nodes[key], bounds)
            delete!(features, key)
        end
    end

    return nothing
end

function cropHighway!(nodes::Dict, bounds::Bounds, highway::Highway, valids::BitVector)
    prev_id, prev_valid = highway.nodes[1], valids[1]
    ni = 1
    for valid in valids
        id = highway.nodes[ni]

        if !valid
            deleteat!(highway.nodes, ni)
            ni -= 1
        end
        if valid != prev_valid
            prev_node, node = nodes[prev_id], nodes[id]
            if !(onBounds(prev_node, bounds) ||
                 onBounds(node, bounds))
                new_node = boundaryPoint(prev_node, node, bounds)
                new_id = addNewNode!(nodes, new_node)
                insert!(highway.nodes, ni + !valid, new_id)
                ni += 1
            end
        end

        ni += 1

        prev_id, prev_valid = id, valid
    end

    return nothing
end
