###########################
### Auxiliary Functions ###
###########################

function haslanes(w::OpenStreetMapX.Way)
    v = get(w.tags, "lanes", "")
    length(v)==1 && '1' <= v[1] <= '9'
end

getlanes(w::OpenStreetMapX.Way) = parse(Int, w.tags["lanes"])

visible(obj::T) where T <: OSMElement = (get(obj.tags, "visible", "") != "false")

services(w::OpenStreetMapX.Way) = (get(w.tags,"highway", "") == "services")

"""""
    extract_highways(ways::Vector{OpenStreetMapX.Way})

Extract Highways
"""
extract_highways(ways::Vector{OpenStreetMapX.Way}) = [way for way in ways if isdefined(way,:tags) && haskey(way.tags, "highway")]

"""
    filter_highways(ways::Vector{OpenStreetMapX.Way})

"""
filter_highways(ways::Vector{OpenStreetMapX.Way}) = [way for way in ways if OpenStreetMapX.visible(way) && !OpenStreetMapX.services(way)]

###
## Filter and Classify Highways for Cars
###
"""
    valid_roadway(way, levels::Set{Int}, classes::Dict{String, Int} = OpenStreetMapX.ROAD_CLASSES)
"""
function valid_roadway(way, levels::Set{Int}, classes::Dict{String, Int} = OpenStreetMapX.ROAD_CLASSES)
    highway = get(way.tags, "highway", "")
    if isempty(highway) || highway == "services" || !haskey(classes, highway)
        return false
    end
    return OpenStreetMapX.visible(way) && classes[highway] in levels
end

filter_roadways(ways::Vector{OpenStreetMapX.Way}, classes::Dict{String, Int} = OpenStreetMapX.ROAD_CLASSES; levels::Set{Int} = Set(1:length(OpenStreetMapX.ROAD_CLASSES))) = [way for way in ways if way.tags["highway"] in keys(classes) && classes[way.tags["highway"]] in levels]

classify_roadway(way::Way, classes::Dict{String, Int} = OpenStreetMapX.ROAD_CLASSES) = classes[way.tags["highway"]]
classify_roadways(ways::Vector{OpenStreetMapX.Way}, classes::Dict{String, Int} = OpenStreetMapX.ROAD_CLASSES) = Dict{Int,Int}(way.id => classify_roadway(way, classes) for way in ways if haskey(classes, way.tags["highway"]))


"""
    filter_walkways(ways::Vector{OpenStreetMapX.Way},
                    classes::Dict{String, Int} = OpenStreetMapX.PED_CLASSES;
                    levels::Set{Int} = Set(1:length(OpenStreetMapX.PED_CLASSES)))

Filters a vector of ways to include only those that are relevant for pedestrian walkways.
It considers the presence of a "sidewalk" tag and checks if the corresponding value or the "highway" tag value
is present in the specified classes dictionary and levels set.

**Arguments**

* `ways::Vector{OpenStreetMapX.Way}` : Way's vector
* `classes` : classes dictionary
* `levels` : set of levels useful to compare with the way tags

"""
function filter_walkways(ways::Vector{OpenStreetMapX.Way},classes::Dict{String, Int} = OpenStreetMapX.PED_CLASSES; levels::Set{Int} = Set(1:length(OpenStreetMapX.PED_CLASSES)))
    walkways = OpenStreetMapX.Way[]
    for way in ways
        sidewalk = get(way.tags, "sidewalk", "")
        if sidewalk != "no"
            if haskey(classes, "sidewalk:$(sidewalk)") && classes["sidewalk:$(sidewalk)"] in levels
                push!(walkways,way)
            elseif haskey(classes, way.tags["highway"]) && classes[way.tags["highway"]] in levels
                push!(walkways,way)
            end
        end
    end
    return walkways
end

"""
    classify_walkways(ways::Vector{OpenStreetMapX.Way},
                      classes::Dict{String, Int} = OpenStreetMapX.PED_CLASSES)

Classifies a vector of OpenStreetMapX ways based on their pedestrian attributes.
It considers the presence of a "sidewalk" tagand checks if the corresponding value or the "highway" tag value
is present in the specified classes dictionary

**Arguments**

* `ways::Vector{OpenStreetMapX.Way}` : Way's vector
* `classes` : classes dictionary

"""
function classify_walkways(ways::Vector{OpenStreetMapX.Way},classes::Dict{String, Int} = OpenStreetMapX.PED_CLASSES)
    walkways = Dict{Int,Int}()
    for way in ways
        sidewalk = get(way.tags, "sidewalk", "")
        if sidewalk != "no"
            if haskey(classes, "sidewalk:$(sidewalk)")
                walkways[way.id] = classes["sidewalk:$(sidewalk)"]
            elseif haskey(classes, way.tags["highway"])
                walkways[way.id] = classes[way.tags["highway"]]
            end
        end
    end
    return walkways
end

###############################################
### Filter and Classify Highways for Cycles ###
###############################################

