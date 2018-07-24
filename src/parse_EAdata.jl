
###################################
# Parse EA datasets along with map files processing
###################################

#=
using CSV, DataFrames, DataFramesMeta, FreqTables, Query, Shapefile, StatsBase

### TO EDIT

cd("C:\\Users\\Admin\\Documents\\OSMsim.jl\\src")

path_boundaries = "D:\\project ea\\data\\boundaries"
    # map files: .osm, .dbf, .shx, .prj, .shp
        # - winnipeg - city centre only.osm ( = winnipeg.osm from https://szufel.pl/winnipeg.zip)
        # - Winnipeg CMA.osm
        # - Winnipeg DAs PopWeighted Centroids.shp (.dbf, .shx, .prj)

path_datasets = "D:\\project ea\\data\\ea datasets"
    # EA files in path_datasets:
        # - Businesses2018_CMA602
        # - DaytimePop2018_DA_CMA602
        # - DemoStats2018_DA_CMA602
        # - home_work_flows_Winnipeg_Pij_2018
        # - SAMPLE_WinnipegCMA_Schools
        # - SAMPLE_WinnipegCMA_TRAFCAN2017Q1
        # - ShoppingCentres2018_CMA602
        # - vehicles_SAMPLE_RVIO2018_Winnipeg_CMA_by_DA

###

# OpenStreetMap library
# include("map_snippet.jl")


files_list = readdir(path_datasets)
=#


###################################
### Businesses

data_business = readtable(path_datasets * "\\Businesses2018_CMA602.csv", nastrings=["", "N/A"])
print(size(data_business))

data_business = @select(data_business, :PRCDDA, :LATITUDE, :LONGITUDE, :Centroid, 
    :BUSNAME, :IEMP_DESC, :ISAL_DESC, :ICLS_DESC)
rename!(data_business, :Centroid => :CENTROID)

# Business data dictionary
dict_data_business = Dict()
labels = ["Dissemination Area", "Latitude", "Longitude", "Centroid", "Business name", 
    "Number of employees", "Volume of annual sales", "Industry"]

for i in 1:size(data_business, 2)
    dict_data_business[names(data_business)[i]] = labels[i]
end

# describe(data_business)

# Categorical variables
data_business[:IEMP_DESC] = categorical(data_business[:IEMP_DESC])
levels!(data_business[:IEMP_DESC], ["1 - 4", "5 - 9", "10 - 19", "20 - 49", 
    "50 - 99", "100 - 249", "250 - 499", "500 - 999", "1,000 - 4,999", 
    "5,000 - 9,999"])
# freqtable(data_business[:IEMP_DESC])

data_business[:ISAL_DESC] = categorical(data_business[:ISAL_DESC])
levels!(data_business[:ISAL_DESC], ["\$1,000 - \$499,999", "\$500,000 - \$999,999", 
    "\$1,000,000 - \$2,499,999", "\$2,500,000 - \$4,999,999", 
    "\$5,000,000 - \$9,999,999", "\$10,000,000 - \$19,999,999",
    "\$20,000,000 - \$49,999,999", "\$50,000,000 - \$99,999,999",
    "\$100,000,000 - \$499,999,999", "\$500,000,000 - \$999,999,999", 
    "\$1,000,000,000+"])
# freqtable(data_business[:ISAL_DESC])

data_business[:ICLS_DESC] = categorical(data_business[:ICLS_DESC])
# levels(data_business[:ICLS_DESC]) # ok
# freqtable(data_business[:ICLS_DESC])

# describe(data_business)

# new levels, but not as missings
recode!(data_business[:IEMP_DESC], missing => "NA")
recode!(data_business[:ISAL_DESC], missing => "NA")
recode!(data_business[:ICLS_DESC], missing => "NA") 



###################################
### Daytimepop per DA

data_daytimep = readtable(path_datasets * "\\DaytimePop2018_DA_CMA602.csv")

# showcols(data_daytimep)

