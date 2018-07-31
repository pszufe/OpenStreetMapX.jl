
###################################
# Destination Location Selectors
###################################


## Selection based on Journey Matrix 
function destinationLocationSelectorJM(DA_home::Int64 = DA_home, 
                                       df_hwflows::DataFrame = df_hwflows, 
                                       df_DAcentroids::DataFrame = df_DAcentroids,
                                       DA_id::Symbol = :PRCDDA)::DA_id_coord
    
    # Selects destination DA_work for an agent randomly weighted by Pij Journey Matrix
    
    # Args:
    # - DA_home - DA_home unique id (DA_id) selected for an agent
    # - df_hwflows - dataframe representing Pij Journej Matrix with *FlowVolume* from *DA_home* to *DA_work*
    # - df_DAcentroids - dataframe with :LATITUDE and :LONGITUDE for each DA_id
    # - DA_id - variable name with unique id for each DA
    
    index = df_hwflows[:DA_home] .== DA_home
    DA_work = sample(df_hwflows[index, :DA_work], fweights(df_hwflows[index, :FlowVolume]))
    index = df_DAcentroids[df_DAcentroids[DA_id] .== DA_work, :]
    point_DA_work = index[:LATITUDE][1], index[:LONGITUDE][1]
    
    return DA_id_coord(DA_work, point_DA_work)
end


###


## Selection based on agent's Demographic Profile

# DA_work selected by randomely choosing the company (business) where agent work based on 
# - agent work_industry profile
# - distance between DA_home and the city centre
# - distance between DA_home and business location 
# - agent_age-based weigths
# - company size weights represented by randomely estimated number of employees


function estimateBusinessEmployees(df_business::DataFrame = df_business,
                                   IEMP_DESC::Symbol = :IEMP_DESC)
    
    # Estimates the number of employees for each Businesses unit based on "Number of employees" intervals
    
    # Args:
    # df_business - dataframe with businesses along with their number of employees as String intervals
    # IEMP_DESC - "Number of employees" variable represented by String intervals (eg "1 - 4")
    
    df_business[:IEMP_DESC_estimate] = 0
    
    for i in 1:size(df_business, 1)
        x = split(replace(df_business[i, :IEMP_DESC], "," => ""))
        
        # assumption: if there is no information concerning number of employees, this number is set to 1
        # there are 323 such businesses in Winnipeg, most of them ATMs, so the probability of selecting any
        # of them should be low
        if x[1] == "NA"
            df_business[i, :IEMP_DESC_estimate] = 1 
        else 
            df_business[i, :IEMP_DESC_estimate] = rand(parse(Int, x[1]):parse(Int, x[3]))
        end
        
    end

    return df_business
end


# Industry dictionary for agent_profile:
# - key = industry from dfdemostat
# - value = industry from df_business
dict_industry = Dict(
    "Manufacturing"                       => ["Manufacturing", "Unassigned"], 
    "Transportation And Warehousing"      => ["Transportation And Warehousing", "Unassigned"], 
    "Arts, Entertainment And Recreation"  => ["Arts, Entertainment and Recreation", "Unassigned"], 
    "Construction"                        => ["Construction", "Unassigned"], 
    "Other Services (Except Public Administration)" => 
        ["Other Services (Except Public Administration)", "Unassigned"], 
    "Retail Trade"                        => ["Retail Trade", "Unassigned"], 
    "Wholesale Trade"                     => ["Wholesale Trade", "Unassigned"], 
    "Professional, Scientific And Technical Services" => 
        ["Professional, Scientific and Technical Services", "Unassigned"], 
    "Accommodation And Food Services"     => ["Accommodation and Food Services", "Unassigned"], 
    "Finance And Insurance"               => ["Finance, Insurance and Real Estate", "Unassigned"], 
    "Educational Services"                => ["Educational, Health and Social Services", "Unassigned"], 
    "Agriculture, Forestry, Fishing And Hunting" => 
        ["Agricultural & Natural Resources", "Unassigned"], 
    "Administrative And Support, Waste Management And Remediation Services" => 
        ["Administrative and Support and Waste Management", "Unassigned"], 
    "Public Administration"               => ["Public Administration", "Unassigned"], 
    "Information And Cultural Industries" => ["Information", "Unassigned"], 
    "Management Of Companies And Enterprises" => 
        ["Management", "Unassigned"], 
    "Utilities"                           => 
        ["Other Services (Except Public Administration)", "Professional, Scientific and Technical Services", 
        "Agricultural & Natural Resources", "Agricultural & Natural Resources"], 
    "Real Estate And Rental And Leasing"  => ["Finance, Insurance and Real Estate", "Unassigned"], 
    "Health Care And Social Assistance"   => ["Educational, Health and Social Services", "Unassigned"], 
    "Mining, Quarrying, And Oil And Gas Extraction" => 
        ["Agricultural & Natural Resources", "Unassigned"]
)


function destinationLocationSelectorDP(q_centre = 0.5, q_other = 0.7,
                                       max_distance_from_cc::Int64 = max_distance_from_cc)::DA_id_coord
    
    # Selects destination DA_work for an agent by randomly choosing the company he works in
    
    # Assumptions based on agent demographic profile:
    # - agents work in the business in accordance with their work_industry
    # - agents livingin the city centre tend to work near home
    # - older agents and women-agents tend to work rather closer to home 
    
    # Args:
    # - q_centre - quantiles probability of the home - business distance for agents living in the downtown 
    # - q_centre - quantiles probability of the home - business distance for agents not living in the downtown 
    # - max_distance_from_cc - maximum distance from DA_home to city_centre to assume DA_home is in the downtown
    
    # Other objects used in the function: 
    # - agent_profile - agent demographic profile::DemoProfile with city_region, work_industy and age
    # - df_business - business dataframe along with its location, industry and estimated number of employees 
    # - df_DAcentroids - dataframe with :LATITUDE and :LONGITUDE for each DA_id
    # - df_demostat - dataframe with population statistics for each DA_id
    # - city_centre_ECEF - city centre ECEF coordinates
    # - DA_home - DA_home unique id (DA_id) selected for an agent
    # - dict_industry - industry (or any) dictionary matching demographic data from df_business with
    # demographic ones selected for an agent (in agent_profile.work_industry)
    
    # Function, in case of any adjustments, should be modified within its body
    
    # industry assumption:
    bus_industry = dict_industry[agent_profile.work_industry]
    index_industry = [(df_business[:ICLS_DESC][i] in bus_industry) for i in 1:size(df_business, 1)]
    df_business_temp = df_business[index_industry, :]
    
    dist_array = distance.(df_DAcentroids[df_DAcentroids[:PRCDDA] .== DA_home, :ECEF][1], 
                           df_business_temp[:ECEF])
    
    # all other assumptions:
    if agent_profile.city_region == "downtown"
        index = dist_array .< ( quantile(dist_array, q_centre)*mean(df_demostat[:ECYHTAAVG])/agent_profile.age[1] )
    else
        index = dist_array .< ( quantile(dist_array, q_other)*mean(df_demostat[:ECYHTAAVG])/agent_profile.age[1] )
    end
    
    DA_work = sample(df_business_temp[index, :PRCDDA], 
                     fweights(df_business_temp[index, :IEMP_DESC_estimate]))
    
    index = df_DAcentroids[df_DAcentroids[:PRCDDA] .== DA_work, :]
    point_DA_work = index[:LATITUDE][1], index[:LONGITUDE][1]
    
    return DA_id_coord(DA_work, point_DA_work)
    
end


