"""
	parse_element(handler::LibExpat.XPStreamHandler,
                      name::AbstractString,
                      attr::Dict{AbstractString,AbstractString})

Parse Elements of Map
"""
function parse_element(handler::LibExpat.XPStreamHandler,
                      name::AbstractString,
                      attr::Dict{AbstractString,AbstractString})
    data = handler.data::OpenStreetMapX.DataHandle
    if name == "node"
        data.element = :Tuple
        data.node = (parse(Int, attr["id"]),
                         OpenStreetMapX.LLA(parse(Float64,attr["lat"]), parse(Float64,attr["lon"])))
    elseif name == "way"
        data.element = :Way
        data.way = OpenStreetMapX.Way(parse(Int, attr["id"]))
    elseif name == "relation"
        data.element = :Relation
        data.relation = OpenStreetMapX.Relation(parse(Int, attr["id"]))
    elseif name == "bounds"
        data.element =:Bounds
        data.bounds = OpenStreetMapX.Bounds(parse(Float64,attr["minlat"]), parse(Float64,attr["maxlat"]), parse(Float64,attr["minlon"]), parse(Float64,attr["maxlon"]))
    elseif name == "tag"
        k = attr["k"]; v = attr["v"]
        if  data.element == :Tuple
            tag(data.osm, handler.data.node[1], k, v)
		elseif data.element == :Way
            tag(data.osm, data.way, k, v)
        elseif data.element == :Relation
            tag(data.osm, data.relation, k, v)
        end
    elseif name == "nd"
        push!(data.way.nodes, parse(Int, attr["ref"]))
    elseif name == "member"
        push!(data.relation.members, attr)
    end
end

function collect_element(handler::LibExpat.XPStreamHandler, name::AbstractString)
    if name == "node"
        handler.data.osm.nodes[handler.data.node[1]] = handler.data.node[2]
        handler.data.element = :None
    elseif name == "way"
        push!(handler.data.osm.ways, handler.data.way)
        handler.data.element = :None
    elseif name == "relation"
        push!(handler.data.osm.relations, handler.data.relation)
        handler.data.element = :None
    elseif name == "bounds"
        handler.data.osm.bounds = handler.data.bounds
		handler.data.element = :None
    end
end

function parseOSM(filename::AbstractString; args...)::OpenStreetMapX.OSMData
    callbacks = LibExpat.XPCallbacks()
    callbacks.start_element = parse_element
    callbacks.end_element = collect_element
    data = OpenStreetMapX.DataHandle()
    LibExpat.parsefile(filename, callbacks, data=data; args...)
    data.osm
end



"""
    get_map_data(filepath::String,filename::Union{String,Nothing}=nothing;
	             road_levels::Set{Int} = Set(1:length(OpenStreetMapX.ROAD_CLASSES)),
				 use_cache::Bool = true, only_intersections::Bool=true)::MapData

High level function - parses .osm file and create the road network based on the map data.
This code currently can parse both *.osm and *.pbf (@blegat - thank you!) files. The data type is determined by file extension.

**Arguments**

* `filepath` : path with an .osm/.pbf file (directory or path to a file)
* `filename` : name of the file (when the first argument is a directory)
* `road_levels` : a set with the road categories (see: OpenStreetMapX.ROAD_CLASSES for more informations)
* `use_cache` : a *.cache file will be crated with a serialized map image in the `datapath` folder
* `only_intersections` : include only road system data
* `trim_to_connected_graph`: trim orphan nodes in such way that the map is a strongly connected graph
"""
function get_map_data(filepath::String,filename::Union{String,Nothing}=nothing; road_levels::Set{Int} = Set(1:length(OpenStreetMapX.ROAD_CLASSES)),
		use_cache::Bool = true,only_intersections::Bool = true, trim_to_connected_graph::Bool=false)::MapData
    #preprocessing map file
    datapath = (filename==nothing) ? dirname(filepath) : filepath;
	if filename == nothing
		filename = basename(filepath)
	end
	cachefile = joinpath(datapath,filename*".cache")
	if use_cache && isfile(cachefile)
		f=open(cachefile,"r");
		res=Serialization.deserialize(f);
		close(f);
		@info "Read map data from cache $cachefile"
	else
		path = joinpath(datapath, filename)
		if endswith(filename, ".pbf")
		    mapdata = OpenStreetMapX.parsePBF(path)
		else
		    mapdata = OpenStreetMapX.parseOSM(path)
		end
		OpenStreetMapX.crop!(mapdata,crop_relations = false)
		res = MapData(mapdata, road_levels, only_intersections; trim_to_connected_graph=trim_to_connected_graph)
		if use_cache
			f=open(cachefile,"w");
			Serialization.serialize(f,res);
			@info "Saved map data to cache $cachefile"
			close(f);
		end
	end
    return res
