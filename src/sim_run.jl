using Distributed
#w = 2
#Distributed.addprocs(w)

#seq 20 40 | xargs --max-args=1 --max-procs=4 julia sim_run.jl &>> runlog1.txt

#@everywhere begin
    using Random
    using Dates
    using Distributed
    using CSVFiles
    using Printf
    pth = "osm/";
    path = "sim/";
    datapath = "/home/ubuntu/datasets/";
    include(joinpath(pth,"OpenStreetMap.jl"))
    include(joinpath(path,"OSMSim.jl"))
    using Main.OSMSim
    mode = "flows";
    version="001"
    resultspath="/home/ubuntu/results/"
    
    function s3copy(filepath,filename)
        s3path="s3://eag-ca-bucket-1/SimResults/raw"
        cmd = `aws s3 --region ca-central-1 cp $(joinpath(filepath,filename)) $(s3path)/$(filename)`
        res = read(cmd,String)
        @info "S3 $(filename): $(res)"
        s3path="s3://eag-ca-bucket-1/SimResults/zip"
        cmd = `zip -m $(joinpath(filepath,filename)).zip $(joinpath(filepath,filename))`
        res = read(cmd,String)
        cmd = `aws s3 --region ca-central-1 cp $(joinpath(filepath,filename)).zip $(s3path)/$(filename).zip`
        res = read(cmd,String)
    
    end
#end

N = 1000;
#jobs = 10

sim_data = get_sim_data(datapath);


include("sim_distributed.jl")
