
###################################
# Additional Activity Selectors
###################################


# AdditionalActivity = DataFrame([String, String, Tuple, String], [:what, :when, :coordinates, :details], 0)

dict_schoolcategory = Dict(
    "0 To 4" => ["Child Care Facility", "Pre School"],
    "5 To 9" => ["Pre School", "School"],
    "10 To 14" => ["School"],
    "15 To 19" => "too old",
    "20 To 24" => "too old",
)


function additionalActivitySchools(max_distance_from_cc::Int64 = max_distance_from_cc)
    
    # Checks if an agent has small children and drives them to school and if so, it randomely
    # selects a child care facility/pre school/school for children and returns their locations
    
    # Assumptions: 
    # - 50% of agents with kids living near city centre drive children do school
    # - 75% of agents with kids living in the edge of the city drive children to school
    # - kids in the same age go to the same school
    
    # Args:
    # - max_distance_from_cc - maximum distance from DA_home to city_centre to assume DA_home is in the downtown
    
    # Objects used in the function: 
    # - agent_profile - agent demographic profile::DemoProfile with city_region, children_number_of and children_age
    # - df_schools - schools dataframe along with its location and category 
    # - df_DAcentroids - dataframe with :LATITUDE and :LONGITUDE for each DA_id
    # - df_demostat - dataframe with population statistics for each DA_id
    # - city_centre_ECEF - city centre ECEF coordinates
    # - DA_home - DA_home unique id (DA_id) selected for an agent
    # - dict_schoolcategory - dictionary mapping children age with school category
    
     # Function, in case of any adjustments, should be modified within its body

    if agent_profile.children_number_of > 0
    
        if agent_profile.city_region == "downtown"
            drive_children = sample(["yes", "no"], pweights([0.5, 0.5])); # println("live in the centre")
        else
            drive_children = sample(["yes", "no"], pweights([0.75, 0.25])); # println("live NOT in the centre")
        end


        if drive_children == "no"
            # do nothing
            # println("don't drive children")

        else
            schoolcat = []
            if any(agent_profile.children_age .== "0 To 4")
                x = sample(["Child Care Facility", "Pre School"], pweights([0.80, 0.20]))
                push!(schoolcat, x)
            end
            if any(agent_profile.children_age .== "5 To 9")
                x = sample(["Pre School", "School"], pweights([0.20, 0.80]))
                push!(schoolcat, x)
            end
            if any(agent_profile.children_age .== "10 To 14")
                push!(schoolcat, "School")
            end

            schoolcat = unique(schoolcat); #println(schoolcat)

            if size(schoolcat, 1) > 0
                index_schoolcat = [(df_schools[:SUBCAT][i] in schoolcat) for i in 1:size(df_schools, 1)]
                df_schools_temp = df_schools[index_schoolcat, :]

                df_schools_temp[:dist_array] = distance.(df_DAcentroids[df_DAcentroids[:PRCDDA] .== DA_home, :ECEF][1], 
                                                         df_schools_temp[:ECEF])

                index_min = [minimum(df_schools_temp[df_schools_temp[:SUBCAT] .== i, :dist_array]) for i in schoolcat]

                index_points = [(df_schools_temp[:dist_array][i] in index_min) for i in 1:size(df_schools_temp, 1)]

                df_schools_temp = df_schools_temp[index_points, :]
                unique!(df_schools_temp, :SUBCAT)

                for i in 1:size(df_schools_temp, 1)
                    push!(AdditionalActivity, 
                          ["school", "before", (df_schools_temp[i, :LATITUDE], df_schools_temp[i, :LATITUDE]),
                            df_schools_temp[i, :SUBCAT]])
                end

            end
        end
    end
end



function additionalActivityShopping(p_shopping_F::Float64 = p_shopping_F,
                                    p_shopping_M::Float64 = p_shopping_M,
                                    distance_radius_H::Int = distance_radius_H,
                                    distance_radius_W::Int = distance_radius_W)
    
    # Checks if an agent goes shopping based on shopping frequency assumptions and if so
    # selects shopping centre location
    
    # Assumptions: 
    # - agent goes shopping depending on the probability of going shopping for males and females
    # - agent goes shopping near home if Geographical Potential [GP] for shopping is higher there than near work
    # - factors affecting GP: number of the shopping centres nearby, distance to the shopping centres,
    # their gross leasing area size and the number of anchor stores
    # - final shopping centre is selected again based on above factors
    
    # Args:
    # - p_shopping_F - shopping probability represented by shopping frequency per week - Females
    # - p_shopping_M - shopping probability represented by shopping frequency per week - Males
    # - distance_radius_H - radius around Home within which an agent might go shopping
    # - distance_radius_W - radius around Work within which an agent might go shopping
    
    # Objects used in the function: 
    # - agent_profile - agent demographic profile::DemoProfile with sex
    # - df_shopping - shopping centres dataframe along with its locations and attributes 
    # - df_DAcentroids - dataframe with :LATITUDE and :LONGITUDE for each DA_id
    # - DA_home - DA_home unique id (DA_id) selected for an agent
    # - DA_work - DA_work unique id (DA_id) selected for an agent
    
    # Function, in case of any adjustments, should be modified within its body

    if agent_profile.sex == "male"
        goes_shopping = sample(["yes", "no"], pweights([p_shopping_F, 1-p_shopping_F]))
    else
        goes_shopping = sample(["yes", "no"], pweights([p_shopping_M, 1-p_shopping_M]))
    end
    
    if goes_shopping == "yes"
        
        # select shopping location - near home or near work
        dist_shopping_H = distance.(df_DAcentroids[df_DAcentroids[:PRCDDA] .== DA_home, :ECEF][1], 
                                    df_shopping[:ECEF])
        dist_shopping_W = distance.(df_DAcentroids[df_DAcentroids[:PRCDDA] .== DA_work, :ECEF][1], 
                                    df_shopping[:ECEF])

        index_nearest_H = dist_shopping_H .< distance_radius_H
        index_nearest_W = dist_shopping_W .< distance_radius_W

        # println("index_nearest_H sum ", sum(index_nearest_H), "index_nearest_W sum ", sum(index_nearest_W))

        # geographical potential for shopping
        GP_H = (df_shopping[index_nearest_H, :gla] ./ dist_shopping_H[index_nearest_H] + 
                df_shopping[index_nearest_H, :anch_cnt])
        GP_W = (df_shopping[index_nearest_W, :gla] ./ dist_shopping_W[index_nearest_W] + 
                df_shopping[index_nearest_W, :anch_cnt])

        # println("GP_H ", GP_H, "GP_W", GP_W)
        # println(sum(GP_H), sum(GP_W))

        if sum(GP_H) > sum(GP_W)
            index_nearest = index_nearest_H
            GP = GP_H
            detail = "near home"
        else
            index_nearest = index_nearest_W
            GP = GP_W
            detail = "near work"
        end

        if sum(GP) == 0 
            # do nothing

        else        
            df_shopping_temp = df_shopping[index_nearest, :]
            index = sample(1:size(df_shopping_temp, 1), fweights(GP))

            points_shopping = tuple(df_shopping_temp[index, :LATITUDE], df_shopping_temp[index, :LONGITUDE])

            push!(AdditionalActivity, ["shopping", "after", points_shopping, detail])
        end
    
    end
