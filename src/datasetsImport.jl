
###################################
# Datasets import
###################################


# cd("C:\\Users\\Admin\\Documents\\OSMsim.jl\\src")
# path_datasets = "D:\\project ea\\data for simulation"
# include("map_snippet.jl")

 using CSV


## Import files
df_business = CSV.read(path_datasets * "\\df_business.csv", allowmissing=:none)
df_DAcentroids = CSV.read(path_datasets * "\\df_DAcentroids.csv",  allowmissing=:auto)
df_daytimep = CSV.read(path_datasets * "\\df_daytimep.csv", allowmissing=:none)
df_demostat = CSV.read(path_datasets * "\\df_demostat.csv", allowmissing=:none)
df_hwflows = CSV.read(path_datasets * "\\df_hwflows.csv", allowmissing=:none)
df_recreationComplex = CSV.read(path_datasets * "\\df_recreationComplex.csv", allowmissing=:auto)
df_schools = CSV.read(path_datasets * "\\df_schools.csv", allowmissing=:auto)
df_shopping = CSV.read(path_datasets * "\\df_shopping.csv", allowmissing=:auto)
df_traffic = CSV.read(path_datasets * "\\df_traffic.csv", allowmissing=:auto)
df_vehicles = CSV.read(path_datasets * "\\df_vehicles.csv", allowmissing=:auto)



###################################
## Businesses - popular stores
df_business_popstores = @where(df_business, 
                               findin(:BUSNAME, Set(collect(keys(desc_df_business_popstores)))))
df_business_popstores[:CATEGORY] = [desc_df_business_popstores[df_business_popstores[i, :BUSNAME]] 
    for i in 1:size(df_business_popstores, 1)]




