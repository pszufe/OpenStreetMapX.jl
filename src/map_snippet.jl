include("OpenStreetMap.jl")
using OpenStreetMap

struct MapData
    osmData
    bounds::OpenStreetMap.Bounds
end

function loadMapData(mapFileName)::MapData
    return MapData(getOSMData(mapFileName),getBounds(parseMapXML(mapFileName)))
end

mutable struct RouteData
    shortest_route
    shortest_distance
    shortest_time
    fastest_route
    fastest_distance
    fastest_time
    p
end
function findRoute(pointA,pointB,mapD::MapData, plotting = true, p = :none)::RouteData
    pointA = LLA(pointA[1],pointA[2])
    pointB = LLA(pointB[1],pointB[2])
    if !inBounds(pointA, mapD.bounds) && !inBounds(pointB, mapD.bounds)
        error("pointA or pointB not in the boundaries!")
    end

    nodes = ENU( mapD.osmData[1], center(mapD.bounds))
    highways = mapD.osmData[2]
    roads = roadways(highways)
    bounds = ENU( mapD.bounds, center(mapD.bounds))

    #cropMap!(nodes, bounds, highways=highways, buildings=mapD.osmData[3], features=mapD.osmData[4], delete_nodes=false)

    intersections = findClassIntersections(highways, roads)
    network = createGraph(segmentHighways(nodes, highways,  intersections, roads),intersections)
    pointA = nearestNode(nodes, ENU(pointA , center(mapD.bounds)), network)
    pointB = nearestNode(nodes,  ENU(pointB , center(mapD.bounds)), network)

    shortest_route, shortest_distance, shortest_time = shortestRoute(network, pointA, pointB)
    fastest_route, fastest_distance, fastest_time = fastestRoute(network, pointA, pointB)

    if plotting
        if p == :none
            p = plotMap(nodes, highways=highways, bounds=bounds, roadways=roads)
        end
        p = add_route!(p,nodes,fastest_route, "",route_color = 0xFF0000)
        p = add_route!(p,nodes,shortest_route, "", route_color = 0x000053)

    end
    #println("Shortest route: $(shortest_distance) m Time: $(shortest_time/60) min (Nodes: $(length(shortest_route)))")
    #println("Fastest route: $(fastest_distance) m  Time: $(fastest_time/60) min  (Nodes: $(length(fastest_route)))")
    return RouteData(shortest_route, shortest_distance, shortest_time,fastest_route, fastest_distance, fastest_time,p)
end

function generatePointInBounds(mapD::MapData)
    boundaries = mapD.bounds
    (rand() * (boundaries.max_y -  boundaries.min_y) + boundaries.min_y,
    rand() * (boundaries.max_x -  boundaries.min_x) + boundaries.min_x)
end
