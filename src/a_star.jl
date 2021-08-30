"""
    get_distance(A::Int, B::Int, 
                 nodes::Dict{Int,T} , 
                 vertices_to_nodes::Vector{Int}) where T<:Union{OpenStreetMapX.ENU,OpenStreetMapX.ECEF}
					
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
                     vertices_to_nodes::Vector{Int}) where T<:Union{OpenStreetMapX.ENU,OpenStreetMapX.ECEF}
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
                    heuristic::Function = (u,v) -> zero(T)) where {T, U}

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
                          heuristic::Function = (u,v) -> zero(T)) where {T, U}
    nvg = nv(g)
    checkbounds(distmx, Base.OneTo(nvg), Base.OneTo(nvg))
    frontier = DataStructures.PriorityQueue{U,T}()
    # The value should be `heuristic(s, t)` but it does not matter since it will
    # be `dequeue!`d in the first iteration independently of the value.
    frontier[U(s)] = zero(T)
    dists = fill(typemax(T), nvg)
    dists[s] = zero(T)
    parents = zeros(U, nvg)
    colormap = zeros(UInt8, nvg)
    colormap[s] = 1
    @inbounds while !isempty(frontier)
        u = dequeue!(frontier)
        cost_so_far = dists[u]
        u == t && (return OpenStreetMapX.extract_a_star_route(parents,s,u), cost_so_far)
        for v in LightGraphs.outneighbors(g, u)
            col = colormap[v]
            if col < UInt8(2)
                dist = distmx[u, v]
                colormap[v] = 1
                path_cost = cost_so_far + dist
                if iszero(col)
                    parents[v] = u
                    dists[v] = path_cost
                    enqueue!(frontier, v, path_cost + heuristic(v,t))
                elseif path_cost < dists[v]
                    parents[v] = u
                    dists[v] = path_cost
                    frontier[v] = path_cost + heuristic(v,t)
                end
            end
        end
        colormap[u] = 2
    end
    Vector{U}(), Inf
end

"""
    a_star_algorithm(m::MapData,  
                    s::Integer,                       
                    t::Integer)
A star search algorithm with straight line distance heuristic

**Arguments**

* `m` : MapData object
* `S` : start vertex
* `t` : end vertex
* `distmx` : distance matrix
"""
function a_star_algorithm(m::MapData,  
                    s::Integer,                       
                    t::Integer)
    heuristic(u,v) = OpenStreetMapX.get_distance(u, v, m.nodes, m.n)
	OpenStreetMapX.a_star_algorithm(m.g,s,t,m.w,heuristic)
end
