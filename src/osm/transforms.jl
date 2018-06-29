### Julia OpenStreetMap Package ###
### MIT License                 ###
### Copyright 2014              ###

### Functions for map coordinate transformations ###

###############################################
### Conversion from LLA to ECEF coordinates ###
###############################################

# For dictionary of nodes
function ECEF(nodes::Dict{Int,LLA}, datum::Ellipsoid = WGS84)
    r = Dict{Int,ECEF}()
    sizehint!(r, ceil(Int, 1.5*length(nodes)))

    for (key, node) in nodes
        r[key] = ECEF(node, datum)
    end

    return r
end

###############################################
### Conversion from ECEF to LLA coordinates ###
###############################################

# For dictionary of nodes
function LLA(nodes::Dict{Int,ECEF}, datum::Ellipsoid = WGS84)
    r = Dict{Int,LLA}()
    sizehint!(r, ceil(Int, 1.5*length(nodes)))

    for (key, node) in nodes
        r[key] = LLA(node, datum)
    end

    return r
end

#####################################
### Conversion to ENU coordinates ###
#####################################

# Given a reference point
function ENU{T<:@compat Union{LLA,ECEF}}(nodes::Dict{Int,T},
                                         lla_ref::LLA,
                                         datum::Ellipsoid = WGS84)
    r = Dict{Int,ENU}()
    sizehint!(r, ceil(Int, 1.5*length(nodes)))

    for (key, node) in nodes
        r[key] = ENU(node, lla_ref, datum)
    end

    return r
end

# Given Bounds
function ENU(nodes::Dict, bounds::Bounds{LLA}, datum::Ellipsoid = WGS84)
    ENU(nodes, center(bounds), datum)
end
