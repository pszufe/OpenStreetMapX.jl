
###################################
# Datasets parsing
###################################


# cd("C:\\Users\\Admin\\Documents\\OSMsim.jl\\src")
# path_datasets = "D:\\project ea\\data for simulation"

# using CSV, DataFrames, DataFramesMeta, FreqTables, Query, Shapefile, StatsBase
# files_list = readdir(path_datasets)

# include("datasetsDescDict.jl")


function replaceMissings(col, replacement)
    collect(Missings.replace(col, replacement))
end



###################################
### Businesses

df_business = readtable(path_datasets * "\\Businesses2018_CMA602.csv", 
                          nastrings=["", "N/A"])
rename!(df_business, :Centroid => :CENTROID)
df_business = df_business[collect(keys(desc_df_business))]

# missings in ISAL_DESC - 3528 and IEMP_DESC - 323
for i in [:PRCDDA, :LATITUDE, :LONGITUDE]
    df_business[i] = replaceMissings(df_business[i], 0)
end

for i in [:CENTROID, :BUSNAME, :IEMP_DESC, :ISAL_DESC, :ICLS_DESC]
    df_business[i] = replaceMissings(df_business[i], "NA")
end

# describe(df_business)



###################################
### Daytimepop per DA

df_daytimep = readtable(path_datasets * "\\DaytimePop2018_DA_CMA602.csv")
df_daytimep = df_daytimep[collect(keys(desc_df_daytimep))]

# there are no missings
for i in names(df_daytimep)
    df_daytimep[i] = replaceMissings(df_daytimep[i], 0)
end

# describe(df_daytimep)



###################################
### Demostats per DA

df_demostat = readtable(path_datasets * "\\DemoStats2018_DA_CMA602.csv")
df_demostat = df_demostat[collect(keys(desc_df_demostat))]

# there are 2 missings in some variables - for DA where no people live
for i in names(df_demostat)
    df_demostat[i] = replaceMissings(df_demostat[i], 0)
end

# Households with / without children
df_demostat[:HouseholdsWithChildren] = @with(df_demostat, :ECYHFSCWC + :ECYHFSLP)
df_demostat[:HouseholdsWithoutChildren] = @with(df_demostat, :ECYBASHHD - :HouseholdsWithChildren)

# describe(df_demostat)



###################################
### Home - work flow journey matrix

df_hwflows = readtable(path_datasets * "\\home_work_flows_Winnipeg_Pij_2018.csv")
rename!(df_hwflows, :DA_I => :DA_home, :DA_J => :DA_work, :Sum_Value => :FlowVolume)

# remove all records with DA_I == "Other | DA_J == "Other
df_hwflows = df_hwflows[@with(df_hwflows, (:DA_home .!= "Other") .& (:DA_work .!= "Other")), :]

# Total Flow Volume per each DA_work (could be useful somewhere)
df_hwflows = @by(df_hwflows, :DA_work, DA_home = :DA_home, FlowVolume = :FlowVolume, 
    FlowVolume_sum_perDAwork = sum(:FlowVolume))

# Total Flow Volume per each DA_home and DA_work weights (could be useful somewhere)
df_hwflows = @by(df_hwflows, :DA_home, DA_work = :DA_work, FlowVolume = :FlowVolume,
    FlowVolume_sum_perDAhome = sum(:FlowVolume), weight_DA_work = :FlowVolume/sum(:FlowVolume),
    FlowVolume_sum_perDAwork = :FlowVolume_sum_perDAwork)

# there are no missings
df_hwflows[:DA_home] = parse.([Int32], df_hwflows[:DA_home])
df_hwflows[:DA_work] = parse.([Int32], df_hwflows[:DA_work])
df_hwflows[:FlowVolume] = replaceMissings(df_hwflows[:FlowVolume], 0)

# describe(df_hwflows)

#= 
x = []

for i in 1:size(unique(df_hwflows[:DA_home]), 1)
    x = push!(x, findfirst(df_hwflows[:DA_home], unique(df_hwflows[:DA_home])[i]))
end
println(sum(df_hwflows[:FlowVolume]), " ", sum(df_hwflows[x, :FlowVolume_sum_perDAhome]))

x = []
for i in 1:size(unique(df_hwflows[:DA_work]), 1)
    x = push!(x, findfirst(df_hwflows[:DA_work], unique(df_hwflows[:DA_work])[i]))
end
println(sum(df_hwflows[:FlowVolume]), " ", sum(df_hwflows[x, :FlowVolume_sum_perDAwork]))

println(round(sum(df_hwflows[:weight_DA_work]), 0), " = ", size(unique(df_hwflows[:DA_home])), 1)

println(all(round.(@by(df_hwflows, :DA_home, w = sum(:weight_DA_work))[2]) .== 1.0))
=#



###################################
### Recreation Complexes - open source data
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
df_recreationComplex = @transform(df_recreationComplex, 
    LATITUDE = parse.(Float64, [replace.(x[i][1], "(" => "") for i in 1:size(x, 1)]),
    LONGITUDE = parse.(Float64, [replace.(x[i][2], ")" => "") for i in 1:size(x, 1)]))

# describe(df_recreationComplex)



###################################
### Schools

df_schools = readtable(path_datasets * "\\SAMPLE_WinnipegCMA_Schools.csv")
rename!(df_schools, :CentroidX => :LONGITUDE, :CentroidY => :LATITUDE)
df_schools = df_schools[collect(keys(desc_df_schools))]

x = deepcopy(df_schools[[:FEATTYP, :SUBCAT]])
delete!(df_schools, [:FEATTYP, :SUBCAT])

