
###################################
# Start Location Selector
###################################


mutable struct DA_id_coord
    DA_id::Int64
    coordinates::Tuple{Float64, Float64}
end

function startLocationSelector(dict_df_DAcentroids, df_demostat_weight_var, weight_var)::DA_id_coord
    
    # Selects starting DA_home for an agent randomly weighted by weight_var
    
    # Args:
    # - dict_df_DAcentroids - dictionary of dataframes with :LATITUDE and :LONGITUDE for each DA
    # - df_demostat_weight_var - dataframe with weight_var value for each DA
    # - weight_var - weighting variable name
    
    
    DA_home = sample(df_demostat_weight_var[:PRCDDA], fweights(df_demostat_weight_var[weight_var]))
    point_DA_home = dict_df_DAcentroids[DA_home][1, :LATITUDE], 
                    dict_df_DAcentroids[DA_home][1, :LONGITUDE]
    
    return DA_id_coord(DA_home, point_DA_home)
end


