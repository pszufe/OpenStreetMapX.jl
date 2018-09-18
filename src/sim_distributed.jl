@info "Starting on $(nworkers()) workers args $ARGS"

#simcount = @Distributed.distributed (+) for d in 1:jobs
for ii in 1:100
    d = parse(Int,ARGS[1])*100+ii
    println("Worker $(myid()) Starting simulation for seed $d")
    Random.seed!(d);
    startt = Dates.now()
    println(startt)
    nodes, buffer,routes = run_simulation(sim_data, mode, d, N);
    @info "Average time per simulation $((Dates.now()-startt).value/N)ms"
    @info "Simulation completed"                   
    
    # add nodeids and distributed.myid to nodes statistics
    nodeids = collect(keys(nodes));
	for i in nodeids
	    if nodes[i].agents_data != nothing
            insert!(nodes[i].agents_data, 1, nodes[i].latitude, :latitude)
            insert!(nodes[i].agents_data, 1, nodes[i].longitude, :longitude)
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
    filenamebase="res_V$(version)_M$(mode)_W$(@sprintf("%04d", Distributed.myid()))_S$(@sprintf("%05d",d))"
    filenodes  = "$(filenamebase)_nodes.csv"
    targetfile=joinpath(resultspath, filenodes)
	CSVFiles.save(targetfile,results, delim = ';')
    s3copy(resultspath, filenodes)
    fileroutes = "$(filenamebase)_routes.csv"
    f = open(joinpath(resultspath, fileroutes),"w")
    for agentid in keys(routes)
        mode = "towork"
        for rset in routes[agentid]
            print(f,"$(agentid);$(mode)")
            for nn in rset
               print(f,";$nn")
            end
            println(f,"")
            mode = "tohome"
        end        
    end
    close(f)
    s3copy(resultspath, fileroutes)
    
	@info "Results exported for worker $(myid()) seed $d to: $targetfile"
    #1
end
#end

#@info "completed all $simcount simulation group  runs"
