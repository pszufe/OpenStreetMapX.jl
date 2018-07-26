#############################
### Parse Elements of Map ###
#############################

function parseElement(handler::LibExpat.XPStreamHandler,
                      name::AbstractString,
                      attr::Dict{AbstractString,AbstractString})
    data = handler.data::DataHandle
    if name == "node"
        data.element = :Tuple
        data.node = (parse(Int, attr["id"]),
                         LLA(float(attr["lat"]), float(attr["lon"])))
    elseif name == "way"
        data.element = :Way
        data.way = Way(parse(Int, attr["id"]))
    elseif name == "relation"
        data.element = :Relation
        data.relation = Relation(parse(Int, attr["id"]))
    elseif name == "bounds"
        data.element =:Bounds
        data.bounds = Bounds(float(attr["minlat"]), float(attr["maxlat"]), float(attr["minlon"]), float(attr["maxlon"]))
    elseif name == "tag" 
        k = attr["k"]; v = attr["v"]
        if  data.element == :Tuple
			if haskey(FEATURE_CLASSES, k)
				data.osm.features[handler.data.node[1]] = k,v
			end
		elseif data.element == :Way
            data_tags = tags(data.way)
            push!(data.osm.way_tags, k)
			data_tags[k] = v
        elseif data.element == :Relation
            data_tags = tags(data.relation)
            push!(data.osm.relation_tags, k)
			data_tags[k] = v
        end
    elseif name == "nd"
        push!(data.way.nodes, parse(Int, attr["ref"]))
    elseif name == "member"
        push!(data.relation.members, attr)
    end
end

function collectElement(handler::LibExpat.XPStreamHandler, name::AbstractString)
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

function parseOSM(filename::AbstractString; args...)
    callbacks = LibExpat.XPCallbacks()
    callbacks.start_element = parseElement
    callbacks.end_element = collectElement
    data = DataHandle()
    LibExpat.parsefile(filename, callbacks, data=data; args...)
    data.osm::OSMData
end



