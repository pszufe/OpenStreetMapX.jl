using Test, OpenStreetMapX
import LightGraphs

@testset "maps" begin

m = OpenStreetMapX.get_map_data("data/reno_east3.osm",use_cache=false)


@test length(m.nodes) == 9032

using Random
Random.seed!(0);

pointA = point_to_nodes(generate_point_in_bounds(m), m)
pointB = point_to_nodes(generate_point_in_bounds(m), m)
@test pointA == 3052967037
@test pointB == 140393352


sr1, shortest_distance1, shortest_time1 = OpenStreetMapX.shortest_route(m, pointA, pointB)
@test (sr1[1], sr1[end]) == (pointA, pointB)

end;