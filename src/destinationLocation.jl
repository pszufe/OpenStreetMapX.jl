
###################################
# Destination Location Selectors
###################################


###################################
## Selection based on Journey Matrix 
function destinationLocationSelectorJM(DA_home, dict_df_DAcentroids, dict_df_hwflows)::DA_id_coord
    
    # Selects destination DA_work for an agent randomly weighted by Pij Journey Matrix
    
    # Args:
    # - DA_home - DA_home unique id selected for an agent
    # - dict_df_DAcentroids - dictionary of dataframes with :LATITUDE and :LONGITUDE for each DA
    # - dict_df_hwflows - dataframe representing Pij Journej Matrix with *FlowVolume* from *DA_home* to *DA_work*
   
    df_hwflows = dict_df_hwflows[DA_home]
    DA_work = sample(df_hwflows[:DA_work], fweights(df_hwflows[:FlowVolume]))
    point_DA_work = dict_df_DAcentroids[DA_work][1, :LATITUDE], 
                    dict_df_DAcentroids[DA_work][1, :LONGITUDE]
    
    return DA_id_coord(DA_work, point_DA_work)
end



###################################
## Selection based on agent's Demographic Profile

# DA_work selected by randomely choosing the company (business) where agent work based on 
# - agent work_industry profile
# - distance between DA_home and the city centre
# - distance between DA_home and business location 
# - agent_age-based weigths
# - company size weights represented by randomely estimated number of employees


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


function destinationLocationSelectorDP(agent_profile, DA_home, df_business, dict_df_DAcentroids, 
                                       dict_df_demostat, dict_industry, q_centre, q_other)::DA_id_coord
    
    # Selects destination DA_work for an agent by randomly choosing the company he works in
    
    # Assumptions based on agent demographic profile:
    # - agents work in the business in accordance with their work_industry
    # - agents living in the city centre tend to work near home - calculated based on the quantiles 
    # of the distance array between home location and industry-related businesses locations
    # - older agents and women-agents tend to work rather closer to home 
    
    # Args:
    # - agent_profile - agent demographic profile::DemoProfile with city_region, work_industy and age
    # - DA_home - DA_home unique id selected for an agent
    # - df_business - business dataframe along with its location, industry and estimated number of employees
    # - dict_df_DAcentroids - dictionary of dataframes with :LATITUDE and :LONGITUDE for each DA
    # - dict_df_demostat - dictionary of dataframes with population statistics for each DA
    # - dict_industry - dictionary matching industry demographic data from df_business with
    # the ones selected for an agent (in agent_profile.work_industry)
    # - q_centre - max quantile of the home - business distance for agents living in the downtown 
    # - q_other - max quantile of the home - business distance for agents not living in the downtown 
 
    # Other objects:
    # df_business[:ICLS_DESC] - "Number of employees" intervals
    # dict_df_demostat[DA_home][1, :ECYHTAAVG] - "Average Age Of Total Household Population"
    
    # Function, in case of any adjustments, should be modified within its body
    
    # industry assumption:
    df_business_temp = @where(df_business, findin(:ICLS_DESC, Set(dict_industry[agent_profile.work_industry])))
    
    # all other assumptions:
    dist_array = distance.(dict_df_DAcentroids[DA_home][1, :ENU], df_business_temp[:ENU])
    avg_age = dict_df_demostat[DA_home][1, :ECYHTAAVG]
    
    if agent_profile.city_region == "downtown"
        index = dist_array .< ( quantile(dist_array, q_centre)*avg_age/agent_profile.age )
        df_business_temp = df_business_temp[index, :]
    else
        index = dist_array .< ( quantile(dist_array, q_other)*avg_age/agent_profile.age )
        df_business_temp = df_business_temp[index, :]
    end
    
    # Estimate the number of employees for each business based on "Number of employees" intervals
        # assumption: if there is no information concerning number of employees, this number is set to 1
        # most of such businesses are ATMs, so the probability of selecting any of them should be low
    intervals = [split(replace(i, "," => "")) for i in df_business_temp[:IEMP_DESC]]
    IEMP_DESC_estimate = zeros(Int, size(intervals, 1))
    for i in 1:size(intervals, 1)
        intervals[i][1] .== "NA" ? IEMP_DESC_estimate[i] = 1 : 
            IEMP_DESC_estimate[i] = rand(parse(Int, intervals[i][1]):parse(Int, intervals[i][3]))
    end

    DA_work = sample(df_business_temp[:PRCDDA], fweights(IEMP_DESC_estimate))
    point_DA_work = dict_df_DAcentroids[DA_work][1, :LATITUDE], 
                    dict_df_DAcentroids[DA_work][1, :LONGITUDE]
    
    return DA_id_coord(DA_work, point_DA_work)
    
end