end

"""
	get_vertices_and_graph_nodes(edges::Vector{Tuple{Int,Int}})

Get Vertices and nodes for a set of `edges`
"""
function get_vertices_and_graph_nodes(edges::Vector{Tuple{Int,Int}})
    graph_nodes = unique(reinterpret(Int, edges))
	vertices = Dict{Int,Int}(zip(graph_nodes, 1:length(graph_nodes)))
	return vertices, graph_nodes
end

"""
	MapData(mapdata::OSMData, road_levels::Set{Int}, only_intersections::Bool=true; trim_to_connected_graph::Bool=false, remove_nodes::AbstractSet{Int}=Set{Int}())

Internal constructor of `MapData` object
"""
function MapData(mapdata::OSMData, road_levels::Set{Int}, only_intersections::Bool=true;
	 trim_to_connected_graph::Bool=false, remove_nodes::AbstractSet{Int}=Set{Int}())
	#preparing data
	roadways = filter(Base.Fix2(valid_roadway, road_levels), mapdata.ways)
	if !isempty(remove_nodes)
		for way in roadways
			filter!(node -> !(node in remove_nodes), way.nodes)
		end
		filter!(way -> !isempty(way.nodes), roadways)
	end

	nodes = Dict{Int,ENU}()
	lla_ref = OpenStreetMapX.center(mapdata.bounds)
	for way in roadways # TODO use `intersections` instead of `roadways` if `only_intersections` ?
		for node in way.nodes
			if !haskey(nodes, node)
				nodes[node] = ENU(mapdata.nodes[node], lla_ref)
			end
		end
	end

	intersections = OpenStreetMapX.find_intersections(roadways)

	# e - Edges in graph, stored as a tuple (source,destination)
	# class - Road class of each edgey
	if only_intersections && !trim_to_connected_graph
		e, class, weight_vals = get_edges_distances(nodes, roadways, intersections)
	else
		e, class = OpenStreetMapX.get_edges(nodes,roadways)
		weight_vals = OpenStreetMapX.distance(nodes,e)
	end
	# (node id) => (graph vertex)
	v, n = OpenStreetMapX.get_vertices_and_graph_nodes(e)
	edges = [v[id] for id in reinterpret(Int, e)]
	I = edges[1:2:end]
	J = edges[2:2:end]
	# w - Edge weights, indexed by graph id
	w = SparseArrays.sparse(I, J, weight_vals, length(v), length(v))
	g = Graphs.DiGraph(length(v))
	for edge in e
		add_edge!(g,v[edge[1]], v[edge[2]])
	end

	if trim_to_connected_graph
		conn_components = sort!(Graphs.strongly_connected_components(g),
			lt=(x,y)->length(x)<length(y), rev=true)
		remove_nodes = Set{Int}()
		I = 2:length(conn_components)
		sizehint!(remove_nodes, sum(i -> length(conn_components[i]), I))
		for i in I
			for node in conn_components[i]
				push!(remove_nodes, n[node])
			end
		end
		return MapData(mapdata, road_levels, only_intersections, remove_nodes=remove_nodes)
	else
		return MapData(mapdata.bounds,nodes,roadways,intersections,g,v,n,e,w,class)
	end
end

const __SAMPLE_MAP = Ref{MapData}()

"""
	sample_map_path()

Produces a path to a sample map file.
"""
function sample_map_path()
	joinpath(dirname(pathof(OpenStreetMapX)),"..","test/data/reno_east3.osm")
end

"""
	sample_map()

Produces a MapData object in a lazy loaded way.
"""
function sample_map()
	if !isdefined(OpenStreetMapX.__SAMPLE_MAP, 1)
		map_file_path = sample_map_path()
		OpenStreetMapX.__SAMPLE_MAP[] = get_map_data(map_file_path, use_cache=false)
	end
	deepcopy(OpenStreetMapX.__SAMPLE_MAP[])
end