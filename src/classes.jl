### Julia OpenStreetMap Package ###
### MIT License                 ###
### Copyright 2014              ###

### The following dictionaries are used for grouping ways    ###
### into limited, discrete classes for routing and plotting. ###

# Ordered by typical significance
const ROAD_CLASSES = Dict(
    "motorway" => 1,
    "trunk" => 2,
    "primary" => 3,
    "secondary" => 4,
    "tertiary" => 5,
    "unclassified" => 6,
    "residential" => 6,
    "service" => 7,
    "motorway_link" => 1,
    "trunk_link" => 2,
    "primary_link" => 3,
    "secondary_link" => 4,
    "tertiary_link" => 5,
    "living_street" => 8,
    "pedestrian" => 8,
    "road" => 6)

# Level 1: Cycleways, walking paths, and pedestrian streets
# Level 2: Sidewalks
# Level 3: Pedestrians typically allowed but unspecified
# Level 4: Agricultural or horse paths, etc.
const PED_CLASSES = Dict(
    "cycleway" => 1,
    "pedestrian" => 1,
    "living_street" => 1,
    "footway" => 1,
    "sidewalk" => 2,
    "sidewalk:yes" => 2,
    "sidewalk:both" => 2,
    "sidewalk:left" => 2,
    "sidewalk:right" => 2,
    "steps" => 2,
    "path" => 3,
    "residential" => 3,
    "service" => 3,
    "secondary" => 4,
    "tertiary" => 4,
    "primary" => 4,
    "track" => 4,
    "bridleway" => 4,
    "unclassified" => 4)

# Level 1: Bike paths
# Level 2: Separated bike lanes (tracks)
# Level 3: Bike lanes
# Level 4: Bikes typically allowed but not specified
const CYCLE_CLASSES = Dict(
    "cycleway" => 1,
    "cycleway:track" => 2,
    "cycleway:opposite_track" => 2,
    "cycleway:lane" => 3,
    "cycleway:opposite" => 3,
    "cycleway:opposite_lane" => 3,
    "cycleway:shared" => 3,
    "cycleway:share_busway" => 3,
    "cycleway:shared_lane" => 3,
    "bicycle:use_sidepath" => 2,
    "bicycle:designated" => 2,
    "bicycle:permissive" => 3,
    "bicycle:yes" => 3,
    "bicycle:dismount" => 4,
    "residential" => 4,
    "pedestrian" => 4,
    "living_street" => 4,
    "service" => 4,
    "unclassified" => 4)

const FEATURE_CLASSES = Dict(
    "amenity" => 1,
    "shop" => 2,
    "building" => 3,
    "craft" => 4,
    "historic" => 5,
    "sport" => 6,
    "tourism" => 7)

# Class 1: Residential/Accomodation
# Class 2: Commercial
# Class 3: Civic/Amenity
# Class 4: Other
# Class 5: Unclassified ("yes")
const BUILDING_CLASSES = Dict(
    "accomodation" => 1,
    "apartments" => 1,
    "dormitory" => 1,
    "farm" => 1,
    "hotel" => 1,
    "house" => 1,
    "detached" => 1,
    "semidetached_house" => 1,
    "residential" => 1,
    "Residential" => 1,
    "terrace" => 1,
    "houseboat" => 1,
    "dwelling_house" => 1,
    "static_caravan" => 1,
    "ger" => 1,
    "commerical" => 2,
    "industrial" => 2,
    "retail" => 2,
    "warehouse" => 2,
    "supermarket" => 2,
    "manufacture" =>2,
    "factory" => 2,
    "administrative" => 3,
    "cathedral" => 3,
    "chapel" => 3,
    "church" => 3,
    "civic" => 3,
    "school" => 3,
    "kindergarten" => 3,
    "train_station" => 3,
    "transportation" => 3,
    "university" => 3,
    "pavilion" => 3,
    "public" => 3,
    "barn" => 4,
    "bridge" => 4,
    "bunker" => 4,
    "cabin" => 4,
    "construction" => 4,
    "cowshed" => 4,
    "farm_auxiliary" => 4,
    "garage" => 4,
    "garages" => 4,
    "greenhouse" => 4,
    "hangar" => 4,
    "hut" => 4,
    "roof" => 4,
    "semi" => 4,
    "shed" => 4,
    "stable" => 4,
    "storage_tank" => 4,
    "sty" => 4,
    "tank" => 4,
    "transformer_tower" => 4,
    "collapsed" => 4,
    "damaged" => 4,
    "ruins" => 4,
    "yes" => 5,
    "Yes" => 5)