end



function additionalActivityRecreation(p_recreation_before::Float64 = p_recreation_before,
                                      p_recreation_F::Float64 = p_recreation_F,
                                      p_recreation_M::Float64 = p_recreation_M,
                                      p_recreation_younger::Float64 = p_recreation_younger,
                                      p_recreation_older::Float64 = p_recreation_older,
                                      young_old_limit::Int = young_old_limit,
                                      p_recreation_poorer::Float64 = p_recreation_poorer,
                                      p_recreation_richer::Float64 = p_recreation_richer,
                                      poor_rich_limit::Int = poor_rich_limit)
    
    # Checks if an agent goes to the recreaton complex based on his demographic profile.
    # If he goes, a recreation complex is selected based on it's distance from home / work
    
    # Assumptions: 
    # - the probability of working out is calculated based on agent age, sex and income
    # - agent goes to the nearest recreation complex to home or work
    
    # Args:
    # - p_recreation_before - probability of working-out before work
    # - p_recreation_F / p_recreation_M - working-out probability for Females/Males
    # - p_recreation_younger/p_recreation_older - working-out probability for younger/older
    # - young_old_limit - age at which agents get from younger to older
    # - p_recreation_poorer/richer - working-out probability for poorer/richer
    # - poor_rich_limit - income at which agents get from poorer to richer
    
    # Objects used in the function: 
    # - agent_profile - agent demographic profile::DemoProfile with sex, age and income
    # - df_recreationComplex - recreation complexes dataframe along with its locations and attributes 
    # - df_DAcentroids - dataframe with :LATITUDE and :LONGITUDE for each DA_id
    # - DA_home - DA_home unique id (DA_id) selected for an agent
    # - DA_work - DA_work unique id (DA_id) selected for an agent
    
    # Function, in case of any adjustments, should be modified within its body
   
    if agent_profile.sex == "female" 
        p_sex = p_recreation_F
    else
        p_sex = p_recreation_M
    end
    
    if agent_profile.age < young_old_limit
        p_age = p_recreation_younger
    else
        p_age = p_recreation_older
    end
    
    if agent_profile.household_income < poor_rich_limit
        p_income = p_recreation_poorer
    else
        p_income = p_recreation_richer
    end
    
    working_out = sample(["yes", "no"], pweights([p_sex*p_age*p_income, 1-p_sex*p_age*p_income]))
    
    if working_out == "yes"
        
        when = sample(["before", "after"], pweights([p_recreation_before, 1-p_recreation_before]))
        
        # select recreation centre location - near home or near work
        dist_recreation_H = distance.(df_DAcentroids[df_DAcentroids[:PRCDDA] .== DA_home, :ECEF][1], 
                                      df_recreationComplex[:ECEF])
        dist_recreation_W = distance.(df_DAcentroids[df_DAcentroids[:PRCDDA] .== DA_work, :ECEF][1], 
                                      df_recreationComplex[:ECEF])
        
        if minimum(dist_recreation_H) < minimum(dist_recreation_W)
            index = dist_recreation_H .== minimum(dist_recreation_H)
            detail = "near home"
        else
            index = dist_recreation_W .== minimum(dist_recreation_W)
            detail = "near work"
        end

        df_recreationComplex_temp = df_recreationComplex[index, :]
        x = split(df_recreationComplex_temp[:Location][1], ",")
        points_recreation = tuple(parse(Float64, replace(x[1], "(" => "")), 
                                  parse(Float64, replace(x[2], ")" => "")),)
        index = [df_recreationComplex_temp[i][1] == true for i in 1:size(df_recreationComplex_temp, 2)]
        detail = join(names(df_recreationComplex_temp)[index], ", ")
            
            push!(AdditionalActivity, ["recreation", when, points_recreation, detail])
    
    end
end



function additionalActivitySelector()
    additionalActivitySchools()
    additionalActivityShopping()
    additionalActivityRecreation()
end