delete!(data_daytimep, [2, 3, 4, 5])

# Daytimepop data dictionary
dict_data_daytimep = Dict()
labels = ["Dissemination Area", 
    "Total Household Population",
    "Total Daytime Population",
    "Total Daytime Population at Home",
    "Total Daytime Population at Home Aged 0-14",
    "Total Daytime Population at Home Aged 15-64",
    "Total Daytime Population at Home Aged 65 and Over",
    "Total Daytime Population at Work",
    "Total Daytime Population at Work at Usual Place",
    "Total Daytime Population at Work Mobile",
    "Total Daytime Population at Work at Home"]

for i in 1:size(data_daytimep, 2)
    dict_data_daytimep[names(data_daytimep)[i]] = labels[i]
end

# describe(data_daytimep)



###################################
### Demostats per DA

data_demostat = readtable(path_datasets * "\\DemoStats2018_DA_CMA602.csv")

# Demostats data dictionary
include("parse_EAdata_DictDemostat.jl")

data_demostat = data_demostat[collect(keys(dict_data_demostat))]

x = trues(size(data_demostat, 2))
for i in 1:size(data_demostat, 2)
    x[i] = any(ismissing.(data_demostat[i]))
end

sum(x)
data_demostat[x]

find(ismissing.(data_demostat[:ECYHTAMED]))
find(ismissing.(data_demostat[:ECYHMAMED]))
find(ismissing.(data_demostat[:ECYHFAMED]))
data_demostat[[1111, 1140], x] = 0



###################################
### Home - work flows journey matrix

data_hwflows = CSV.read(path_datasets * "\\home_work_flows_Winnipeg_Pij_2018.csv",
    header = true, types = [String, String, Int])

# showcols(data_hwflows)
# describe(data_hwflows)
rename!(data_hwflows, :DA_I => :DA_Home, :DA_J => :DA_Work, :Sum_Value => :FlowVolume)

# remove all records with DA_I == "Other | DA_J == "Other
data_hwflows = data_hwflows[@with(data_hwflows, (:DA_Home .!= "Other") .& (:DA_Work .!= "Other")), :]

# Total Flow Volume per each DA_Work (could be useful somewhere)
data_hwflows = @by(data_hwflows, :DA_Work, DA_Home = :DA_Home, FlowVolume = :FlowVolume, 
    FlowVolume_sum_perDAwork = sum(:FlowVolume))

# Total Flow Volume per each DA_Home and DA_work weights
data_hwflows = @by(data_hwflows, :DA_Home, DA_Work = :DA_Work, FlowVolume = :FlowVolume,
    FlowVolume_sum_perDAhome = sum(:FlowVolume), weight_DA_Work = :FlowVolume/sum(:FlowVolume),
    FlowVolume_sum_perDAwork = :FlowVolume_sum_perDAwork)

data_hwflows[:DA_Home] = parse.([Int32], data_hwflows[:DA_Home])
data_hwflows[:DA_Work] = parse.([Int32], data_hwflows[:DA_Work])

# describe(data_hwflows)

# H-W flow matrix dictionary
dict_data_hwflows = Dict()
labels = ["DA_Home", "DA_Work", "Flow Volume of commuters from DA_Home to DA_Work", 
    "Total Flow Volume of commuters from a given DA_Home", 
    "Probability of commuting to the DA_Work from a given DA_Home", 
    "Total Flow Volume of commuters to a given DA_Work"]

for i in 1:size(data_hwflows, 2)
    dict_data_hwflows[names(data_hwflows)[i]] = labels[i]
end


# check:
#=
x = []
for i in 1:size(unique(data_hwflows[:DA_Home]), 1)
    x = push!(x, findfirst(data_hwflows[:DA_Home], unique(data_hwflows[:DA_Home])[i]))
end
println(sum(data_hwflows[:FlowVolume]), " ", sum(data_hwflows[x, :FlowVolume_sum_perDAhome]))

