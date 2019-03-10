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
