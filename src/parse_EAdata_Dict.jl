
###################################
# EA datasets dictionaries
###################################


# Business data dictionary
dict_data_business = Dict()
labels = ["Dissemination Area", "Latitude", "Longitude", "Centroid", "Business name", 
    "Number of employees", "Volume of annual sales", "Industry"]

for i in 1:size(data_business, 2)
    dict_data_business[names(data_business)[i]] = labels[i]
end


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


# Demostats data dictionary
dict_data_demostat = Dict(:PRCDDA => "Dissemination Area",
    :ECYBASHPOP => "Total Household Population", 
    :ECYBASKID => "Total Children Living In Households (Children At Home)",
    :ECYBASLF => "In The Labour Force",
    :ECYPTAAVG => "Average Age Of Total Population",
    :ECYPTAMED => "Median Age Of Total Population",
    :ECYHRIMED => "Median Household Income (Constant Year 2005 \$)",
    :ECYPOWHPL => "Household Population 15 Years Or Over For Place Of Work Status",
    :ECYPOWINLF => "In The Labour Force For Occupation",
    :ECYPOWEMP => "Employed",
    :ECYPOWHOME => "Worked At Home",
    :ECYPOWOSCA => "Worked Outside Canada",
    :ECYPOWNFIX => "No Fixed Workplace Address",
    :ECYPOWUSUL => "Worked At Usual Place",
    :ECYTRAHPL => "Household Population 15 Years Or Over For Travel To Work",
    :ECYTRAALL => "Employed Population With Usual Place Of Work And No Fixed Place Of Work",
    :ECYTRADRIV => "Travel To Work By Car As Driver",
    :ECYTRAPSGR => "Travel To Work By Car As Passenger",
    :ECYTRAPUBL => "Travel To Work By Public Transit",
    :ECYTRAWALK => "Travel To Work By Walked",
    :ECYTRABIKE => "Travel To Work By Bicycle",
    :ECYTRAOTHE => "Travel To Work By Other Method")


# H-W flow matrix dictionary
dict_data_hwflows = Dict()
labels = ["DA_Home", "DA_Work", "Flow Volume of commuters from DA_Home to DA_Work", 
    "Total Flow Volume of commuters from a given DA_Home", 
    "Probability of commuting to the DA_Work from a given DA_Home", 
    "Total Flow Volume of commuters to a given DA_Work"]

for i in 1:size(data_hwflows, 2)
    dict_data_hwflows[names(data_hwflows)[i]] = labels[i]
end


# Schools data dictionary
dict_data_schools = Dict()
labels = ["School name", "Street name", "Longitude", "Latitude", 
    "School type", "School subcategory"]
for i in 1:size(data_schools, 2)
    dict_data_schools[names(data_schools)[i]] = labels[i]
end


# Traffic data dictionary
dict_data_traffic = Dict(:STREET  => "Name of the street the count was taken on",
    :TRAFFIC1  => "Most recent traffic count",
    :CNTTYPE1  => "Type of count",
    :CNT1YEAR  => "Year this count was taken",
    :CROSSST  => "Nearest cross street to the count",
    :CROSSDIR  => "Direction from the count to the cross street",
    :CROSSDIST  => "Distance, in miles, to the nearest cross street",
    :LONGITUDE  => "Longitude of traffic point",
    :LATITUDE  => "Latitude of traffic point")


# Schopping centres data dictionary
dict_data_shopping = Dict()
labels = ["Dissemination Area", "Shopping Centre Name", "Address", 
    "Latitude Y-coordinate", "Longitude X-coordinate", "Centre Type",
    "Gross Leaseable Area", "Total Number of Stores", 
    "Total Number of Parking Spaces", "Number of Anchor Stores"]

for i in 1:size(data_shopping, 2)
    dict_data_shopping[names(data_shopping)[i]] = labels[i]
end


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


