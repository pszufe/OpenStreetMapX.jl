function count_nodes(path::String, filename::String...) 
    nodes = Dict{SubString,Int64}()
    for file in filename
        stream = open(joinpath(path,file))
        local nodeid
        for line in eachline(CodecZlib.GzipDecompressorStream(stream))
            c = codeunits(line)
           i = 1
           while c[i] != 0x3b
               i += 1
           end
           i += 1
           beg = i
           while c[i] != 0x3b
               i += 1
           end
           nodeid = SubString(line, beg, i-1)
            if !haskey(nodes,nodeid)
                nodes[nodeid] = 1
            else
                nodes[nodeid] += 1
            end
        end
        close(stream)
    end
    delete!(nodes,"\"NODE_ID\"")
    return nodes
end