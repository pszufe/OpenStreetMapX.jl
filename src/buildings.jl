### Julia OpenStreetMap Package ###
### MIT License                 ###
### Copyright 2014              ###

### Classify buildings ###
function classify(buildings::Dict{Int,Building})
    bdgs = Dict{Int,Int}()

    for (key, building) in buildings
        if haskey(BUILDING_CLASSES, building.class)
            bdgs[key] = BUILDING_CLASSES[building.class]
        end
    end

    return bdgs
end
