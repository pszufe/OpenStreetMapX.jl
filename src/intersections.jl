###########################
### Auxiliary Functions ###
###########################


"""
    oneway(w::OpenStreetMapX.Way)

Check if Way is One - Way
"""
function oneway(w::OpenStreetMapX.Way)
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


"""
    reverseway(w::OpenStreetMapX.Way)

Check if Way is Reverse
"""
reverseway(w::OpenStreetMapX.Way) = (get(w.tags,"oneway", "") == "-1")

"""
    distance(nodes::Dict{Int,T}, route::AbstractVector{Int}) where T<:(Union{OpenStreetMapX.ENU,OpenStreetMapX.ECEF})

Compute the distance of a route for some `nodes` data
"""
function distance(nodes::Dict{Int,T}, route::AbstractVector{Int}) where T<:(Union{OpenStreetMapX.ENU,OpenStreetMapX.ECEF})
    if length(route) == 0
        return Inf
    end
    dist = sum(distance(nodes[route[i-1]],nodes[route[i]]) for i = 2:length(route))
end

"""
    find_intersections(highways::Vector{OpenStreetMapX.Way})

Find Intersections of Highways
"""
function find_intersections(highways::Vector{OpenStreetMapX.Way})
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

"""
    find_segments(nodes::Dict{Int,T}, highways::Vector{OpenStreetMapX.Way}, intersections::Dict{Int,Set{Int}}) where T<:Union{OpenStreetMapX.ENU,OpenStreetMapX.ECEF}

Find Segments of Highways
"""
function find_segments(nodes::Dict{Int,T}, highways::Vector{OpenStreetMapX.Way}, intersections::Dict{Int,Set{Int}}) where T<:Union{OpenStreetMapX.ENU,OpenStreetMapX.ECEF}
    segments = OpenStreetMapX.Segment[]
    for highway in highways
        firstNode = 1
        for j = 2:length(highway.nodes)
            if highway.nodes[firstNode] != highway.nodes[j] && (haskey(intersections, highway.nodes[j])|| j == length(highway.nodes))
                if !reverseway(highway)
                    seg = OpenStreetMapX.Segment(highway.nodes[firstNode],highway.nodes[j],highway.nodes[firstNode:j], OpenStreetMapX.distance(nodes, highway.nodes[firstNode:j]), highway.id)
                    push!(segments,seg)
                else
                    seg = OpenStreetMapX.Segment(highway.nodes[j],highway.nodes[firstNode],reverse(highway.nodes[firstNode:j]), OpenStreetMapX.distance(nodes, highway.nodes[firstNode:j]), highway.id)
                    push!(segments,seg)
                end
                if !oneway(highway)
                    seg = OpenStreetMapX.Segment(highway.nodes[j],highway.nodes[firstNode],reverse(highway.nodes[firstNode:j]), OpenStreetMapX.distance(nodes, highway.nodes[firstNode:j]), highway.id)
                    push!(segments,seg)
                end
				firstNode = j
            end
        end
    end
    return segments
end

function get_edges_distances(nodes::Dict{Int,T}, highways::Vector{OpenStreetMapX.Way}, intersections::Dict{Int,Set{Int}}) where T<:Union{OpenStreetMapX.ENU,OpenStreetMapX.ECEF}
    back = Dict{Tuple{Int,Int},Int}()
    e = Tuple{Int,Int}[]
    class = Int[]
    weight_vals = Float64[]
    function add_segment(way, path)
        edge = (first(path), last(path))
        weight = OpenStreetMapX.distance(nodes, path)
        if haskey(back, edge)
            i = back[edge]
            if weight < weight_vals[i]
                class[i] = classify_roadway(way)
                weight_vals[i] = weight
            end
        else
            push!(e, edge)
            push!(class, classify_roadway(way))
            push!(weight_vals, weight)
            back[edge] = length(e)
        end
    end
    for highway in highways
        firstNode = 1
        for j = 2:length(highway.nodes)
            if highway.nodes[firstNode] != highway.nodes[j] && (haskey(intersections, highway.nodes[j]) || j == length(highway.nodes))
                rev = reverseway(highway)
                if !rev
                    add_segment(highway, view(highway.nodes, firstNode:j))
                end
                if rev || !oneway(highway)
                    add_segment(highway, view(highway.nodes, j:-1:firstNode))
                end
				firstNode = j
            end
        end
    end
    return e, class, weight_vals
end
