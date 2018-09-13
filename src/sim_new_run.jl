


@info "Starting on $(nworkers()) workers"

simcount = @Distributed.distributed (+) for d in 1:4
    i = d
    println("Worker $(myid()) Starting simulation for seed $d")
    Random.seed!(d);
    startt = Dates.now()
    println(startt)
    nodes, buffer = run_simulation(sim_data, mode, N);
    @info "Average time per simulation $((Dates.now()-startt).value/N)ms"
    @info "Simulation completed"                   
    
    # add nodeids and distributed.myid to nodes statistics
    nodeids = collect(keys(nodes));
	for i in nodeids
	    if nodes[i].agents_data != nothing
            insert!(nodes[i].agents_data, 1, i, :NODE_ID)
            insert!(nodes[i].agents_data, 1, Distributed.myid(), :DISTRIBUTED_ID)
		else
		    delete!(nodes, i)
		end
    end
	
    # merge results
	results = collect(values(nodes))[1].agents_data
	for df in collect(values(nodes))[2:end]
       append!(results, df.agents_data)
    end
    targetfile=joinpath(resultspath, 
	                   "$(Distributed.myid())-results-000$(d).csv")
	CSVFiles.save(targetfile,results)	
	@info "Results exported for worker $(myid()) seed $d to: $targetfile"
    1
end

@info "completed all $simcount simulation group  runs"

#TODO
# - `aws s3 region ca-central-1 cp  $filename "s3://eag-ca-bucket-1/SimResults/`
#- check how to execute the above shell command
#- use R for plotting


