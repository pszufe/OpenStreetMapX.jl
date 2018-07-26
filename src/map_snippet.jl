include("OpenStreetMap.jl")
using OpenStreetMap

function loadMapData(mapFileName)::OpenStreetMap.OSMData
    return parseOSM(mapFileName)
end

mutable struct RouteData
    shortest_route
    shortest_distance
    shortest_time
    fastest_route
    fastest_distance
    fastest_time
end

function findRoutes(pointA,pointB,mapD::OpenStreetMap.OSMData)::RouteData
    pointA = LLA(pointA[1],pointA[2])
    pointB = LLA(pointB[1],pointB[2])
    if !inBounds(pointA, mapD.bounds) && !inBounds(pointB, mapD.bounds)
        error("pointA or pointB not in the boundaries!")
    end
    #crop!(mapD,cropRelations = false)
    nodes = ENU(mapD.nodes, center(mapD.bounds))
    bounds = ENU(mapD.bounds, center(mapD.bounds))
    highways = filterHighways(extractHighways(mapD.ways))
    roadways = filterRoadways(highways, levels = Set(1:6))
    intersections = findIntersections(roadways)
    segments = findSegments(nodes,roadways,intersections)
    network = createGraph(segments, intersections, classifyRoadways(roadways))
    pointA = nearestNode(nodes, ENU(pointA , center(mapD.bounds)), network)
    pointB = nearestNode(nodes,  ENU(pointB , center(mapD.bounds)), network)
    shortest_route, shortest_distance, shortest_time = shortestRoute(network, pointA, pointB)
    fastest_route, fastest_distance, fastest_time = fastestRoute(network, pointA, pointB)
    return RouteData(shortest_route, shortest_distance, shortest_time,fastest_route, fastest_distance, fastest_time)
end

function generatePointInBounds(mapD::OpenStreetMap.OSMData)
    boundaries = mapD.bounds
    (rand() * (boundaries.max_y -  boundaries.min_y) + boundaries.min_y,
    rand() * (boundaries.max_x -  boundaries.min_x) + boundaries.min_x)
end