SchoolType = Dict(:7372 => "School", :7377 => "College/University")

SchoolSubcat = Dict(
    :7372001 => "Unspecified",
    :7372002 => "School",
    :7372003 => "Child Care Facility",
    :7372004 => "Pre School",
    :7372005 => "Primary School",
    :7372006 => "High School",
    :7372007 => "Senior High School",
    :7372008 => "Vocational Training",
    :7372009 => "Technical School",
    :7372010 => "Language School",
    :7372011 => "Sport School",
    :7372012 => "Art School",
    :7372013 => "Special School",
    :7372014 => "Middle School",
    :7372015 => "Culinary School",
    :7372016 => "Driving School",
    :7377001 => "Unspecified",
    :7377002 => "College/University",
    :7377003 => "Junior College/Community College"
)

df_schools[:FEATTYP], df_schools[:SUBCAT] = " ", " "
for i in 1:size(df_schools, 1)
    df_schools[i, :FEATTYP] = SchoolType[x[i, :FEATTYP]]
    df_schools[i, :SUBCAT] = SchoolSubcat[x[i, :SUBCAT]]
end

# there are some missings in STNAME
df_schools[:NAME] = replaceMissings(df_schools[:NAME], "NA")
df_schools[:STNAME] = replaceMissings(df_schools[:STNAME], "NA")
df_schools[:LONGITUDE] = replaceMissings(df_schools[:LONGITUDE], 0)
df_schools[:LATITUDE] = replaceMissings(df_schools[:LATITUDE], 0)

for i in [:STNAME]
    df_schools[df_schools[i] .== "", i] = "NA"
end

## Schools filtering
ind_sch = [df_schools[i, :SUBCAT] in ["Child Care Facility", "School", "Pre School"] for i in 1:size(df_schools, 1)]
df_schools = df_schools[ind_sch, :]

# describe(df_schools)



###################################
### Shopping centres

df_shopping = readtable(path_datasets * "\\ShoppingCentres2018_CMA602.csv")
rename!(df_shopping, :lat => :LATITUDE, :lon => :LONGITUDE)
df_shopping = df_shopping[collect(keys(desc_df_shopping))]

# missings in address - 2, totstores - 3, parking - 11, anch_cnt - 14, centre_typ - 1
for i in [:PRCDDA, :LATITUDE, :LONGITUDE, :gla, :totstores, :parking, :anch_cnt]
    df_shopping[i] = replaceMissings(df_shopping[i], 0)
end

for i in [:address, :centre_typ, :centre_nm]
    df_shopping[i] = replaceMissings(df_shopping[i], "NA")
end

# describe(df_shopping)



###################################
### Traffic

df_traffic = readtable(path_datasets * "\\SAMPLE_WinnipegCMA_TRAFCAN2017Q1.csv")
df_traffic = df_traffic[collect(keys(desc_df_traffic))]

# there are some missings in STREET and CROSSST
for i in [:TRAFFIC1, :CROSSDIST, :LONGITUDE, :CNT1YEAR, :LATITUDE]
    df_traffic[i] = replaceMissings(df_traffic[i], 0)
end

for i in [:STREET, :CROSSST, :CROSSDIR, :CNTTYPE1]
    df_traffic[i] = replaceMissings(df_traffic[i], "NA")
end

for i in [:STREET, :CROSSST, :CROSSDIR, :CNTTYPE1]
    df_traffic[df_traffic[i] .== "", i] = "NA"
end

# describe(df_traffic)



###################################
### Vehicles per DA

df_vehicles = readtable(path_datasets * "\\vehicles_SAMPLE_RVIO2018_Winnipeg_CMA_by_DA.csv")

# Industry minus large van and med hvy trucks:
df_vehicles[:RSINDSTRYT_min_RSLRGVAN_T_RSMEDHVY_T] = @with(df_vehicles,
    :RSINDSTRYT - :RSLRGVAN_T - :RSMEDHVY_T)

df_vehicles = df_vehicles[collect(keys(desc_df_vehicles))]

# there are no missings
for i in names(df_vehicles)
    df_vehicles[i] = replaceMissings(df_vehicles[i], 0)
end

# describe(df_vehicles)

###



###################################
# Shapefile - DA centroids

handle = open(path_datasets * "\\Winnipeg DAs PopWeighted Centroids.shp", "r") do io
    read(io, Shapefile.Handle)
end

LONGITUDE, LATITUDE = [], []

for i in 1:size(handle.shapes, 1)
    push!(LONGITUDE, Tuple(GeoInterface.coordinates(handle.shapes[i]))[1])
    push!(LATITUDE, Tuple(GeoInterface.coordinates(handle.shapes[i]))[2])
end

df_DAcentroids = DataFrame(PRCDDA = df_demostat[:PRCDDA], LONGITUDE = LONGITUDE, LATITUDE = LATITUDE)

###



###################################
# Datasets export

CSV.write(path_datasets * "\\df_business.csv", df_business)
CSV.write(path_datasets * "\\df_daytimep.csv", df_daytimep)
CSV.write(path_datasets * "\\df_demostat.csv", df_demostat)
CSV.write(path_datasets * "\\df_hwflows.csv", df_hwflows)
CSV.write(path_datasets * "\\df_traffic.csv", df_traffic)
CSV.write(path_datasets * "\\df_schools.csv", df_schools)
CSV.write(path_datasets * "\\df_recreationComplex.csv", df_recreationComplex)
CSV.write(path_datasets * "\\df_shopping.csv", df_shopping)
CSV.write(path_datasets * "\\df_vehicles.csv", df_vehicles)
CSV.write(path_datasets * "\\df_DAcentroids.csv", df_DAcentroids)



