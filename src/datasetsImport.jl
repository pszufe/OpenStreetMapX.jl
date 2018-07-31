
###################################
# Datasets import
###################################


# cd("C:\\Users\\Admin\\Documents\\OSMsim.jl\\src")
# path_datasets = "D:\\project ea\\data for simulation"
# include("map_snippet.jl")

 using CSV


## Import files
df_business = CSV.read(path_datasets * "\\df_business.csv", allowmissing=:none)
df_daytimep = CSV.read(path_datasets * "\\df_daytimep.csv", allowmissing=:none)
df_demostat = CSV.read(path_datasets * "\\df_demostat.csv", allowmissing=:none)
df_hwflows = CSV.read(path_datasets * "\\df_hwflows.csv", allowmissing=:none)
df_traffic = CSV.read(path_datasets * "\\df_traffic.csv", allowmissing=:auto)
df_schools = CSV.read(path_datasets * "\\df_schools.csv", allowmissing=:auto)
df_shopping = CSV.read(path_datasets * "\\df_shopping.csv", allowmissing=:auto)
df_vehicles = CSV.read(path_datasets * "\\df_vehicles.csv", allowmissing=:auto)
df_DAcentroids = CSV.read(path_datasets * "\\df_DAcentroids.csv",  allowmissing=:auto)


## Open data Recreation Complexes file
df_recreationComplex = CSV.read(path_datasets * "\\Recreation_Complex.csv")

df_recreationComplex = df_recreationComplex[[Symbol("Complex Name"),
                                             :Arena,
                                             Symbol("Indoor Pool"),
                                             Symbol("Fitness Leisure Centre"), 
                                             Symbol("Location 1") ]]
names!(df_recreationComplex, [:Name, :Arena, :Indoor_Pool, :Fitness_Leisure_Centre, :Location])

df_recreationComplex = @where(df_recreationComplex, (:Arena .== true) .| (:Indoor_Pool .== true) .| 
                              (:Fitness_Leisure_Centre .== true))

x = split.(df_recreationComplex[:Location], ",")							  
LAT = parse.(Float64, [replace.(x[i][1], "(" => "") for i in 1:size(x, 1)])
LON = parse.(Float64, [replace.(x[i][2], ")" => "") for i in 1:size(x, 1)])


## Create coordinates variables in osm format
df_business[:LLA] = LLA.(df_business[:LATITUDE], df_business[:LONGITUDE])
df_business[:ECEF] = ECEF.(df_business[:LLA])

df_schools[:LLA] = LLA.(df_schools[:LATITUDE], df_schools[:LONGITUDE])
df_schools[:ECEF] = ECEF.(df_schools[:LLA])

df_shopping[:LLA] = LLA.(df_shopping[:LATITUDE], df_shopping[:LONGITUDE])
df_shopping[:ECEF] = ECEF.(df_shopping[:LLA])

df_DAcentroids[:LLA] = LLA.(df_DAcentroids[:LATITUDE], df_DAcentroids[:LONGITUDE])
df_DAcentroids[:ECEF] = ECEF.(df_DAcentroids[:LLA])

df_recreationComplex[:LLA] = LLA.(LAT, LON)
df_recreationComplex[:ECEF] = ECEF.(df_recreationComplex[:LLA])


## Schools filtering
ind_sch = [df_schools[i, :SUBCAT] in ["Child Care Facility", "School", "Pre School"] for i in 1:size(df_schools, 1)]
df_schools = df_schools[ind_sch, :]


## Demostat Households with / withou children
df_demostat[:HouseholdsWithChildren] = @with(df_demostat, :ECYHFSCWC + :ECYHFSLP)
df_demostat[:HouseholdsWithoutChildren] = @with(df_demostat, :ECYBASHHD - :HouseholdsWithChildren)


