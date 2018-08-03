#######################
### Crop Single Way ###
#######################

function crop!(nodes::Dict, bounds::Bounds, way::Way)
    valid = falses(length(way.nodes)+2)
    n = 1
    while n <= length(way.nodes)
        if !haskey(nodes, way.nodes[n])
            splice!(way.nodes, n)
            splice!(valid, n+1)
        else
            valid[n+1] = inBounds(nodes[way.nodes[n]], bounds)
            n += 1
        end
    end
    if sum(valid) == 0
        return true
    elseif sum(valid) < (length(valid)-2)
		toRemove = falses(length(way.nodes))
        for i in 2:(length(valid)-1)
            if !valid[i]
                if valid[i-1] != valid[i]
                    if !onBounds(nodes[way.nodes[i-2]], bounds)
                        new_node = boundaryPoint(nodes[way.nodes[i-2]], nodes[way.nodes[i-1]],bounds)
                        new_id = addNewNode!(nodes, new_node)
                        way.nodes[i-1] = new_id
                    else
						toRemove[i-1] = true
                    end
                elseif valid[i] != valid[i+1]
                    if !onBounds(nodes[way.nodes[i]], bounds)
                        new_node = boundaryPoint(nodes[way.nodes[i-1]], nodes[way.nodes[i]],bounds)
                        new_id = addNewNode!(nodes, new_node)
                        way.nodes[i-1] = new_id
                    else
                        toRemove[i-1] = true
                    end
                else
                    toRemove[i-1] = true
                end
            end
        end
		filter!(node -> toRemove[findfirst(way.nodes,node)] == false, way.nodes)
        return false
    else
        return false
    end
end

#################
### Crop Ways ###
#################

function crop!(nodes::Dict, bounds::Bounds, ways::Vector{Way})
    toRemove = [crop!(nodes,bounds,way) for way in ways]
    filter!(way -> toRemove[findfirst(ways,way)] == false, ways)
end


############################
### Crop Single Relation ###
############################

function crop!(nodes::Dict, bounds::Bounds, ways::Vector{Way},relations::Vector{Relation}, relation::Relation)
	valid = falses(length(relation.members))
	for i = 1:length(relation.members)
		ref = parse(Int,relation.members[i]["ref"])
		if relation.members[i]["type"] == "node" && haskey(nodes,ref)
			valid[i] = inBounds(nodes[ref],bounds)
		elseif relation.members[i]["type"] == "way"
			way_index = findfirst(way -> way.id == ref, ways)
			way_index != 0 && (valid[i] = !crop!(nodes, bounds, ways[way_index])) 
		else
			relation_index = findfirst(relation -> relation.id == ref, relations)
			relation_index != 0 && (valid[i] = !crop!(nodes,bounds, ways, relations, relations[relation_index])) 
		end
	end
	filter!(member -> valid[findfirst(relation.members,member)] == true, relation.members)
	if sum(valid) == 0
		return true
	else
		return false
	end
end

######################
### Crop Relations ###
######################

function crop!(nodes::Dict, bounds::Bounds, ways::Vector{Way}, relations::Vector{Relation})
    toRemove = [crop!(nodes,bounds,ways, relations, relation) for relation in relations]
    filter!(relation -> toRemove[findfirst(relations,relation)] == false, relations)
end

####################################
### Crop Single Node and Feature ###
####################################

function crop!(nodes::Dict, bounds::Bounds, features::Dict, id::Int)
	if !inBounds(nodes[id], bounds)
		id in keys(features) && delete!(features, id)
		delete!(nodes,id)
	end
end

###############################
### Crop Nodes and Features ###
###############################

function crop!(nodes::Dict, bounds::Bounds, features::Dict)
    for (key, node) in nodes
        crop!(nodes,bounds,features,key)
    end
end

################
### Crop Map ###
################

function crop!(map::OpenStreetMap.OSMData; cropRelations = true, cropWays = true, cropNodes = true)
	cropRelations && crop!(map.nodes, map.bounds, map.ways, map.relations)
	cropWays && crop!(map.nodes, map.bounds, map.ways)
	cropNodes && crop!(map.nodes, map.bounds, map.features)
end