### Julia OpenStreetMap Package ###
### MIT License                 ###
### Copyright 2014              ###

### Classify features ###
function classify(features::Dict{Int,Feature})
    feats = Dict{Int,Int}()

    for (key, feature) in features
        if haskey(FEATURE_CLASSES, feature.class)
            feats[key] = FEATURE_CLASSES[feature.class]
        end
    end

    return feats
end
