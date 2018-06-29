### Julia OpenStreetMap Package ###
### MIT License                 ###
### Copyright 2014              ###

type Highway
    @compat class::AbstractString       # Type of highway
    lanes::Int          # Number of lanes (1 if unspecified)
    oneway::Bool        # True if road is one-way
    @compat sidewalk::AbstractString    # Sidewalk classifier, if available
    @compat cycleway::AbstractString    # Cycleway classifier, if available
    @compat bicycle::AbstractString     # Bicycle classifier, if available
    @compat name::AbstractString        # Name, if available
    nodes::Vector{Int}  # List of nodes
end

type Segment
    node0::Int          # Source node ID
    node1::Int          # Target node ID
    nodes::Vector{Int}  # List of nodes falling within node0 and node1
    dist::Real          # Length of the segment
    class::Int          # Class of the segment
    parent::Int         # ID of parent highway
    oneway::Bool        # True if road is one-way
end

type Feature
    @compat class::AbstractString       # Shop, amenity, crossing, etc.
    @compat detail::AbstractString      # Class qualifier
    @compat name::AbstractString        # Name
end

type Building
    @compat class::AbstractString       # Building type (usually "yes")
    @compat name::AbstractString        # Building name (usually unavailable)
    nodes::Vector{Int}  # List of nodes
end

type Intersection
    highways::Set{Int}  # Set of highway IDs
end
Intersection() = Intersection(Set{Int}())

type HighwaySet # Multiple highways representing a single "street" with a common name
    highways::Set{Int}
end

# Transporation network graph data and helpers to increase routing speed (do koniecznej zmiany)
type Network
    g                                   # Graph object
    v::Dict{Int,Int}  					# (node id) => (graph vertex)
    w::Vector{Float64}                  # Edge weights, indexed by edge id
	e::Array{Tuple{Int64,Int64},1}     	#edges in graph, stored as a tuple (source,destination)
    class::Vector{Int}                 	# Road class of each edge
	
end

### Rendering style data (tu moze zmienic bedzie trzeba)
type Style
    @compat color::UInt32
    width::Real
    @compat spec::AbstractString
end
Style(x, y) = Style(x, y, "-")
