
###################################
# Start Location Selector
###################################


mutable struct DA_id_coord
    DA_id::Int64
    coordinates::Tuple{Float64, Float64}
end

function startLocationSelector(weight_var::Symbol = weight_var, 
                               df_demostat::DataFrame = df_demostat, 
                               df_DAcentroids::DataFrame = df_DAcentroids,
                               DA_id::Symbol = DA_id)::DA_id_coord
    
    # Selects starting DA_home for an agent randomly weighted by weight_var
    
    # Args:
    # - weight_var - weighting variable name
    # - df_demostat - dataframe with population statistics for each DA_id: includes weight_var
    # - df_DAcentroids - dataframe with :LATITUDE and :LONGITUDE for each DA_id
    # - DA_id - variable name with unique id for each DA
    
    DA_home = sample(df_demostat[DA_id], fweights(df_demostat[weight_var]))
    index = df_DAcentroids[df_DAcentroids[DA_id] .== DA_home, :]
    point_DA_home = index[:LATITUDE][1], index[:LONGITUDE][1]
    
    return DA_id_coord(DA_home, point_DA_home)
end


