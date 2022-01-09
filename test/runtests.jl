using Test, OpenStreetMapX
using Random, StableRNGs
import Graphs

@testset "$ext" for ext in ["osm", "pbf"]
    pth = joinpath(dirname(pathof(OpenStreetMapX)),"..","test","data","reno_east3.$ext")
    m =  OpenStreetMapX.get_map_data(pth,use_cache = false);

    @testset "maps" begin
        @test length(m.nodes) == 9032
        @test eltype(generate_point_in_bounds(m)) <: Float64
        rng = StableRNGs.StableRNG(1234)
        pA = generate_point_in_bounds(rng, m)
        @test all(isapprox.(pA,(39.52679926947162, -119.7400090256387)))
        pB = generate_point_in_bounds(rng, m)
        @test all(isapprox.(pB,(39.53417080390912, -119.73955700911934)))
        pointA = point_to_nodes(pA, m)
        pointB = point_to_nodes(pB, m)


        @test pointA == 3625693684
        @test pointB == 140115165


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
        @test centroid(m.nodes,node_list) ≈ ENU(1264.3091688577153, 982.9015092571676, -0.2152924371073368)

        #nodes.jl/nodes_within_range
        @test Set(nodes_within_range(m.nodes, ENU(3300,1500,-1), 100.0)) == Set([3052967037, 3052967180, 3052967130, 6050217400, 3052966904, 3052967140, 6050217409, 3052967199])

        #nodes.jl/add_new_node!
        @test haskey(m.nodes,-1) == false
        OpenStreetMapX.add_new_node!(m.nodes,ENU(3300,1500,-1),-1)
        @test length(m.nodes) == 9033
        @test nearest_node(m.nodes,ENU(3300,1500,-1)) == -1

        ### intersections.jl ###
        #intersections.jl/oneway
        @test OpenStreetMapX.oneway(m.roadways[1]) == true

        #intersections.jl/distance
        @test distance(m.nodes,sr1) ≈ 1720.2462568078658

        #intersections.jl/find_intersections
        @test OpenStreetMapX.find_intersections(m.roadways[1:2]) == Dict(139988738=>Set([14370413]),2975020216=>Set([14370407]),2441017888=>Set([14370407]),385046328=>Set([14370413]))

        ### routing.jl ###
        #routing.jl/get_edges
        @test Dict(zip(OpenStreetMapX.get_edges(m.nodes,m.roadways[1:2])...)) == Dict((139988738, 385046327) => 1, (2441017870, 2975020216) => 4, (385046327, 385046328) => 1, (2441017888, 2441017878) => 4, (2441017878, 2441017870) => 4)

        #parseMap.jl/get_vertices_and_graph_nodes
        vertices, graph_nodes = OpenStreetMapX.get_vertices_and_graph_nodes(OpenStreetMapX.get_edges(m.nodes,m.roadways[1:2])[1])
        @test sort(graph_nodes) == sort([2441017878,139988738,2975020216,2441017870,385046328,2441017888,385046327])
        @test vertices == Dict(zip(graph_nodes, 1:length(graph_nodes)))

        #routing.jl/distance
        #Returns seem to be equal yet returning false (?)
        @test sort(distance(m.nodes,OpenStreetMapX.get_edges(m.nodes,m.roadways[1:2])[1])) ≈ sort([30.2013937293296, 7.243941886194111, 35.492758006997796, 12.29992029473937, 11.290063259013777])

        conn_components = sort!(Graphs.strongly_connected_components(m.g),
                lt=(x,y)->length(x)<length(y), rev=true)
        @test length(conn_components)>1
        @test length(conn_components[1])==1799

        m2 =  OpenStreetMapX.get_map_data(pth,use_cache = false, trim_to_connected_graph=true);
        conn_components2 = sort!(Graphs.strongly_connected_components(m2.g),
                lt=(x,y)->length(x)<length(y), rev=true)
        @test length(conn_components2)==1
        @test length(conn_components[1])==length(conn_components2[1])

        #######################################################

        function perftest()
            sr_len=length(shortest_route(m, pointA, pointB; routing = :astar)[1])
            fr_len=length(fastest_route(m, pointA, pointB; routing = :astar)[1])
            shortest_route(m, pointA, pointB; routing = :dijkstra)
            fastest_route(m, pointA, pointB; routing = :dijkstra)

            shortest_route(m, pointA, pointB; routing = :astar)
            shortest_route(m, pointA, pointB; routing = :dijkstra)
            fastest_route(m, pointA, pointB; routing = :astar)
            fastest_route(m, pointA, pointB; routing = :dijkstra)
            nothing

        end

        @test perftest() == nothing


    end

    @testset "converters" begin
        node = m.nodes[140376307]
        lla = LLA(node, m.bounds)
        @test all((lla.lat, lla.lon, lla.alt) .≈ (39.5173324, -119.8005402, 0.0))
        e = ECEF(lla)
        #test with data from https://www.oc.nps.edu/oc2902w/coord/llhxyz.htm?source=post_page---------------------------
        @test all( abs.((e.x, e.y, e.z)./1000 .- (-2448.622, -4275.441, 4036.788)) .< 0.001)
        llawarsaw = LLA(52.22977,21.01178)
        # http://www.apsalin.com/convert-geodetic-to-cartesian.aspx
        ewaw = ECEF(llawarsaw)
        @test ewaw ≈ ECEF(3654475.66587739, 1403683.91652118, 5018503.15478704)
        llawarsaw2 = LLA(ewaw)
        @test llawarsaw2 ≈ llawarsaw
    end
end
