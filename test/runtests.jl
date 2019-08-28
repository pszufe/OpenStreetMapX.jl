using Test, OpenStreetMapX
import LightGraphs

@testset "maps" begin

m = get_map_data("data/reno_east3.osm",use_cache=false);


@test length(m.nodes) == 9032

using Random
Random.seed!(0);
pA = generate_point_in_bounds(m)
@test all(isapprox.(pA,(39.53584630184622, -119.71506095062803)))
pB = generate_point_in_bounds(m)
@test all(isapprox.(pB,(39.507242155639005, -119.78506509516248)))
pointA = point_to_nodes(pA, m)
pointB = point_to_nodes(pB, m)


@test pointA == 3052967037
@test pointB == 140393352


sr1, shortest_distance1, shortest_time1 = shortest_route(m, pointA, pointB)
@test (sr1[1], sr1[end]) == (pointA, pointB)

@test shortest_route(m, pointA, pointB; routing = :astar) == shortest_route(m, pointA, pointB; routing = :dijkstra)
@test fastest_route(m, pointA, pointB; routing = :astar) == fastest_route(m, pointA, pointB; routing = :dijkstra)

#######################################################
### nodes.jl ###
#nodes.jl/nearest_node
@test nearest_node(m.nodes, ENU(3300,1500,-1)) == 3052967130

#nodes.jl/centroid
node_list = [pointA,pointB]
@test centroid(m.nodes,node_list) == ENU(309.1010361600104, -35.35610349960848, -0.9191984126487114)

#nodes.jl/nodes_within_range
@test nodes_within_range(m.nodes, ENU(3300,1500,-1), 100.0) == [3052967037, 3052967180, 3052967130, 6050217400, 3052966904, 3052967140, 6050217409, 3052967199]

#nodes.jl/add_new_node!
@test haskey(m.nodes,-1) == false
OpenStreetMapX.add_new_node!(m.nodes,ENU(3300,1500,-1),-1)
@test length(m.nodes) == 9033
@test nearest_node(m.nodes,ENU(3300,1500,-1)) == -1

### intersections.jl ###
#intersections.jl/oneway
@test OpenStreetMapX.oneway(m.roadways[1]) == true

#intersections.jl/distance
@test distance(m.nodes,sr1) == 9019.07204040599

#intersections.jl/find_intersections
@test OpenStreetMapX.find_intersections(m.roadways[1:2]) == Dict(139988738=>Set([14370413]),2975020216=>Set([14370407]),2441017888=>Set([14370407]),385046328=>Set([14370413]))

### routing.jl ###
#routing.jl/get_edges
@test OpenStreetMapX.get_edges(m.nodes,m.roadways[1:2]) == (Tuple{Int64,Int64}[(139988738, 385046327), (2441017870, 2975020216), (385046327, 385046328), (2441017888, 2441017878), (2441017878, 2441017870)], [1, 4, 1, 4, 4])

#routing.jl/get_vertices
@test OpenStreetMapX.get_vertices(OpenStreetMapX.get_edges(m.nodes,m.roadways[1:2])[1]) == Dict(2441017878=>7,139988738=>1,2975020216=>4,2441017870=>3,385046328=>5,2441017888=>6,385046327=>2)

#routing.jl/distance
#Returns seem to be equal yet returning false (?)
@test distance(m.nodes,OpenStreetMapX.get_edges(m.nodes,m.roadways[1:2])[1]) == [30.2013937293296, 7.243941886194111, 35.492758006997796, 12.29992029473937, 11.290063259013777]

#intersections.jl/features_to_graph

#######################################################

function perftest()
  sr_len=length(shortest_route(m, pointA, pointB; routing = :astar)[1])
  fr_len=length(fastest_route(m, pointA, pointB; routing = :astar)[1])
  shortest_route(m, pointA, pointB; routing = :dijkstra)
  fastest_route(m, pointA, pointB; routing = :dijkstra)

  print("shortest_route(...; routing = :astar) of $sr_len nodes")
  @time shortest_route(m, pointA, pointB; routing = :astar)
  print("shortest_route(...; routing = :dijkstra)  of $sr_len nodes")
  @time shortest_route(m, pointA, pointB; routing = :dijkstra)

  print("fastest_route(...; routing = :astar) of $fr_len nodes")
  @time fastest_route(m, pointA, pointB; routing = :astar)
  print("fastest_route(...; routing = :dijkstra) of $fr_len nodes")
  @time fastest_route(m, pointA, pointB; routing = :dijkstra)

end

perftest()


end;
