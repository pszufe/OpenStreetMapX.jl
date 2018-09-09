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
#Distributed.addprocs(4)

@Distributed.distributed for i in range(1000)
    Random.seed!(i);
    nodes, buffer = run_simulation(sim_data,mode,N);

    nodeids = collect(keys(nodes));
    sort!(nodeids, by = (nodeid -> nodes[nodeid].count), rev=true);
    #for i in nodeids[1:5]
    #    show(nodes[i]); println();
    #end
    #- scalic nodes w jeden duzy dataframe, ktory ma kolumne dodatkowe kolumny: nodeid oraz  Distributed.myid()
    #- zapisac na dysk do katalogu plik = "/home/ubuntu/results/$(myid())-results-000i"
    # - `aws s3 --region ca-central-1 cp  $plik "s3://eag-ca-bucket-1/SimResults/`

end
#TODO
# wykonac powyzsze polecenie powloki (sprawdzic jak)
# napisac do Tonego o zwiekszenie limitu serwery.
# wykresy dla wynikow - w R
