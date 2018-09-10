pth = "osm/";
path = "sim/";
datapath = "../../datasets/";

include(pth*"OpenStreetMap.jl")
include(path*"OSMSim.jl")

using Main.OSMSim

N = 100;
mode = "business";

sim_data = get_sim_data(datapath);

using Distributed
using Random
using Dates
#Distributed.addprocs(4)

@Distributed.distributed for i in 1:1
    Random.seed!(i);
    startt=Dates.now()
    nodes, buffer = run_simulation(sim_data,mode,N);
    @info "Average time per simulation $((Dates.now()-startt).value/N)ms"
    
    nodeids = collect(keys(nodes));
    sort!(nodeids, by = (nodeid -> nodes[nodeid].count), rev=true);
    for i in nodeids[1:1]
        show(nodes[i]); println();
    end
end

#TODO
    #- scalic nodes w jeden duzy dataframe, ktory ma kolumne dodatkowe kolumny: nodeid oraz  Distributed.myid()
    #- zapisac na dysk do katalogu plik = "/home/ubuntu/results/$(myid())-results-000i"-    # - `aws s3 region ca-central-1 cp  $plik "s3://eag-ca-bucket-1/SimResults/`
-# wykonac powyzsze polecenie powloki (sprawdzic jak)
-# napisac do Tonego o zwiekszenie limitu serwery.
-# wykresy dla wynikow - w R





