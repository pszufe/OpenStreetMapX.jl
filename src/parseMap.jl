### Julia OpenStreetMap Package ###
### MIT License                 ###
### Copyright 2014              ###

type OSMattributes
    oneway::Bool
    oneway_override::Bool
    oneway_reverse::Bool
    visible::Bool
    lanes::Int

    name::String
    class::String
    detail::String
    cycleway::String
    sidewalk::String
    bicycle::String

    # XML elements
    element::Symbol # :None, :Node, :Way, :Tag[, :Relation]
    parent::Symbol # :Building, :Feature, :Highway
    way_nodes::Vector{Int} # for buildings and highways

    id::Int # Uninitialized
    lat::Float64 # Uninitialized
    lon::Float64 # Uninitialized

    OSMattributes() = new(false,false,false,false,1,
                          "","","","","","",:None,:None,[])
end

type OSMdata
    nodes::Dict{Int,LLA}
    highways::Dict{Int,Highway}
    buildings::Dict{Int,Building}
    features::Dict{Int,Feature}
    attr::OSMattributes
    OSMdata() = new(Dict(),Dict(),Dict(),Dict(),OSMattributes())
end

function reset_attributes!(osm::OSMattributes)
    osm.oneway = osm.oneway_override = osm.oneway_reverse = osm.visible = false
    osm.lanes = 1
    osm.name = osm.class = osm.detail = osm.cycleway = osm.sidewalk = osm.bicycle = ""
    osm.element = osm.parent = :None
    empty!(osm.way_nodes)
end

### PARSE XML ELEMENTS ###

function parse_node(attr::OSMattributes, attrs_in::Dict{@compat(AbstractString),@compat(AbstractString)})
    attr.visible = true
    attr.element = :Node
    if haskey(attrs_in, "id")
        attr.id = @compat( parse(Int,attrs_in["id"]) )
        attr.lat = float(attrs_in["lat"])
        attr.lon = float(attrs_in["lon"])
    end
end

function parse_way(attr::OSMattributes, attrs_in::Dict{@compat(AbstractString),@compat(AbstractString)})
    attr.visible = true
    attr.element = :Way
    if haskey(attrs_in, "id")
        attr.id = @compat( parse(Int,attrs_in["id"]) )
    end
end

function parse_nd(attr::OSMattributes, attrs_in::Dict{@compat(AbstractString),@compat(AbstractString)})
    if haskey(attrs_in, "ref")
        push!(attr.way_nodes, @compat( parse(Int64,attrs_in["ref"]) ) )
    end
end

function parse_tag(attr::OSMattributes, attrs_in::Dict{@compat(AbstractString),@compat(AbstractString)})
    if haskey(attrs_in, "k") && haskey(attrs_in, "v")
        k, v = attrs_in["k"], attrs_in["v"]
        if k == "name"
            if isempty(attr.name)
                attr.name = v # applicable to roads (highways), buildings, features
            end
        elseif attr.element == :Way
            if k == "building"
                parse_building(attr, v)
            else
                parse_highway(attr, k, v) # for other highway tags
            end
        elseif attr.element == :Node
            if haskey(FEATURE_CLASSES, k)
                parse_feature(attr, k, v)
            end
        end
    else
        # Nothing to be done here?
    end
end

### PARSE OSM ENTITIES ###

function parse_highway(attr::OSMattributes, k::@compat(AbstractString), v::@compat(AbstractString))
    if k == "highway"
        attr.class = v
        if v == "services" # Highways marked "services" are not traversable
            attr.visible = false
            return
        end
        if v == "motorway" || v == "motorway_link"
            attr.oneway = true # motorways default to oneway
        end
    elseif k == "oneway"
        if v == "-1"
            attr.oneway = true
            attr.oneway_reverse = true
        elseif v == "false" || v == "no" || v == "0"
            attr.oneway = false
            attr.oneway_override = true
        elseif v == "true" || v == "yes" || v == "1"
            attr.oneway = true
        end
    elseif k == "junction" && v == "roundabout"
        attr.oneway = true
    elseif k == "cycleway"
        attr.cycleway = v
    elseif k == "sidewalk"
        attr.sidewalk = v
    elseif k == "bicycle"
        attr.bicycle = v
    elseif k == "lanes" && length(v)==1 && '1' <= v[1] <= '9'
        attr.lanes = @compat parse(Int,v)
    else
        return
    end
    attr.parent = :Highway
end

function parse_building(attr::OSMattributes, v::@compat(AbstractString))
    attr.parent = :Building
    if isempty(attr.class)
        attr.class = v
    end
end

function parse_feature(attr::OSMattributes, k::@compat(AbstractString), v::@compat(AbstractString))
    attr.parent = :Feature
    attr.class = k
    attr.detail = v
end

### LibExpat.XPStreamHandlers ###

function parseElement(handler::LibExpat.XPStreamHandler, name::@compat(AbstractString), attrs_in::Dict{@compat(AbstractString),@compat(AbstractString)})
    attr = handler.data.attr::OSMattributes
    if attr.visible
        if name == "nd"
            parse_nd(attr, attrs_in)
        elseif name == "tag"
            parse_tag(attr, attrs_in)
        end
    elseif !(haskey(attrs_in, "visible") && attrs_in["visible"] == "false")
        if name == "node"
            parse_node(attr, attrs_in)
        elseif name == "way"
            parse_way(attr, attrs_in)
        end
    end # no work done for "relations" yet
end

function collectValues(handler::LibExpat.XPStreamHandler, name::@compat(AbstractString))
    # println(typeof(name))
    osm = handler.data::OSMdata
    attr = osm.attr::OSMattributes
    if name == "node"
        osm.nodes[attr.id] = LLA(attr.lat, attr.lon)
        if attr.parent == :Feature
            osm.features[attr.id] = Feature(attr.class, attr.detail, attr.name)
        end
    elseif name == "way"
        if attr.parent == :Building
            osm.buildings[attr.id] = Building(attr.class, attr.name, copy(attr.way_nodes))
        elseif attr.parent == :Highway
            if attr.oneway_reverse
                reverse!(attr.way_nodes)
            end
            osm.highways[attr.id] = Highway(attr.class, attr.lanes,
                                            (attr.oneway && !attr.oneway_override),
                                            attr.sidewalk, attr.cycleway, attr.bicycle,
                                            attr.name, copy(attr.way_nodes))
        end
    else # :Tag or :Nd (don't reset values!)
        return
    end
    reset_attributes!(osm.attr)
end

### Parse the data from an openStreetMap XML file ###
function parseMapXML(filename::@compat(AbstractString))

    # Parse the file
    street_map = LightXML.parse_file(filename)

    if LightXML.name(LightXML.root(street_map)) != "osm"
        throw(ArgumentError("Not an OpenStreetMap datafile."))
    end

    return street_map
end

function getOSMData(filename::@compat(AbstractString); args...)
    osm = OSMdata()

    callbacks = LibExpat.XPCallbacks()
    callbacks.start_element = parseElement
    callbacks.end_element = collectValues

    LibExpat.parsefile(filename, callbacks, data=osm; args...)
    osm.nodes, osm.highways, osm.buildings, osm.features
end
