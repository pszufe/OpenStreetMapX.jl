###########################
### Auxiliary Functions ###
###########################

function haslanes(w::OpenStreetMap2.Way)
    v = get(w.tags, "lanes", "")
    length(v)==1 && '1' <= v[1] <= '9'
end

getlanes(w::OpenStreetMap2.Way) = parse(Int, w.tags["lanes"])

visible(obj::T) where T <: OSMElement = (get(obj.tags, "visible", "") != "false") 

services(w::OpenStreetMap2.Way) = (get(w.tags,"highway", "") == "services")

########################
### Extract Highways ###
########################

extract_highways(ways::Vector{OpenStreetMap2.Way}) = [way for way in ways if isdefined(way,:tags) && haskey(way.tags, "highway")]

filter_highways(ways::Vector{OpenStreetMap2.Way}) = [way for way in ways if OpenStreetMap2.visible(way) && !OpenStreetMap2.services(way)]

##############################################
### Filter and Classify Highways for Cars ###
##############################################

filter_roadways(ways::Vector{OpenStreetMap2.Way}, classes::Dict{String, Int} = OpenStreetMap2.ROAD_CLASSES; levels::Set{Int} = Set(1:length(OpenStreetMap2.ROAD_CLASSES))) = [way for way in ways if way.tags["highway"] in keys(classes) && classes[way.tags["highway"]] in levels]

classify_roadways(ways::Vector{OpenStreetMap2.Way}, classes::Dict{String, Int} = OpenStreetMap2.ROAD_CLASSES) = Dict{Int,Int}(way.id => classes[way.tags["highway"]] for  way in ways if haskey(classes, way.tags["highway"]))

####################################################
### Filter and Classify Highways for Pedestrians ###
####################################################

function filter_walkways(ways::Vector{OpenStreetMap2.Way},classes::Dict{String, Int} = OpenStreetMap2.PED_CLASSES; levels::Set{Int} = Set(1:length(OpenStreetMap2.PED_CLASSES)))
    walkways = OpenStreetMap2.Way[]
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

function classify_walkways(ways::Vector{OpenStreetMap2.Way},classes::Dict{String, Int} = OpenStreetMap2.PED_CLASSES)
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

function filter_cycleways(ways::Vector{OpenStreetMap2.Way}, classes::Dict{String, Int} = OpenStreetMap2.CYCLE_CLASSES; levels::Set{Int} = Set(1:length(OpenStreetMap2.CYCLE_CLASSES)))
    cycleways = OpenStreetMap2.Way[]
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

function classify_cycleways(ways::Vector{OpenStreetMap2.Way}, classes::Dict{String, Int} = OpenStreetMap2.CYCLE_CLASSES)
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

extract_buildings(ways::Vector{OpenStreetMap2.Way}) = [way for way in ways if isdefined(way,:tags) && haskey(way.tags, "building")]

filter_buildings(buildings::Vector{OpenStreetMap2.Way}, classes::Dict{String, Int} = OpenStreetMap2.BUILDING_CLASSES; levels::Set{Int} = Set(1:length(OpenStreetMap2.BUILDING_CLASSES))) = [building for building in buildings if (building.tags["building"] in keys(classes)) && (classes[building.tags["building"]] in levels) && OpenStreetMap2.visible(building)]

classify_buildings(buildings::Vector{OpenStreetMap2.Way}, classes::Dict{String, Int} = OpenStreetMap2.BUILDING_CLASSES) = Dict{Int,Int}(building.id => classes[building.tags["building"]] for  building in buildings if haskey(classes, building.tags["building"]))

#############################################
### Extract, Filter and Classify Features ###
#############################################

filter_features(features::Dict{Int,Tuple{String,String}}, classes::Dict{String, Int} = OpenStreetMap2.FEATURE_CLASSES; levels::Set{Int} = Set(1:length(OpenStreetMap2.FEATURE_CLASSES))) = Dict{Int,Tuple{String,String}}(key => feature for (key,feature) in features if classes[feature[1]] in levels)

function filter_features!(osmdata::OpenStreetMap2.OSMData, classes::Dict{String, Int} = OpenStreetMap2.FEATURE_CLASSES; levels::Set{Int} = Set(1:length(OpenStreetMap2.FEATURE_CLASSES)))
	osmdata.features = filter_features(osmdata.features, classes, levels = levels)
end

classify_features(features::Dict{Int,Tuple{String,String}}, classes::Dict{String, Int} = OpenStreetMap2.FEATURE_CLASSES) = Dict{Int,Int}(key =>  classes[feature[1]] for (key, feature) in features if haskey(classes, feature[1]))

### filter features in graph ###

function filter_graph_features(features::Dict{Int,Tuple{String,String}}, graphFeatures::Dict{Int,Int},classes::Dict{String,Int},class::String)
    if !haskey(classes,class)
        error("class not in classes")
    end
    level = classes[class]
    Dict{Int,Int}(key => node for (key,node) in graphFeatures if classes[features[key][1]] == level) 
end