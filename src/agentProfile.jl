
###################################
# Agent demographic profile generator and aggregator
###################################


## Agent demographic profile generator
mutable struct DemoProfile
    DA_home::Int
    city_region::String
    sex::String
    age::Int
    marital_status::String
    work_industry::String
    household_income::Int # household data
    household_size::String # household data
    children_number_of::Int # household data
    children_age::Array{String} # household data
    imigrant::String
    imigrant_since::String
end


# work_industry
dict_work_industry = Dict(
    :ECYINDAGRI => "Agriculture, Forestry, Fishing And Hunting", 
    :ECYINDMINE => "Mining, Quarrying, And Oil And Gas Extraction", 
    :ECYINDUTIL => "Utilities",  
    :ECYINDCSTR => "Construction", 
    :ECYINDMANU => "Manufacturing", 
    :ECYINDWHOL => "Wholesale Trade", 
    :ECYINDRETL => "Retail Trade", 
    :ECYINDTRAN => "Transportation And Warehousing", 
    :ECYINDINFO => "Information And Cultural Industries", 
    :ECYINDFINA => "Finance And Insurance", 
    :ECYINDREAL => "Real Estate And Rental And Leasing",
    :ECYINDPROF => "Professional, Scientific And Technical Services", 
    :ECYINDMGMT => "Management Of Companies And Enterprises", 
    :ECYINDADMN => "Administrative And Support, Waste Management And Remediation Services", 
    :ECYINDEDUC => "Educational Services", 
    :ECYINDHLTH => "Health Care And Social Assistance",
    :ECYINDARTS => "Arts, Entertainment And Recreation", 
    :ECYINDACCO => "Accommodation And Food Services", 
    :ECYINDOSER => "Other Services (Except Public Administration)", 
    :ECYINDPUBL => "Public Administration"
)


# household_income
dict_hh_income = Dict(
    :ECYHRI_010 => [0, 9999], 
    :ECYHRI1020 => [10000, 19999], 
    :ECYHRI2030 => [20000, 29999], 
    :ECYHRI3040 => [30000, 39999], 
    :ECYHRI4050 => [40000, 49999], 
    :ECYHRI5060 => [50000, 59999], 
    :ECYHRI6070 => [60000, 69999], 
    :ECYHRI7080 => [70000, 79999], 
    :ECYHRI8090 => [80000, 89999], 
    :ECYHRIX100 => [90000, 99999], 
    :ECYHRIX125 => [100000, 124999], 
    :ECYHRIX150 => [125000, 149999], 
    :ECYHRIX175 => [150000, 174999], 
    :ECYHRIX200 => [175000, 199999], 
    :ECYHRIX250 => [200000, 249999], 
    :ECYHRI250P => [250000, 1000000]
)


# children_number_of
dict_children_number_of = Dict(
    :HouseholdsWithoutChildren => 0,
    :ECYHFSC1C => 1, 
    :ECYHFSC2C => 2, 
    :ECYHFSC3C => 3, # 3+
    :ECYHFSLP1C => 1, 
    :ECYHFSLP2C => 2, 
    :ECYHFSLP3C => 3 # 3+
)


