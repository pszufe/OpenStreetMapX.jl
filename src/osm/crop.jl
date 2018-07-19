###############################
### Crop Nodes and Features ###
###############################

function crop!(nodes::Dict, bounds::Bounds, features::Dict)
    for (key, feature) in features
        if !inBounds(nodes[key], bounds)
            delete!(features, key)
            delete!(nodes,key)
        end
    end
end

#######################
### Crop Single Way ###
#######################


#################
### Crop Ways ###
#################

function crop!(nodes::Dict, bounds::Bounds, ways::Vector{Way})
    toRemove = [crop!(nodes,bounds,way) for way in ways]
    filter!(way -> toRemove(findfirst(ways,way)) != true, ways)
end


############################
### Crop Single Relation ###
############################


######################
### Crop Relations ###
######################

################
### Crop Map ###
################