###########################
### Auxiliary Functions ###
###########################

function hasLanes(w::Way)
    v = get(w.tags, "lanes", "")
    length(v)==1 && '1' <= v[1] <= '9'
end

getLanes(w::Way) = parse(Int, w.tags["lanes"])

visible{T <: OSMElement}(obj::T) = (get(obj.tags, "visible", "") != "false")

services(w::Way) = (get(w.tags,"highway", "") == "services")

########################
### Extract Highways ###
########################

extractHighways(ways::Vector{OpenStreetMap.Way}) = [way for way in ways if isdefined(way,:tags) && haskey(way.tags, "highway")]

filterHighways(ways::Vector{OpenStreetMap.Way}) = [way for way in ways if visible(way) && !services(way)]

##############################################
### Filter and Classify Highways for Cars ###
##############################################

filterRoadways(ways::Vector{OpenStreetMap.Way}, classes::Dict{String, Int} = OpenStreetMap.ROAD_CLASSES; levels::Set{Int} = Set(1:length(OpenStreetMap.ROAD_CLASSES))) = [way for way in ways if way.tags["highway"] in keys(classes) && classes[way.tags["highway"]] in levels]

classifyRoadways(ways::Vector{OpenStreetMap.Way}, classes::Dict{String, Int} = OpenStreetMap.ROAD_CLASSES) = Dict{Int,Int}(way.id => classes[way.tags["highway"]] for  way in ways if haskey(classes, way.tags["highway"]))

####################################################
### Filter and Classify Highways for Pedestrians ###
####################################################

function filterWalkways(ways::Vector{OpenStreetMap.Way},classes::Dict{String, Int} = OpenStreetMap.PED_CLASSES; levels::Set{Int} = Set(1:length(OpenStreetMap.PED_CLASSES)))
    walkways = OpenStreetMap.Way[]
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

function classifyWalkways(ways::Vector{OpenStreetMap.Way},classes::Dict{String, Int} = OpenStreetMap.PED_CLASSES)
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

function filterCycleways(ways::Vector{OpenStreetMap.Way}, classes::Dict{String, Int} = OpenStreetMap.CYCLE_CLASSES; levels::Set{Int} = Set(1:length(OpenStreetMap.CYCLE_CLASSES)))
    cycleways = OpenStreetMap.Way[]
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

function classifyCycleways(ways::Vector{OpenStreetMap.Way}, classes::Dict{String, Int} = OpenStreetMap.CYCLE_CLASSES)
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

extractBuildings(ways::Vector{OpenStreetMap.Way}) = [way for way in ways if isdefined(way,:tags) && haskey(way.tags, "building")]

filterBuildings(buildings::Vector{OpenStreetMap.Way}, classes::Dict{String, Int} = OpenStreetMap.BUILDING_CLASSES; levels::Set{Int} = Set(1:length(OpenStreetMap.BUILDING_CLASSES))) = [building for building in buildings if (building.tags["building"] in keys(classes)) && (classes[building.tags["building"]] in levels) && visible(building)]

classifyBuildings(buildings::Vector{OpenStreetMap.Way}, classes::Dict{String, Int} = OpenStreetMap.BUILDING_CLASSES) = Dict{Int,Int}(building.id => classes[building.tags["building"]] for  building in buildings if haskey(classes, building.tags["building"]))

#############################################
### Extract, Filter and Classify Features ###
#############################################

filterFeatures(features::Dict{Int,Tuple{String,String}}, classes::Dict{String, Int} = OpenStreetMap.FEATURE_CLASSES; levels::Set{Int} = Set(1:length(OpenStreetMap.FEATURE_CLASSES))) = Dict{Int,Tuple{String,String}}(key => feature for (key,feature) in features if classes[feature[1]] in levels)

function filterFeatures!(osmdata::OpenStreetMap.OSMData, classes::Dict{String, Int} = OpenStreetMap.FEATURE_CLASSES; levels::Set{Int} = Set(1:length(OpenStreetMap.FEATURE_CLASSES)))
	osmdata.features = filterFeatures(osmdata.features, levels, classes)
end

classifyFeatures(features::Dict{Int,Tuple{String,String}}, classes::Dict{String, Int} = OpenStreetMap.FEATURE_CLASSES) = Dict{Int,Int}(key =>  classes[feature[1]] for (key, feature) in features if haskey(classes, feature[1]))