"""
    get_distance(A::Int, B::Int, 
                 nodes::Dict{Int,T} , 
                 vertices_to_nodes::Dict{Int,Int}) where T<:Union{OpenStreetMapX.ENU,OpenStreetMapX.ECEF}
					
Auxiliary function - takes two vertices of graph and return the distance between them. 
Used to compute straight line distance heuristic for A* algorithm.

**Arguments**

* `A` : start vertex
* `B` : end vertex
* `nodes` : dictionary of .osm nodes ID's and correspoding points coordinates
* `vertices_to_nodes` : dictionary mapping graph vertices to .osm file nodes
"""
function get_distance(A::Int, B::Int, 
                     nodes::Dict{Int,T}, 
                     vertices_to_nodes::Dict{Int,Int}) where T<:Union{OpenStreetMapX.ENU,OpenStreetMapX.ECEF}
    A,B = vertices_to_nodes[A], vertices_to_nodes[B]
    OpenStreetMapX.distance(nodes[A],nodes[B])
end


function extract_a_star_route(parents::Vector{Int},s::Int, u::Int)
    route = Int[]
    index = u
    push!(route,index)
    while index != s
        index = parents[index]
        push!(route, index)
    end
    reverse!(route)
end

"""
    a_star_algorithm(g::AbstractGraph{U},  
                    s::Integer,                       
                    t::Integer,                       
                    distmx::AbstractMatrix{T}=LightGraphs.weights(g),
                    heuristic::Function = n -> zero(T)) where {T, U}

High level function - implementation of A star search algorithm:
(https://en.wikipedia.org/wiki/A*_search_algorithm). 
Based on the implementation in LightGraphs library, 
however significantly improved in terms of performance.

**Arguments**

* `g` : graph object
* `S` : start vertex
* `t` : end vertex
* `distmx` : distance matrix
* `heuristic` : search heuristic function; by default returns zero 
"""
function a_star_algorithm(g::LightGraphs.AbstractGraph{U},  # the g
                          s::Integer,           # the start vertex
                          t::Integer,           # the end vertex
                          distmx::AbstractMatrix{T}=LightGraphs.weights(g),
                          heuristic::Function = n -> zero(T)) where {T, U}
    checkbounds(distmx, Base.OneTo(nv(g)), Base.OneTo(nv(g)))
    frontier = DataStructures.PriorityQueue{Tuple{T, U},T}()
    frontier[(zero(T), U(s))] = zero(T)
    nvg = nv(g)
    visited = zeros(Bool, nvg)
    dists = fill(typemax(T), nvg)
    parents = zeros(U, nvg)
    colormap = zeros(UInt8, nvg)
    colormap[s] = 1
    @inbounds while !isempty(frontier)
        (cost_so_far, u) = dequeue!(frontier)
        u == t && (return OpenStreetMapX.extract_a_star_route(parents,s,u), cost_so_far)
        for v in LightGraphs.outneighbors(g, u)
            if get(colormap, v, 0) < 2
                dist = distmx[u, v]
                colormap[v] = 1
                path_cost = cost_so_far + dist
                if !visited[v] 
                    visited[v] = true
                    parents[v] = u
                    dists[v] = path_cost
                    enqueue!(frontier,
                            (path_cost, v),
                            path_cost + heuristic(v,t))
                elseif path_cost < dists[v]
                    parents[v] = u
                    dists[v] = path_cost
                    frontier[path_cost, v] = path_cost + heuristic(v,t)
                end
            end
        end
        colormap[u] = 2
    end
    Vector{U}(), Inf
end

"""
    a_star_algorithm(m::OpenStreetMapX.MapData,  
                    s::Integer,                       
                    t::Integer)
A star search algorithm with straight line distance heuristic

**Arguments**

* `m` : MapData object
* `S` : start vertex
* `t` : end vertex
* `distmx` : distance matrix
"""
function a_star_algorithm(m::OpenStreetMapX.MapData,  
                    s::Integer,                       
                    t::Integer)
    heuristic(u,v) = OpenStreetMapX.get_distance(u, v, m.nodes, m.n)
	OpenStreetMapX.a_star_algorithm(m.g,s,t,m.w,heuristic)
end