x = []
for i in 1:size(unique(data_hwflows[:DA_Work]), 1)
    x = push!(x, findfirst(data_hwflows[:DA_Work], unique(data_hwflows[:DA_Work])[i]))
end
println(sum(data_hwflows[:FlowVolume]), " ", sum(data_hwflows[x, :FlowVolume_sum_perDAwork]))

println(round(sum(data_hwflows[:weight_DA_Work]), 0), " = ", size(unique(data_hwflows[:DA_Home])), 1)

println(all(round.(@by(data_hwflows, :DA_Home, w = sum(:weight_DA_Work))[2]) .== 1.0))
=#



###################################
### Schools

data_schools = readtable(path_datasets * "\\SAMPLE_WinnipegCMA_Schools.csv")
# showcols(data_schools)

x = deepcopy(data_schools[[:FEATTYP, :SUBCAT]])
delete!(data_schools, [:FEATID, :PACKAGE, :BRANDNAME, :COMPNAME, :HSNUM, :LOCNAME,
        :FEATTYP, :SUBCAT])

rename!(data_schools, :CentroidX => :LONGITUDE, :CentroidY => :LATITUDE)
# describe(data_schools)

SchoolType = Dict(:7372 => "School", :7377 => "College/University")

SchoolSubcat = Dict(:7372001 => "Unspecified",
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
    :7377003 => "Junior College/Community College")

data_schools[:FEATTYP], data_schools[:SUBCAT] = " ", " "
for i in 1:size(data_schools, 1)
    data_schools[i, :FEATTYP] = SchoolType[x[i, :FEATTYP]]
    data_schools[i, :SUBCAT] = SchoolSubcat[x[i, :SUBCAT]]
end

# Schools data dictionary
dict_data_schools = Dict()
labels = ["School name", "Street name", "Longitude", "Latitude", 
    "School type", "School subcategory"]
for i in 1:size(data_schools, 2)
    dict_data_schools[names(data_schools)[i]] = labels[i]
end



###################################
### Traffic

data_traffic = readtable(path_datasets * "\\SAMPLE_WinnipegCMA_TRAFCAN2017Q1.csv")

# showcols(data_traffic)

# Traffic  data dictionary
dict_data_traffic = Dict(:STREET  => "Name of the street the count was taken on",
    :TRAFFIC1  => "Most recent traffic count",
    :CNTTYPE1  => "Type of count",
    :CNT1YEAR  => "Year this count was taken",
    :CROSSST  => "Nearest cross street to the count",
    :CROSSDIR  => "Direction from the count to the cross street",
    :CROSSDIST  => "Distance, in miles, to the nearest cross street",
    :LONGITUDE  => "Longitude of traffic point",
    :LATITUDE  => "Latitude of traffic point")

data_traffic = data_traffic[collect(keys(dict_data_traffic))]

# sort(names(data_traffic)) .== sort(collect(keys(dict_data_traffic)))

# describe(data_traffic)



###################################
### Schopping centres

data_shopping = readtable(path_datasets * "\\ShoppingCentres2018_CMA602.csv")

# showcols(data_shopping)

data_shopping = data_shopping[[:PRCDDA, :centre_nm, :address, :lat, :lon, :centre_typ,
    :gla, :totstores, :parking, :anch_cnt]]

# describe(data_shopping)

rename!(data_shopping, :lat => :LATITUDE, :lon => :LONGITUDE)

# Schopping centres data dictionary
dict_data_shopping = Dict()
labels = ["Dissemination Area", "Shopping Centre Name", "Address", 
    "Latitude Y-coordinate", "Longitude X-coordinate", "Centre Type",
    "Gross Leaseable Area", "Total Number of Stores", 
    "Total Number of Parking Spaces", "Number of Anchor Stores"]

for i in 1:size(data_shopping, 2)
    dict_data_shopping[names(data_shopping)[i]] = labels[i]
end



###################################
### Vehicles per DA

