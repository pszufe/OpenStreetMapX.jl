
using Distributed
Distributed.addprocs(2)

@everywhere begin
    using Random
    using Dates
    using Distributed
    pth = "osm/";
    path = "sim/";
    datapath = "../../datasets/";
    include(joinpath(pth,"OpenStreetMap.jl"))
    include(joinpath(path,"OSMSim.jl"))
    using Main.OSMSim
    mode = "business";
end

N = 100;

sim_data = get_sim_data(datapath);

@info "Starting on $(nworkers()) workers"
#i = 1
simcount = @Distributed.distributed (+) for i in 1:4
    println("Worker $(myid()) Starting simulation for seed $i")
    Random.seed!(i);
    
    startt = Dates.now()
    nodes, buffer = run_simulation(sim_data,mode,N);
    println("Average time per simulation $((Dates.now()-startt).value/N)ms")
    
    nodeids = collect(keys(nodes));
    sort!(nodeids, by = (nodeid -> nodes[nodeid].count), rev=true);
    for i in nodeids[1:1]
        show(nodes[i]); println();
    end
    1
end

@info "completed all $simcount simulation group  runs"


#TODO
    #- scalic nodes w jeden duzy dataframe, ktory ma kolumne dodatkowe kolumny: nodeid oraz  Distributed.myid()
    #- zapisac na dysk do katalogu plik = "/home/ubuntu/results/$(myid())-results-000i"-    # - `aws s3 region ca-central-1 cp  $plik "s3://eag-ca-bucket-1/SimResults/`
-# wykonac powyzsze polecenie powloki (sprawdzic jak)
-# napisac do Tonego o zwiekszenie limitu serwery.
-# wykresy dla wynikow - w R





