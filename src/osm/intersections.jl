###########################
### Auxiliary Functions ###
###########################

### Check if Way is One - Way ### 

function oneway(w::Way)
    v = get(w.tags,"oneway", "")
    if v == "false" || v == "no" || v == "0"
        return false
    elseif v == "-1" || v == "true" || v == "yes" || v == "1"
        return true
    end
    highway = get(w.tags,"highway", "")
    junction = get(w.tags,"junction", "")
    return (highway == "motorway" || highway == "motorway_link" || junction == "roundabout")
end

### Check if Way is Reverse ###

reverseWay(w::Way) = (get(w.tags,"oneway", "") == "-1")

### Compute the distance of a route ###

function distance{T<:(Union{ENU,ECEF})}(nodes::Dict{Int,T}, route::Vector{Int})
    if length(route) == 0
        return Inf
    end
    dist = sum(distance(nodes[route[i-1]],nodes[route[i]]) for i = 2:length(route))
end

######################################
### Find Intersections of Highways ###
######################################

function findIntersections(highways::Vector{Way})
    seen = Set{Int}()
    intersections = Dict{Int,Set{Int}}()
    for highway in highways
        for i = 1:length(highway.nodes)
            if i == 1 || i == length(highway.nodes) || (highway.nodes[i] in seen)
                get!(Set{Int}, intersections, highway.nodes[i])
            else
                push!(seen, highway.nodes[i])
            end
        end
    end
    for highway in highways
        for i = 1:length(highway.nodes)
            if i == 1 || i == length(highway.nodes) || haskey(intersections, highway.nodes[i])
                push!(intersections[highway.nodes[i]], highway.id)
            end
        end
    end
    return intersections
end

#################################
### Find Segments of Highways ###
#################################

function findSegments{T<:Union{ENU,ECEF}}(nodes::Dict{Int,T}, highways::Vector{Way}, intersections::Dict{Int,Set{Int}})
    segments = Segment[]
    intersect = Set(keys(intersections))
    for highway in highways
        firstNode = 1
        for j = 2:length(highway.nodes)
            if highway.nodes[firstNode] != highway.nodes[j] && (in(highway.nodes[j], intersect)|| j == length(highway.nodes))
                if !reverseWay(highway)
                    seg = Segment(highway.nodes[firstNode],highway.nodes[j],highway.nodes[firstNode:j], distance(nodes, highway.nodes[firstNode:j]), highway.id)
                    push!(segments,seg)
                else
                    seg = Segment(highway.nodes[j],highway.nodes[firstNode],reverse(highway.nodes[firstNode:j]), distance(nodes, highway.nodes[firstNode:j]), highway.id)
                    push!(segments,seg)
                end
                if !oneway(highway)
                    seg = Segment(highway.nodes[j],highway.nodes[firstNode],reverse(highway.nodes[firstNode:j]), distance(nodes, highway.nodes[firstNode:j]), highway.id)
                    push!(segments,seg)
                end
				firstNode = j
            end
        end
    end
    return segments
end