data_vehicles = readtable(path_datasets * "\\vehicles_SAMPLE_RVIO2018_Winnipeg_CMA_by_DA.csv")

# showcols(data_vehicles)

# Industry minus large van and med hvy trucks:
data_vehicles[:RSINDSTRYT_min_RSLRGVAN_T_RSMEDHVY_T] = @with(data_vehicles,
    :RSINDSTRYT - :RSLRGVAN_T - :RSMEDHVY_T)

# Vehicles data dictionary
dict_data_vehicles = Dict(:PRCDDA => "Dissemination Area",
    :RSINDSTRYT => "Retail Industry",
    :RSCAR____T => "Retail Car",
    :RSSUBCOM_T => "Retail Subcompact",
    :RSCMPACT_T => "Retail Compact",
    :RSINTMDT_T => "Retail Intermediate",
    :RSFULSIZET => "Retail Full Size",
    :RSLUXURY_T => "Retail Luxury",
    :RSMEDLUX_T => "Retail Medium Luxury",
    :RSHILUX__T => "Retail High Luxury",
    :RSLUXSPT_T => "Retail Luxury Sport",
    :RSSPORT__T => "Retail Sport",
    :RSTRUCK__T => "Retail Truck",
    :RSCMPSUV_T => "Retail Compact SUV",
    :RSINTSUV_T => "Retail Intermediate SUV",
    :RSLRGSUV_T => "Retail Large SUV",
    :RSLUXSUV_T => "Retail Luxury SUV",
    :RSSMLPKUPT => "Retail Small Pickup",
    :RSLRGPKUPT => "Retail Large Pickup",
    :RSSMLVAN_T => "Retail Small Van",
    :RSLRGVAN_T => "Retail Large Van",
    :RSMEDHVY_T => "Retail Medium/Heavy",
    :RSINDSTRYT_min_RSLRGVAN_T_RSMEDHVY_T => "Retail Industry minus large van and medium/heavy truck")

data_vehicles = data_vehicles[collect(keys(dict_data_vehicles))]

# describe(data_vehicles)



###################################
# Parse map and boundary files
###################################

handle = open(path_boundaries * "\\Winnipeg DAs PopWeighted Centroids.shp", "r") do io
    read(io, Shapefile.Handle)
end

LONGITUDE, LATITUDE = [], []

for i in 1:size(handle.shapes, 1)
    push!(LONGITUDE, Tuple(GeoInterface.coordinates(handle.shapes[i]))[1])
    push!(LATITUDE, Tuple(GeoInterface.coordinates(handle.shapes[i]))[2])
end

data_DAcentroids = DataFrame(PRCDDA = data_demostat[:PRCDDA], LONGITUDE = LONGITUDE, LATITUDE = LATITUDE)

# DA centroids to LLA, ECEF and osm nodes
data_DAcentroids[:LLA] = LLA.(data_DAcentroids[:LATITUDE], data_DAcentroids[:LONGITUDE])
data_DAcentroids[:ECEF] = ECEF.(data_DAcentroids[:LLA])
data_DAcentroids[:osm_node] = nearestNode.(ECEF.(WinnipegMap.osmData[1]), data_DAcentroids[:ECEF])

# data_DAcentroids double checked



###################################
### Data export
###################################


CSV.write(path_datasets * "\\data_business.csv", data_business)
CSV.write(path_datasets * "\\data_daytimep.csv", data_daytimep)
CSV.write(path_datasets * "\\data_demostat.csv", data_demostat)
CSV.write(path_datasets * "\\data_hwflows.csv", data_hwflows)
CSV.write(path_datasets * "\\data_traffic.csv", data_traffic)
CSV.write(path_datasets * "\\data_schools.csv", data_schools)
CSV.write(path_datasets * "\\data_shopping.csv", data_shopping)
CSV.write(path_datasets * "\\data_vehicles.csv", data_vehicles)
CSV.write(path_datasets * "\\data_DAcentroids.csv", data_DAcentroids)

