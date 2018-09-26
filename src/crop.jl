#######################
### Crop Single Way ###
#######################

function crop!(nodes::Dict, bounds::OpenStreetMapX.Bounds, way::OpenStreetMapX.Way)
    valid = falses(length(way.nodes)+2)
    n = 1
    while n <= length(way.nodes)
        if !haskey(nodes, way.nodes[n])
            splice!(way.nodes, n)
            splice!(valid, n+1)
        else
            valid[n+1] = OpenStreetMapX.inbounds(nodes[way.nodes[n]], bounds)
            n += 1
        end
    end
    if sum(valid) == 0
        return true
    elseif sum(valid) < (length(valid)-2)
		leave = trues(length(way.nodes))
        for i in 2:(length(valid)-1)
            if !valid[i]
                if valid[i-1] != valid[i]
                    if !OpenStreetMapX.onbounds(nodes[way.nodes[i-2]], bounds)
                        new_node = OpenStreetMapX.boundary_point(nodes[way.nodes[i-2]], nodes[way.nodes[i-1]],bounds)
                        new_id = OpenStreetMapX.add_new_node!(nodes, new_node)
                        way.nodes[i-1] = new_id
                    else
						leave[i-1] = false
                    end
                elseif valid[i] != valid[i+1]
                    if !OpenStreetMapX.onbounds(nodes[way.nodes[i]], bounds)
                        new_node = OpenStreetMapX.boundary_point(nodes[way.nodes[i-1]], nodes[way.nodes[i]],bounds)
                        new_id = OpenStreetMapX.add_new_node!(nodes, new_node)
                        way.nodes[i-1] = new_id
                    else
                        leave[i-1] = false
                    end
                else
                    leave[i-1] = false
                end
            end
        end
		way.nodes = way.nodes[leave]
        return false
    else
        return false
    end
end

#################
### Crop Ways ###
#################

function crop!(nodes::Dict, bounds::OpenStreetMapX.Bounds, ways::Vector{OpenStreetMapX.Way})
    leave = ways[[!OpenStreetMapX.crop!(nodes,bounds,way) for way in ways]]
	append!(empty!(ways),leave)
	return nothing
end


############################
### Crop Single Relation ###
############################

function crop!(nodes::Dict, bounds::OpenStreetMapX.Bounds, ways::Vector{OpenStreetMapX.Way},relations::Vector{OpenStreetMapX.Relation}, relation::OpenStreetMapX.Relation)
	valid = falses(length(relation.members))
	for i = 1:length(relation.members)
		ref = parse(Int,relation.members[i]["ref"])
		if relation.members[i]["type"] == "node" && haskey(nodes,ref)
			valid[i] = OpenStreetMapX.inbounds(nodes[ref],bounds)
		elseif relation.members[i]["type"] == "way"
			way_index = findfirst(way -> way.id == ref, ways)
			!isa(way_index,Nothing) && (valid[i] = !OpenStreetMapX.crop!(nodes, bounds, ways[way_index])) 
		else
			relation_index = findfirst(relation -> relation.id == ref, relations)
			!isa(relation_index,Nothing) && (valid[i] = !OpenStreetMapX.crop!(nodes,bounds, ways, relations, relations[relation_index])) 
		end
	end
	relation.members = relation.members[valid]
	if sum(valid) == 0
		return true
	else
		return false
	end
end

######################
### Crop Relations ###
######################

function crop!(nodes::Dict, bounds::OpenStreetMapX.Bounds, ways::Vector{OpenStreetMapX.Way}, relations::Vector{OpenStreetMapX.Relation})
    leave = relations[[!OpenStreetMapX.crop!(nodes,bounds,ways, relations, relation) for relation in relations]]
	append!(empty!(relations),leave)
	return nothing
end

####################################
### Crop Single Node and Feature ###
####################################

function crop!(nodes::Dict, bounds::OpenStreetMapX.Bounds, features::Dict, id::Int)
	if !OpenStreetMapX.inbounds(nodes[id], bounds)
		id in keys(features) && delete!(features, id)
		delete!(nodes,id)
	end
end

###############################
### Crop Nodes and Features ###
###############################

function crop!(nodes::Dict, bounds::OpenStreetMapX.Bounds, features::Dict)
    for (key, node) in nodes
        OpenStreetMapX.crop!(nodes,bounds,features,key)
    end
end

################
### Crop Map ###
################

function crop!(map::OpenStreetMapX.OSMData; crop_relations = true, crop_ways = true, crop_nodes = true)
	crop_relations && OpenStreetMapX.crop!(map.nodes, map.bounds, map.ways, map.relations)
	crop_ways && OpenStreetMapX.crop!(map.nodes, map.bounds, map.ways)
	crop_nodes && OpenStreetMapX.crop!(map.nodes, map.bounds, map.features)
end