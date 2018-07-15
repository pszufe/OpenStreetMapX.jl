###################################
# Parse EA datasets 
###################################

### TO EDIT
path_boundaries = "D:\\project ea\\data\\boundaries"
path_datasets = "D:\\project ea\\data\\ea datasets"
cd("C:\\Users\\Admin\\Documents\\OSMsim.jl\\src")

###
using CSV, DataFrames, DataFramesMeta, Query, Shapefile, StatsBase

files_list = readdir(path_datasets)



###################################
### Businesses
data_business = readtable(path_datasets * "\\Businesses2018_CMA602.csv")
data_business = @select(data_business, :PRCDDA, :LATITUDE, :LONGITUDE, :Centroid,
    :INFO_EMP, :IEMP_DESC, :INFO_SAL, :ISAL_DESC, :EMPSIZCLS, :ECLS_DESC, :SALVOLCLS,
    :SCLS_DESC, :INDUSTCLS, :ICLS_DESC)
rename!(data_business, :Centroid => :CENTROID)
data_business_cols = DataFrame(colnames = names(data_business),
    labels = ["Dissemination Area",
        "Latitude Y-coordinate",
        "Longitude X-coordinate",
        "Businesses centroids",
        "Number of Employees",
        "Number of Employees more detailed",
        "Volume of Annual Sales",
        "Volume of Annual Sales more detailed",
        "Number of Employees Regrouping of ", # Regrouping of
        "Number of Employees Regrouping of 2", # Regrouping of
        "Volume of Annual Sales Regrouping of ", # Regrouping of
        "Volume of Annual Sales Regrouping of 2", # Regrouping of
        "Industry Regrouping of", # Regrouping of
        "Industry"])

# countmap(data_business[5])
# describe(data_business)
 


###################################
### Daytimepop per DA
data_daytimep = readtable(path_datasets * "\\DaytimePop2018_DA_CMA602.csv")
# showcols(data_daytimep)
delete!(data_daytimep, [2, 3, 4, 5])
data_daytimep_cols = DataFrame(colnames = names(data_daytimep),
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
        "Total Daytime Population at Work at Home"])
# describe(data_daytimep)



###################################
### Demostats per DA
data_demostat = readtable(path_datasets * "\\DemoStats2018_DA_CMA602.csv")
# showcols(data_demostat)
# describe(data_demostat[:ECYBASHPOP])

data_demostat[:weight_DA_Home] = @with(data_demostat, :ECYBASHPOP/sum(:ECYBASHPOP))
# data_demostat_cols - to be done later when socio-demographic characteristis are chosen



###################################
### Home - work flows journey matrix
# data_hwflows = readtable(path_datasets * "\\home_work_flows_Winnipeg_Pij_2018.csv", separator = ",", header = true)
data_hwflows = CSV.read(path_datasets * "\\home_work_flows_Winnipeg_Pij_2018.csv",
    header = true, types = [String, String, Int])

# showcols(data_hwflows)
# describe(data_hwflows)
rename!(data_hwflows, :DA_I => :DA_Home, :DA_J => :DA_Work)

# remove all records with DA_I == "Other | DA_J == "Other
data_hwflows = data_hwflows[@with(data_hwflows, (:DA_Home .!= "Other") .& (:DA_Work .!= "Other")), :]

# Total_Sum_Value per each DA_Home
data_hwflows_DA_H = @by(data_hwflows, :DA_Home, Total_Sum_Value = sum(:Sum_Value))
sum(data_hwflows[:Sum_Value]) == sum(data_hwflows_DA_H[:Total_Sum_Value]) # check
data_hwflows_DA_H[:DA_Home] = parse.([Int], data_hwflows_DA_H[:DA_Home])

data_hwflows = @by(data_hwflows, :DA_Home, DA_Work = :DA_Work, Sum_Value = :Sum_Value,
    Total_Sum_Value = sum(:Sum_Value), weight_DA_Work = :Sum_Value/sum(:Sum_Value))
sum(data_hwflows[:Sum_Value]) == sum(data_hwflows_DA_H[:Total_Sum_Value]) # check
sum(data_hwflows[:weight_DA_Work]) == size(data_hwflows_DA_H)[1] # check
all(round.(@by(data_hwflows, :DA_Home, w  = sum(:weight_DA_Work))[2]) .== 1.0) # check

data_hwflows[:DA_Home] = parse.([Int], data_hwflows[:DA_Home])
data_hwflows[:DA_Work] = parse.([Int], data_hwflows[:DA_Work])

# describe(data_hwflows)



###################################
### Schools
data_schools = readtable(path_datasets * "\\SAMPLE_WinnipegCMA_Schools.csv")
# showcols(data_schools)
delete!(data_schools, [:FEATID, :PACKAGE, :BRANDNAME, :COMPNAME, :HSNUM, :LOCNAME])
rename!(data_schools, :CentroidX => :LONGITUDE, :CentroidY => :LATITUDE)
# describe(data_schools)

Dict_SchoolType = Dict(:7372 => "School", :7377 => "College/University")

Dict_SchoolSubcat = Dict(:7372001 => "Unspecified",
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

data_schools[:FEATTYP_], data_schools[:SUBCAT_] = "0", "0"
for i in 1:size(data_schools, 1)
    data_schools[i, :FEATTYP_] = Dict_SchoolType[data_schools[i, :FEATTYP]]
    data_schools[i, :SUBCAT_] = Dict_SchoolSubcat[data_schools[i, :SUBCAT]]
end




###################################
### Traffic
data_traffic = readtable(path_datasets * "\\SAMPLE_WinnipegCMA_TRAFCAN2017Q1.csv")
# showcols(data_traffic)
# describe(data_traffic)



###################################
### Schopping centres
data_shopping = readtable(path_datasets * "\\ShoppingCentres2018_CMA602.csv")
# showcols(data_shopping)
data_shopping = data_shopping[[:PRCDDA, :centre_nm, :address, :lat, :lon, :centre_typ,
    :gla, :totstores, :parking, :anch_cnt]]
# describe(data_shopping)
rename!(data_shopping, :lat => :LATITUDE, :lon => :LONGITUDE)
data_shopping_cols = DataFrame(colnames = names(data_shopping),
    labels = ["Dissemination Area",
        "Shopping Centre Name",
        "Address",
        "Latitude Y-coordinate",
        "Longitude X-coordinate",
        "Centre Type",
        "Gross Leaseable Area",
        "Total Number of Stores",
        "Total Number of Parking Spaces",
        "Number of Anchor Stores"])



###################################
### Vehicles
data_vehicles = readtable(path_datasets * "\\vehicles_SAMPLE_RVIO2018_Winnipeg_CMA_by_DA.csv")
# showcols(data_vehicles)
# describe(data_vehicles)

# Industry minus large van and med hvy trucks:
data_vehicles[:RSINDSTRYT_min_RSLRGVAN_T_RSMEDHVY_T] = @with(data_vehicles,
    :RSINDSTRYT - :RSLRGVAN_T - :RSMEDHVY_T)




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
# data_DAcentroids double checked


###################################
###################################
###################################

### Data export
CSV.write(path_datasets * "\\data_demostat.csv", data_demostat[[:PRCDDA, :ECYBASHPOP, :weight_DA_Home]])
CSV.write(path_datasets * "\\data_hwflows.csv", data_hwflows)
CSV.write(path_datasets * "\\data_DAcentroids.csv", data_DAcentroids)