"""
    filter_cycleways(ways::Vector{OpenStreetMapX.Way},
                    classes::Dict{String, Int} = OpenStreetMapX.CYCLE_CLASSES;
                    levels::Set{Int} = Set(1:length(OpenStreetMapX.CYCLE_CLASSES)))

Filters a vector of OpenStreetMapX ways to include only those that are relevant for cycleways.
It considers the presence of "bicycle", "cycleway", and "highway" tags and checks if the corresponding values
or the constructed class strings are present in the specified classes dictionary and levels set.

**Arguments**

* `ways::Vector{OpenStreetMapX.Way}` : Way's vector
* `classes` : classes dictionary
* `levels` : set of levels useful to compare with the way tags

"""
function filter_cycleways(ways::Vector{OpenStreetMapX.Way}, classes::Dict{String, Int} = OpenStreetMapX.CYCLE_CLASSES; levels::Set{Int} = Set(1:length(OpenStreetMapX.CYCLE_CLASSES)))
    cycleways = OpenStreetMapX.Way[]
    for way in ways
        bicycle = get(way.tags, "bicycle", "")
        cycleway = get(way.tags, "cycleway", "")
        highway = get(way.tags, "highway", "")

        cycleclass = "cycleway:$(cycleway)"
        bikeclass = "bicycle:$(bicycle)"

        if bicycle != "no"
            if haskey(classes, cycleclass) && classes[cycleclass] in levels
                push!(cycleways, way)
            elseif haskey(classes, bikeclass) && classes[bikeclass] in levels
                push!(cycleways, way)
            elseif haskey(classes, highway) && classes[highway] in levels
                push!(cycleways, way)
            end
        end
    end
    return cycleways
end

"""
    classify_cycleways(ways::Vector{OpenStreetMapX.Way},
                       classes::Dict{String, Int} = OpenStreetMapX.CYCLE_CLASSES)

Classifies a vector of OpenStreetMapX ways based on their cycleway attributes.
It considers the presence of "bicycle", "cycleway", and "highway" tags and checks if the corresponding values
or the constructed class strings are present in the specified classes dictionary.

**Arguments**

* `ways::Vector{OpenStreetMapX.Way}` : Way's vector
* `classes` : classes dictionary

"""
function classify_cycleways(ways::Vector{OpenStreetMapX.Way}, classes::Dict{String, Int} = OpenStreetMapX.CYCLE_CLASSES)
    cycleways = Dict{Int,Int}()
    for way in ways
        bicycle = get(way.tags, "bicycle", "")
        cycleway = get(way.tags, "cycleway", "")
        highway = get(way.tags, "highway", "")

        cycleclass = "cycleway:$(cycleway)"
        bikeclass = "bicycle:$(bicycle)"

        if bicycle != "no"
            if haskey(classes, cycleclass)
                cycleways[way.id] = classes[cycleclass]
            elseif haskey(classes, bikeclass)
                cycleways[way.id] = classes[bikeclass]
            elseif haskey(classes, highway)
                cycleways[way.id] = classes[highway]
            end
        end
    end
    return cycleways
end

##############################################
### Extract, Filter and Classify Buildings ###
##############################################

extract_buildings(ways::Vector{OpenStreetMapX.Way}) = [way for way in ways if isdefined(way,:tags) && haskey(way.tags, "building")]

filter_buildings(buildings::Vector{OpenStreetMapX.Way}, classes::Dict{String, Int} = OpenStreetMapX.BUILDING_CLASSES; levels::Set{Int} = Set(1:length(OpenStreetMapX.BUILDING_CLASSES))) = [building for building in buildings if (building.tags["building"] in keys(classes)) && (classes[building.tags["building"]] in levels) && OpenStreetMapX.visible(building)]

classify_buildings(buildings::Vector{OpenStreetMapX.Way}, classes::Dict{String, Int} = OpenStreetMapX.BUILDING_CLASSES) = Dict{Int,Int}(building.id => classes[building.tags["building"]] for  building in buildings if haskey(classes, building.tags["building"]))

#############################################
### Extract, Filter and Classify Features ###
#############################################

filter_features(features::Dict{Int,Tuple{String,String}}, classes::Dict{String, Int} = OpenStreetMapX.FEATURE_CLASSES; levels::Set{Int} = Set(1:length(OpenStreetMapX.FEATURE_CLASSES))) = Dict{Int,Tuple{String,String}}(key => feature for (key,feature) in features if classes[feature[1]] in levels)

function filter_features!(osmdata::OpenStreetMapX.OSMData, classes::Dict{String, Int} = OpenStreetMapX.FEATURE_CLASSES; levels::Set{Int} = Set(1:length(OpenStreetMapX.FEATURE_CLASSES)))
	osmdata.features = filter_features(osmdata.features, classes, levels = levels)
end

classify_features(features::Dict{Int,Tuple{String,String}}, classes::Dict{String, Int} = OpenStreetMapX.FEATURE_CLASSES) = Dict{Int,Int}(key =>  classes[feature[1]] for (key, feature) in features if haskey(classes, feature[1]))

### filter features in graph ###

function filter_graph_features(features::Dict{Int,Tuple{String,String}}, graphFeatures::Dict{Int,Int},classes::Dict{String,Int},class::String)
    if !haskey(classes,class)
        error("class not in classes")
    end
    level = classes[class]
    Dict{Int,Int}(key => node for (key,node) in graphFeatures if classes[features[key][1]] == level)
end