function demographicProfileGenerator(DA_home, dict_df_demostat, dict_df_DAcentroids, city_centre_ENU, 
                                     max_distance_from_cc)::DemoProfile
    
    # Creates socio-demographic profile of an agent based on demostats distributions per DA
    
    # Args:
    # - DA_home - DA_home unique id selected for an agent
    # - dict_df_demostat - dictionary of dataframes with population statistics for each DA
    # - dict_df_DAcentroids - dictionary of dataframes with :LATITUDE and :LONGITUDE for each DA
    # - max_distance_from_cc - maximum distance from DA_home to city_centre to assume DA_home is in the downtown
    # - city_centre_ENU - city centre ENU coordinates

    # Function, in case of any adjustments, should be modified within its body altogether with DemoProfile struct
    
    df_demostat = dict_df_demostat[DA_home]
    
    # city_region
    dist_city_centre = distance(dict_df_DAcentroids[DA_home][1, :ENU], city_centre_ENU)
    
    if dist_city_centre < max_distance_from_cc
        city_region = "downtown"
    else
        city_region = "edge city"
    end
    

    # sex and age
    x = df_demostat[[:ECYHMA2024, :ECYHMA2529, :ECYHMA3034, :ECYHMA3539, # male
                     :ECYHMA4044, :ECYHMA4549, :ECYHMA5054, :ECYHMA5559, 
                     :ECYHMA6064, :ECYHMA6569, :ECYHFA2024, :ECYHFA2529, # female
                     :ECYHFA3034, :ECYHFA3539, :ECYHFA4044, :ECYHFA4549, 
                     :ECYHFA5054, :ECYHFA5559, :ECYHFA6064, :ECYHFA6569]]
    sex_age = sample(String.(names(x)), fweights(Array(x)))

    if searchindex(sex_age, "M") > 0
        sex = "male"
    else
        sex = "female"
    end
    
    age = rand(parse(Int, sex_age[7:8]):parse(Int, sex_age[9:10]))
    
    
    # marital_status (household population aged 15+)
    x = df_demostat[[:ECYMARMCL, :ECYMARNMCL]]
    marital_status = sample(["married or living with a common-law partner", 
                             "not married and not living with a common-law partner"], 
                            fweights(Array(x)))

    
    # work_industry
    x = df_demostat[collect(keys(dict_work_industry))]    
    work_industry = dict_work_industry[sample(names(x), fweights(Array(x)))]

    
    # household_income 
    x = df_demostat[collect(keys(dict_hh_income))]
    income_interval = sample((names(x)), fweights(Array(x)))
    household_income = rand(dict_hh_income[income_interval][1]:dict_hh_income[income_interval][2])

    
    # household_size
    x = df_demostat[[:ECYHSZ1PER, :ECYHSZ2PER, :ECYHSZ3PER, :ECYHSZ4PER, :ECYHSZ5PER]]
    household_size = sample(["1 Person", "2 Persons", "3 Persons", "4 Persons", "5 Persons"], 
                            fweights(Array(x)))

    
    # children_number_of
    x = df_demostat[collect(keys(dict_children_number_of))]
    children_number_of = dict_children_number_of[sample(names(x), fweights(Array(x)))]

    
    # children_age
    children_age = []
    for i in 1:children_number_of
        x = df_demostat[[:ECYCHA_0_4, :ECYCHA_5_9, :ECYCHA1014, :ECYCHA1519, 
                         :ECYCHA2024, :ECYCHA25P]]
        push!(children_age, sample(["0 To 4", "5 To 9", "10 To 14", "15 To 19", 
                                    "20 To 24", "25 Or More"], 
                                   fweights(Array(x)))) 
    end

    
    # imigrant
    x = df_demostat[[:ECYPIMNI, :ECYPIMIM]]
    imigrant = sample(["Non-Immigrants", "Immigrants"], fweights(Array(x)))

    
    # imigrant_since
    if imigrant == "Immigrants"
        x = df_demostat[[:ECYPIMP01, :ECYPIM0105, :ECYPIM0611, :ECYPIM12CY]]
        imigrant_since = "immigration date: " * sample(["Before 2001", "2001 To 2005", 
                                                        "2006 To 2011", "2012 To Present"], 
                                                       fweights(Array(x)))
    else
        imigrant_since = ""
    end
    
    return DemoProfile(DA_home, 
                       city_region, 
                       sex, 
                       age, 
                       marital_status, 
                       work_industry, 
                       household_income, 
                       household_size, 
                       children_number_of, 
                       children_age, 
                       imigrant, 
                       imigrant_since)
    
end



## Agent demographic profile aggregator

