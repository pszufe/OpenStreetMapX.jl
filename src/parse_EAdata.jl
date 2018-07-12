###################################
# Parse EA datasets
###################################

using CSV, DataFrames, DataFramesMeta, Query, StatsBase

paths_eadata = "D:\\project ea\\data\\ea datasets"
files_list = readdir(paths_eadata)



###################################
### Businesses
data_business = readtable(paths_eadata * "\\Businesses2018_CMA602.csv")
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

countmap(data_business[5])
describe(data_business)



###################################
### Daytimepop per DA
data_daytimep = readtable(paths_eadata * "\\DaytimePop2018_DA_CMA602.csv")
showcols(data_daytimep)
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
describe(data_daytimep)



###################################
### Demostats per DA
data_demostat = readtable(paths_eadata * "\\DemoStats2018_DA_CMA602.csv")
showcols(data_demostat)
describe(data_demostat[:ECYBASHPOP])

data_demostat[:weight_DA_Home] = @with(data_demostat, :ECYBASHPOP/sum(:ECYBASHPOP))



###################################
### Home - work flows journey matrix
# data_hwflows = readtable(paths_eadata * "\\home_work_flows_Winnipeg_Pij_2018.csv", separator = ",", header = true)
data_hwflows = CSV.read(paths_eadata * "\\home_work_flows_Winnipeg_Pij_2018.csv",
    header = true, types = [String, String, Int])

showcols(data_hwflows)
describe(data_hwflows)
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
all(round(@by(data_hwflows, :DA_Home, w  = sum(:weight_DA_Work))[2]) .== 1.0) # check

data_hwflows[:DA_Home] = parse.([Int], data_hwflows[:DA_Home])
data_hwflows[:DA_Work] = parse.([Int], data_hwflows[:DA_Work])

describe(data_hwflows)



###################################
### Schools
data_schools = readtable(paths_eadata * "\\SAMPLE_WinnipegCMA_Schools.csv")
showcols(data_schools)
delete!(data_schools, [:FEATID, :PACKAGE, :BRANDNAME, :COMPNAME, :HSNUM, :LOCNAME])
rename!(data_schools, :CentroidX => :LONGITUDE, :CentroidY => :LATITUDE)
describe(data_schools)
#=
x = deepcopy(data_schools)

recode(x[:SUBCAT],  7372003 =>"Unspecified")

levels(data_schools[:SUBCAT])
levels(data_schools[:SUBCAT]) = 7372003 =>"Unspecified",
    "School",
    "Child Care Facility",
    "Pre School",
    "Vocational Training",
    "Technical School",
    "Language School",
    "Sport School",
    "Art School",
    "Special School",
    "Driving School",
    "College/University"]

map()
=#



###################################
### Traffic
data_traffic = readtable(paths_eadata * "\\SAMPLE_WinnipegCMA_TRAFCAN2017Q1.csv")
showcols(data_traffic)
describe(data_traffic)



###################################
### Schopping centres
data_shopping = readtable(paths_eadata * "\\ShoppingCentres2018_CMA602.csv")
showcols(data_shopping)
data_shopping = data_shopping[[:PRCDDA, :centre_nm, :address, :lat, :lon, :centre_typ,
    :gla, :totstores, :parking, :anch_cnt]]
describe(data_shopping)
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
data_vehicles = readtable(paths_eadata * "\\vehicles_SAMPLE_RVIO2018_Winnipeg_CMA_by_DA.csv")
showcols(data_vehicles)
describe(data_vehicles)

# Industry minus large van and med hvy trucks:
data_vehicles[:RSINDSTRYT_min_RSLRGVAN_T_RSMEDHVY_T] = @with(data_vehicles,
    :RSINDSTRYT - :RSLRGVAN_T - :RSMEDHVY_T)



######################################################################
######################################################################
