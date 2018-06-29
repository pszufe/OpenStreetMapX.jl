### Julia OpenStreetMap Package ###
### MIT License                 ###
### Copyright 2014              ###

### Functions for finding highway intersections ###

### Generate a list of intersections ###
function findIntersections(highways::Dict{Int,Highway})
    seen = Set{Int}()
    intersections = Dict{Int,Intersection}()

    for hwy in values(highways)
        n_nodes = length(hwy.nodes)

        for i in 1:n_nodes
            node = hwy.nodes[i]

            if i == 1 || i == n_nodes || in(node, seen)
                get!(Intersection, intersections, node)
            else
                push!(seen, node)
            end
        end
    end

    for (hwy_key, hwy) in highways
        n_nodes = length(hwy.nodes)

        for i in 1:n_nodes
            node = hwy.nodes[i]

            if i == 1 || i == n_nodes || haskey(intersections, node)
                push!(intersections[node].highways, hwy_key)
            end
        end
    end

    return intersections
end

findClassIntersections(highways::Dict{Int,Highway},classes::Dict{Int,Int}) = findIntersections(filter!((x,y)->x in keys(classes), highways))



### Generate a new list of highways divided up by intersections
function segmentHighways(nodes, highways::Dict{Int,Highway}, intersections, classes, levels=Set(1:10))
    segments = Segment[]
    inters = Set(keys(intersections))

    for (i, class) in classes
        if in(class, levels) && haskey(highways,i)
            highway = highways[i]
            first = 1
            for j = 2:length(highway.nodes)
                if highway.nodes[first] != highway.nodes[j] && (in(highway.nodes[j], inters) || j == length(highway.nodes))
                    node0 = highway.nodes[first]
                    node1 = highway.nodes[j]
                    route_nodes = highway.nodes[first:j]
                    dist = distance(nodes, route_nodes)
                    s = Segment(node0, node1, route_nodes, dist, class, i, true)
                    push!(segments, s)

                    if !highway.oneway
                        s = Segment(node1, node0, reverse(route_nodes), dist, class, i, true)
                        push!(segments, s)
                    end
                    first = j
                end
            end
        end
    end

    return segments
end

### Generate a list of highways from segments, for plotting purposes
function highwaySegments( segments::Vector{Segment} )
    highways = Dict{Int,Highway}()

    for k = 1:length(segments)
        highways[k] = Highway("", 1, true, "", "", "", "$(segments[k].parent)", segments[k].nodes)
    end

    return highways
end


### Cluster highway intersections into higher-level intersections ###
# Note that there may be multiple intersection clusters containing the same 
# streets, due to curved streets. Parameter max_dist controls how far apart an 
# intersection must be from an existing cluster to create a new cluster.
function findIntersectionClusters( nodes::Dict{Int,ENU}, 
                                   intersections_in::Dict{Int,Intersection}, 
                                   highway_clusters::Vector{HighwaySet}; 
                                   max_dist=15.0 )
    hwy_cluster_mapping = Dict{Int,Int}()
    for k = 1:length(highway_clusters)
        hwys = [highway_clusters[k].highways...]
        for kk = 1:length(hwys)
            hwy_cluster_mapping[hwys[kk]] = k
        end
    end

    # Deep copy intersections dictionary and replace highways with highway 
    # sets where available
    intersections = deepcopy(intersections_in)
    for (node,inter) in intersections
        hwys = [inter.highways...]
        for k = 1:length(hwys)
            if haskey(hwy_cluster_mapping,hwys[k])
                hwys[k] = hwy_cluster_mapping[hwys[k]]
            end
        end
        inter.highways = Set(hwys)
    end

    # Group intersections by number of streets contained
    hwy_counts = Vector{Int}[]
    for (node,inter) in intersections
        hwy_cnt = length(inter.highways)
        if hwy_cnt > length(hwy_counts)
            for k = (length(hwy_counts)+1):hwy_cnt
                push!(hwy_counts,Int[])
            end
        end
        push!(hwy_counts[hwy_cnt], node)
    end

    clusters = Set{Int}[]                   # Array of sets of highway IDs in each cluster
    clusters_nodes = Set{Int}[]             # Array of sets of node IDs in each cluster
    intersection_mapping = Dict{Int,Int}()  # [intersection id => index in `clusters`]

    for kk = 1:(length(hwy_counts)-1)
        # Start with intersections with most highways, as they are the best 
        # "seeds" for new clusters because all intersection nodes added to the cluster 
        # must have their highways be a subset of the highways already in the cluster.
        # Skip checking intersections with only 1 highway (road ends)
        k = length(hwy_counts)+1-kk

        for inter in hwy_counts[k]
            found = false
            for index = 1:length(clusters)
                if issubset(intersections[inter].highways,clusters[index])
                    # Check distance to cluster centroid
                    c = centroid(nodes,[clusters_nodes[index]...])
                    c_dist = distance(c,nodes[inter])
                    if c_dist < max_dist
                        intersection_mapping[inter] = index
                        clusters_nodes[index] = Set([clusters_nodes[index]...,inter])
                        found = true
                        break
                    end
                end
            end
            if !found
                push!(clusters,intersections[inter].highways)
                push!(clusters_nodes,Set(inter))
                intersection_mapping[inter] = length(clusters)
            end
        end
    end

    # Create new node at centroid of each intersection cluster
    cluster_map = Dict{Int,Int}()   # [Intersection Node ID => Cluster Node ID]
    for k = 1:length(clusters_nodes)
        if length(clusters_nodes[k]) > 1
            n = [clusters_nodes[k]...]
            c = centroid(nodes,n)
            cluster_node_id = addNewNode!(nodes,c)

            for j = 1:length(n)
                cluster_map[n[j]] = cluster_node_id
            end
        end
    end

    return cluster_map
end


### Replace Nodes in Highways Using Node Remapping
function replaceHighwayNodes!( highways::Dict{Int,Highway}, node_map::Dict{Int,Int} )
    for (key,hwy) in highways
        all_equal = true
        for k = 1:length(hwy.nodes)
            if haskey(node_map,hwy.nodes[k])
                hwy.nodes[k] = node_map[hwy.nodes[k]]
            end

            if k > 1 && hwy.nodes[k] != hwy.nodes[k-1]
                all_equal = false
            end
        end

        # If all nodes in hwy are now equal, delete it.
        if all_equal
            delete!(highways,key)
        end
    end
    return nothing
end


