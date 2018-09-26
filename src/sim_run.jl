#using Pkg;Pkg.add(PackageSpec(url="https://github.com/bkamins/Nanocsv.jl"))

using Distributed
#w = 2
#Distributed.addprocs(w)

#seq 20 40 | xargs --max-args=1 --max-procs=4 julia sim_run.jl &>> runlog1.txt

#@everywhere begin
begin
    using Random
    using Dates
    using Distributed
    using CSVFiles
    using Printf
    using Nanocsv
    pth = "osm/";
    path = "sim/";
    datapath = "../datasets/";
    include(joinpath(pth,"OpenStreetMap.jl"))
    include(joinpath(path,"OSMSim.jl"))
    using Main.OSMSim
    mode = "flows";
    version="001"
    resultspath="/home/ubuntu/results/"

    function s3copy(filepath,filename)
        #s3path="s3://eag-ca-bucket-1/SimResults/raw"
        #cmd = `aws s3 --region ca-central-1 cp $(joinpath(filepath,filename)) $(s3path)/$(filename)`
        #res = read(cmd,String)
        #@info "S3 $(filename): $(res)"
        s3path="s3://eag-ca-bucket-1/SimResults/gz"
        cmd = `gzip $(joinpath(filepath,filename))`
        res = read(cmd,String)
        cmd = `aws s3 --region ca-central-1 cp $(joinpath(filepath,filename)).gz $(s3path)/$(filename).gz`
        res = read(cmd,String)

    end
    N = 100;
    max_jobs_worker=1
end


sim_data = get_sim_data(datapath);


include("sim_distributed.jl")
