__precompile__()
###################################
### Julia OpenStreetMap Package ###
### MIT License                 ###
### Copyright 2014              ###
###################################

module OpenStreetMap

#packages for parsing XML files:
using LightXML
using LibExpat

using Compat
using LightGraphs
using Winston


export ECEF, ENU, LLA # Points
export Bounds, Ellipsoid # Other types
export WGS84, OSGB36, NAD27 # Constants
export center, distance, getX, getY, getZ, inBounds  # Methods

export parseMapXML, getOSMData, getBounds #parsing XML file
export plotMap, add_route! #plotting
export cropMap! #removing unnecessary points (e.g. outside the bounds)
export findIntersections, findClassIntersections, nearestNode, segmentHighways, highwaySegments #finding roads intersections, segments, etc.
export roadways, walkways, cycleways, classify #classification of highways
export createGraph, shortestRoute, fastestRoute, routeEdges #creating a road network graph and finding shortest or fastest routes
export nodesWithinRange, nodesWithinDrivingDistance, nodesWithinDrivingTime
export findHighwaySets, findIntersectionClusters, replaceHighwayNodes!

include("types.jl") #types used in the package
include("classes.jl") #grouping highways into classes for routing and plotting
include("layers.jl")  #layers used in plotting
include("speeds.jl") # speed limits in kilometers per hour


include("points.jl") # points coordinates
include("bounds.jl") #bounds of the map
include("conversion.jl") #conversion of geographical coordinates
include("highways.jl") #highways classification functions
include("features.jl") #features classification functions
include("buildings.jl") #buildings classification functions

include("nodes.jl") #finding nearest nodes or nodes within some range
include("parseMap.jl") #map parsing funcions
include("crop.jl") #cropping nodes
include("plot.jl") #plotting
include("intersections.jl") #finding intersections
include("transforms.jl") #conversion of coordinates of points used in simulation
include("routing.jl") #routing functions

end
