module OpenStreetMap2

using LibExpat
using LightGraphs
using Plots
using SparseArrays

export WGS84, OSGB36, NAD27 # Coordinate systems constants
export distance, getX, getY, getZ  # Auxiliary functions to calculate distances and get coordinates of points
export center, inbounds, onbounds, boundary_point #Functions for map bounds
export ECEF, LLA, ENU #Conversion functions
export parseOSM #parsing XML file
export extract_highways, filter_highways #Highways extraction 
export filter_roadways, classify_roadways,  filter_walkways, classify_walkways, filter_cycleways, classify_cycleways #Filtering and classification of cars, cycles and pedestrian Highways
export extract_buildings, filter_buildings, classify_buildings #Building extraction, filtering and classification 
export filter_features, filter_features!, classify_features, filter_graph_features #Features filtering and classification
export crop! #crop map elements
export nearest_node, nodes_within_range, centroid #Nodes functions
export find_intersections, find_segments #Get intersections or segments of the road
export create_graph #Create a routing network
export features_to_graph, find_optimal_waypoint_approx, find_optimal_waypoint_exact
export find_route, shortest_route, fastest_route #Routing funcions
export nodes_within_weights, nodes_within_driving_distance, nodes_within_driving_time #Find nodes within specified range
export plotmap, addroute! #Plotting

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
