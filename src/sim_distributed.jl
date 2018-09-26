@info "Starting on $(nworkers()) workers args $ARGS"

args = length(ARGS)>0 ?  ARGS : ["1"]


function run_dist_sim(resultspath,version::String,N::Int,max_jobs_worker::Int,sim_data, mode)
	for ii in 1:max_jobs_worker
	    d = parse(Int,args[1])*100+ii;
	    nodes, buffer,routes = run_simulation(sim_data, mode, d, N);
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
	    targetfile=joinpath(resultspath,filenodes)
		CSVFiles.save(targetfile,results, delim = ';')
	    #s3copy(resultspath, filenodes)
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
	    #s3copy(resultspath, fileroutes)

		@info "Results exported for worker $(myid()) seed $d to: $targetfile"
	    #1
	end
end


run_dist_sim(resultspath,version,N,max_jobs_worker,sim_data, mode)

#@info "completed all $simcount simulation group  runs"
