"""
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
Get Vertices and nodes for a set of `edges`
"""
function get_vertices_and_graph_nodes(edges::Vector{Tuple{Int,Int}})
    graph_nodes = unique(reinterpret(Int, edges))
	vertices = Dict{Int,Int}(zip(graph_nodes, 1:length(graph_nodes)))
	return vertices, graph_nodes
end

"""
Internal constructor of `MapData` object
"""
function MapData(mapdata::OSMData, road_levels::Set{Int}, only_intersections::Bool=true;
	 trim_to_connected_graph::Bool=false, remove_nodes::AbstractSet{Int}=Set{Int}())
	#preparing data
	bounds = mapdata.bounds
	nodes = OpenStreetMapX.ENU(mapdata.nodes,OpenStreetMapX.center(bounds))
	highways = OpenStreetMapX.filter_highways(OpenStreetMapX.extract_highways(mapdata.ways))
	roadways = OpenStreetMapX.filter_roadways(highways, levels= road_levels)
	if length(remove_nodes) > 0
		delete!.(Ref(nodes), remove_nodes);
		delcount = 0
		for rno in length(roadways):-1:1
			rr = roadways[rno]
			for i in length(rr.nodes):-1:1
				if rr.nodes[i] in remove_nodes
					deleteat!(rr.nodes,i)
					delcount += 1
				end
			end
			length(rr.nodes) == 0 && deleteat!(roadways, rno)
		end
	end
	intersections = OpenStreetMapX.find_intersections(roadways)
	segments = OpenStreetMapX.find_segments(nodes,roadways,intersections)
	#remove unuseful nodes
	roadways_nodes = unique(vcat(collect(way.nodes for way in roadways)...))
	nodes = Dict(key => nodes[key] for key in roadways_nodes)

	# e - Edges in graph, stored as a tuple (source,destination)
	# class - Road class of each edgey
	if only_intersections && !trim_to_connected_graph
		vals = Dict((segment.node0,segment.node1) => (segment.distance,segment.parent) for segment in segments)
		e = collect(keys(vals))
		vals = collect(values(vals))
		weight_vals = map(val -> val[1],vals)
		classified_roadways = OpenStreetMapX.classify_roadways(roadways)
		class =  [classified_roadways[id] for id in map(val -> val[2],vals)]
	else
		e,class = OpenStreetMapX.get_edges(nodes,roadways)
		weight_vals = OpenStreetMapX.distance(nodes,e)
	end
	# (node id) => (graph vertex)
	v, n = OpenStreetMapX.get_vertices_and_graph_nodes(e)
	edges = [v[id] for id in reinterpret(Int, e)]
	I = edges[1:2:end]
	J = edges[2:2:end]
	# w - Edge weights, indexed by graph id
	w = SparseArrays.sparse(I, J, weight_vals, length(v), length(v))
	g = LightGraphs.DiGraph(length(v))
	for edge in e
		add_edge!(g,v[edge[1]], v[edge[2]])
	end

	if trim_to_connected_graph
		rm_list = Set{Int}()
		conn_components = sort!(LightGraphs.strongly_connected_components(g),
        	lt=(x,y)->length(x)<length(y), rev=true)
		remove_vs = vcat(conn_components[2:end]...)
		rm_list = getindex.(Ref(n), remove_vs)
		return  MapData(mapdata, road_levels, only_intersections, remove_nodes=Set{Int}(rm_list))
	else
		return MapData(bounds,nodes,roadways,intersections,g,v,n,e,w,class)
	end
end
