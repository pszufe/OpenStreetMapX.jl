using ZipFile
resultspath="/home/ubuntu/data/dat"
resultspathagg="/home/ubuntu/data/agg"

const   agents = Dict{Int64,String}()
const   nodes = Dict{Int64,Array{Int64,1}}()
const   coords = Dict{Int64,Tuple{Float64,Float64}}()
const   routes1 = Dict{Int64,String}()
const   routes2 = Dict{Int64,String}()

const   routes1coords = Dict{Int64,String}()
const   routes2coords = Dict{Int64,String}()


function split_line(line::AbstractString, delim::AbstractString, firstc::Int64)
    res1=String[]
    ix = 1
    while length(res1) < firstc
        ix2 = findnext(delim,line,ix)[1]
        push!(res1,line[ix:(ix2-1)])
        ix = ix2+1
    end
    last_item = line[(findlast(";",line)[1]+1):end]
    (res1,line[ix:end],last_item)
end

function aggregate2!(resultspath,agents,nodes,coords)
    local lineheader_r
    f_count = 0
    for ff in readdir(resultspath)
        global ffn = joinpath(resultspath,ff)        
        
        if isfile(ffn) && endswith(ff,"_nodes.csv.zip") && f_count < 30
            f_count += 1
            println("$f_count reading $ff")
            local line
            r = ZipFile.Reader(ffn);
            f = r.files[1]

            lineheader_s, lineheader_r = split_line(strip(readline(f)),";",4)
            while (!eof(f))
                line = strip(readline(f))
                line_s,line_r,line_last = split_line(line,";",4)
                id = parse(Int64,line_last)

                agents[id] = line_r
                node_id = parse(Int64,line_s[2])
                if !haskey(nodes,node_id)
                    nodes[node_id] = Int64[]
                    coords[node_id] = (parse(Float64,line_s[3]),parse(Float64,line_s[4]))
                end
                push!(nodes[node_id],id)
            end
            close(f)
            close(r)
        end
    end
    return lineheader_r
end

const node_line_header = aggregate2!(resultspath,agents,nodes,coords)

function collect_routes!(routes1,routes2,routes1coords,routes2coords)
    f_count = 0
    for ff in readdir(resultspath)
        ffn = joinpath(resultspath,ff)
        if isfile(ffn) && endswith(ff,"_routes.csv") && f_count < 30
            f_count += 1
            println("$f_count reading $ff")
            f = open(ffn,"r");            
            local line
            while (!eof(f))
                line = strip(readline(f))
                if length(line) > 0
                    els = split(line,";")
                    agentid = parse(Int64,els[1])
                    nodes = parse.(Int64,els[3:end])
                    if els[2] == "towork"
                        routes1[agentid] = join(nodes,"#")
                        routes1coords[agentid] = join([join(coords[route], ",") for route in nodes],"#")
                    else
                        routes2[agentid] = join(nodes,"#")
                        routes2coords[agentid] = join([join(coords[route], ",") for route in nodes],"#")
                    end
                end
            end
            close(f)
        end
    end
end

collect_routes!(routes1,routes2,routes1coords,routes2coords)

function export_data(agents,nodes,coords,routes1,routes2,node_line_header)
    fns = open(joinpath(resultspathagg,"Node_Stats_.csv"),"w")
    println(fns,"\"NODE_ID\";\"longitude\";\"latitude\";\"vehicle_count\"")
    routes_tuple = (routes1,routes2)
    coords_tuple = (routes1coords,routes2coords)
    for node in sort!(collect(keys(nodes)))
        println(fns,"$(node);$(coords[node][1]);$(coords[node][2]);$(length(nodes[node]))")
        ftr = open(joinpath(resultspathagg,"Travel_$(node)_$(coords[node][1])_$(coords[node][2]).csv"),"w")
        fn = open(joinpath(resultspathagg,"Routes_n_$(node)_$(coords[node][1])_$(coords[node][2]).csv"),"w")
        fc = open(joinpath(resultspathagg,"Routes_c_$(node)_$(coords[node][1])_$(coords[node][2]).csv"),"w")
        println(ftr,"\"NODE_ID\";\"longitude\";\"latitude\";"*node_line_header)
        for agentid in nodes[node]
            println(ftr,"$(node);$(coords[node][1]);$(coords[node][2]);"*agents[agentid])
            routetype = "towork"
            for i in 1:2
                println(fn,"$agentid;$routetype;$(routes_tuple[i][agentid])")
                # dolozyc do linii pozynizej odpytywanie z coords
                #println(fc,"$agentid;$routetype;"*join([coords[route] for route in routes[agentid]],";"))
                println(fc, "$agentid;$routetype;$(coords_tuple[i][agentid])")
                routetype = "tohome"
            end
        end
        close(ftr)
        close(fn)
        close(fc)
        flush(fns)
    end
    close(fns)
end

export_data(agents,nodes,coords,routes1,routes2,node_line_header)
