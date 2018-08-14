function get_lon_lat!(table::DataFrames.DataFrame)
    x = split.(table[:LOCATION], ",")
    table[:LATITUDE] = parse.(Float64, [replace.(x[i][1], "(" => "") for i in 1:size(x, 1)])
    table[:LONGITUDE] = parse.(Float64, [replace.(x[i][2], ")" => "") for i in 1:size(x, 1)])
end

function combine_cols!(table::DataFrames.DataFrame, new_col::Symbol, cols::Array{Symbol}, operation::Function)
    array = [table[i] for i in cols]
    table[new_col] = operation(array...)
end

function filter_df_hwflows!(table::DataFrames.DataFrame)
    table = table[(table[:DA_I] .!= "Other") .& (table[:DA_J] .!= "Other"), :]
end

function filter_df_recreationComplex!(table::DataFrames.DataFrame)
    table = table[table[:ARENA]  .| table[:INDOOR_POOL] .| table[:FITNESS], :]
end

function filter_df_schools!(table::DataFrames.DataFrame, categories::Dict{Int,String} = SchoolType)
    table[:SUBCAT] = [SchoolSubcat[table[:SUBCAT][i]] for i = 1:length(table[:SUBCAT])]
    schools = ["Child Care Facility", "School", "Pre School"]
    table = table[indexin(table[:SUBCAT], schools) .> 0,:]
end

function filter_df_popstores!(table::DataFrames.DataFrame, categories::Dict{String,String})
    df_popstores = table[indexin(table[:BUSNAME], collect(keys(categories))) .> 0,:]
    df_popstores[:CATEGORY] = [categories[df_popstores[i, :BUSNAME]] for i in 1:size(df_popstores, 1)]
    return df_popstores
end

function get_derivative_datasets(data_prep, data_to_filter)
    data_frames = Dict{String,DataFrames.DataFrame}()
    for (key,value) in data_prep
        table = data_to_filter[value[:source]]
        new_table = value[:filter](table,value[:categories])
        data_frames[key] = new_table
    end
    return data_frames
end

function parse_csv_datasets(data_prep, path)
    data_frames = Dict{String,DataFrames.DataFrame}()
    for (key,value) in data_prep
        if !isa(value[:NAs],Void)
            table = readtable(path*value[:file_name]*".csv", nastrings = value[:NAs])
        else
            table = readtable(path*value[:file_name]*".csv")
        end
        if !isa(value[:rename],Void)
            for n in value[:rename]
                rename!(table,n.first,n.second)
            end
        end
        if !isa(value[:variables],Void)
            table = table[collect(keys(value[:variables]))]
        end
        if !isa(value[:new_col],Void)
            for ex in value[:new_col]
                if length(ex) == 2
                    ex[1](table,ex[2]...)
                elseif length(ex) == 1
                    ex[1](table)
                else
                    Error("new column definition in wrong format!")
                end
            end
        end
        if !isa(value[:filter],Void)
            for ex in value[:filter]
                table = ex(table)
            end
        end
        data_frames[key] = table
    end
    return data_frames
end

function parse_shapefile_data(data_prep, path::String)
    data_frames = Dict{String,DataFrames.DataFrame}()
    for (key,value) in data_prep
        handle = open(path * value*".shp", "r") do io
            read(io, Shapefile.Handle)
        end
        LONGITUDE, LATITUDE = zeros(size(handle.shapes, 1)), zeros(size(handle.shapes, 1))
        for i = 1:length(handle.shapes)
            LONGITUDE[i], LATITUDE[i] = handle.shapes[i].x,handle.shapes[i].y
        end
        attributes = readdbf(path * value*".DBF")
        data_frames[key] = DataFrame(DA_ID = parse.(Int, attributes[:Label]), LONGITUDE = LONGITUDE, LATITUDE = LATITUDE)
    end
    return data_frames
end

function get_data(path; prepare_datasets = SimDataPreparation.prepare_data)
    data_frames = Dict{String,DataFrames.DataFrame}()
    if haskey(prepare_datasets, :CSV)
        merge!(data_frames,parse_csv_datasets(prepare_datasets[:CSV],path))
    else
        Error("")
    end
    if haskey(prepare_datasets, :SHP)
        merge!(data_frames, parse_shapefile_data(prepare_datasets[:SHP],path))
     else
        Error("")
    end
    if haskey(prepare_datasets, :DERIVATIVE)
        merge!(data_frames, get_derivative_datasets(prepare_datasets[:DERIVATIVE], data_frames))
     else
        Error("")
    end
    return data_frames
end
    