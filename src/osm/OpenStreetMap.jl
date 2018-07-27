module OpenStreetMap

using LibExpat
using LightGraphs
using Winston

export WGS84, OSGB36, NAD27 # Coordinate systems constants
export distance, getX, getY, getZ  # Auxiliary functions to calculate distances and get coordinates of points
export center, inBounds, onBounds, boundaryPoint #Functions for map bounds
export ECEF, LLA, ENU #Conversion functions
export parseOSM #parsing XML file
export extractHighways, filterHighways #Highways extraction 
export filterRoadways, classifyRoadways,  filterWalkways, classifyWalkways, filterCycleways, classifyCycleways #Filtering and classification of cars, cycles and pedestrian Highways
export extractBuildings, filterBuildings, classifyBuildings #Building extraction, filtering and classification 
export filterFeatures, filterFeatures!, classifyFeatures #Features filtering and classification
export crop! #crop map elements
export nearestNode, nodesWithinRange, centroid #Nodes functions
export findIntersections, findSegments #Get intersections or segments of the road
export createGraph #Create a routing network
export findRoute, shortestRoute, fastestRoute #Routing funcions
export nodesWithinWeights, nodesWithinDrivingDistance, nodesWithinDrivingTime #Find nodes within specified range
export plotMap, addRoute! #Plotting

include("types.jl") #types used in the package
include("classes.jl") #grouping highways into classes for routing and plotting
include("layers.jl")  #layers used in plotting
include("speeds.jl") # speed limits in kilometers per hour

include("points.jl") # points coordinates and constants
include("bounds.jl") #bounds of the map
include("conversion.jl") #conversion of geographical coordinates

include("parseMap.jl") #map parsing funcions
include("classification.jl") #highways, features and buildings classification functions 
include("crop.jl") #cropping nodes and ways

include("nodes.jl") #finding nearest nodes or nodes within some range 
include("intersections.jl") #finding intersections
include("routing.jl") #routing functions
include("plot.jl") #plotting

end 
