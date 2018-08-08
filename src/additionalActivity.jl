
###################################
# Additional Activity Selectors
###################################


mutable struct AdditionalActivity
    before
    point_before
    after
    point_after
end



###################################
# schools

"""
Dictionary mapping children age with school category
* `key` : children age intervals from df_demostat and agent profile
* `value` : correspoding school
"""
dict_schoolcategory = Dict(
    "0 To 4" => ["Child Care Facility", "Pre School"],
    "5 To 9" => ["Pre School", "School"],
    "10 To 14" => ["School"],
    "15 To 19" => "too old",
    "20 To 24" => "too old",
)


"""
Checks if an agent has small children and drives them to school and if so, it randomely selects 
a suitable school category (child care facility/pre school/school) for children and returns their locations.

**Arguments**
* `agent_profile` : agent demographic profile::DemoProfile with city_region, children_number_of and children_age
* `DA_home` : DA_home unique id selected for an agent
* `dict_df_DAcentroids` : dictionary of dataframes with :LATITUDE and :LONGITUDE for each DA
* `dict_schoolcategory`  : dictionary mapping children age with school category
* `df_AdditionalActivity`  : a dataframe initially empty for each agent created in additional_activity_selector
* `df_schools`  : schools dataframe along with its location and category 
             
**Assumptions**
- 50% of agents with kids living in the downtown drive children do school
- 75% of agents with kids living in the edge of the city drive children to school
- kids in the same age go to the same school
- if school is closer than 500m from home agents walk the kids to the school
- kids aged 0-3 go to Child Care Facility, kids aged 4-5 go to Pre School, kids aged 6-14 go to School
- kids go to Child Care Facility/Pre School/School located nearest their home.
"""
function additional_activity_schools(agent_profile, DA_home, dict_df_DAcentroids, dict_schoolcategory,
                                     df_AdditionalActivity, df_schools)

    if agent_profile.children_number_of > 0
    
        if agent_profile.city_region == "downtown"
            drive_children = sample(["yes", "no"], pweights([0.5, 0.5])); # println("live in the centre")
        else
            drive_children = sample(["yes", "no"], pweights([0.75, 0.25])); # println("live NOT in the centre")
        end

        if drive_children == "yes"

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

            schoolcat = unique(schoolcat); # println(schoolcat)

            if size(schoolcat, 1) > 0
                df_schools_temp = @where(df_schools, findin(:SUBCAT, Set(schoolcat)))

                df_schools_temp[:dist_array] = distance.(dict_df_DAcentroids[DA_home][1, :ENU], 
                                                         df_schools_temp[:ENU])

                mins = [minimum(df_schools_temp[df_schools_temp[:SUBCAT] .== i, :dist_array]) for i in schoolcat]
                df_schools_temp = @where(df_schools_temp, findin(:dist_array, Set(mins)))
                
                unique!(df_schools_temp, :SUBCAT) # filter different schools for kids in the same age
                unique!(df_schools_temp, :dist_array) # filter schools located in the same place

                for i in 1:size(df_schools_temp, 1)
                    if df_schools_temp[i, :dist_array] > 500
                        push!(df_AdditionalActivity, 
                              ["school", "before", (df_schools_temp[i, :LATITUDE], df_schools_temp[i, :LONGITUDE]),
                               df_schools_temp[i, :SUBCAT], df_schools_temp[i, :dist_array]])
                    end
                end

            end
        end
    end
end



###################################
# popular stores

"""
Checks if an agent goes shopping to any of the popular stores and if so selects a store location

**Arguments**
* `agent_profile` : agent demographic profile::DemoProfile with sex
* `DA_home` : DA_home unique id selected for an agent
* `DA_work` : DA_work unique id selected for an agent
* `dict_df_business_popstores` : dictionary of dataframes with popular shops by category
* `dict_df_DAcentroids` : dictionary of dataframes with :LATITUDE and :LONGITUDE for each DA
* `df_AdditionalActivity`  : a dataframe initially empty for each agent created in additional_activity_selector
* `p_...`  :  probabilities for femaies of going shopping to any of the stores' categories
* `p_shoppingMale`  :  male probability of going shopping - relative to female probabilites
             
**Assumptions**
- calculations based on probabilities of going shopping to different stores per sex
- agent chooses the store located the closest to home or work 

### TODO: 
- agent chooses the store by optimizing the way home-work and based on store size represented by estimated number of employees
- probabilities put into Dict
- different probabilities for males and females
"""
function additional_activity_popularstores(agent_profile, DA_home, DA_work, 
                                           dict_df_business_popstores, dict_df_DAcentroids, df_AdditionalActivity,
                                           p_drugstore, p_petrol_station, p_supermarket, p_convinience, 
                                           p_other_retail, p_grocery, p_discount, p_mass_merchandise, p_shoppingMale)

    if agent_profile.sex == "male"
        p_drugstore        *= p_shoppingMale
        p_petrol_station   *= p_shoppingMale
        p_supermarket      *= p_shoppingMale
        p_convinience      *= p_shoppingMale
        p_other_retail     *= p_shoppingMale    
        p_grocery          *= p_shoppingMale   
        p_discount         *= p_shoppingMale
        p_mass_merchandise *= p_shoppingMale
    end
    
    popstore = []
    push!(popstore, sample(["drugstore", ""], pweights([p_drugstore, 1 - p_drugstore])))
    push!(popstore, sample(["petrol station", ""], pweights([p_petrol_station, 1 - p_petrol_station])))
    push!(popstore, sample(["supermarket", ""], pweights([p_supermarket, 1 - p_supermarket])))
    push!(popstore, sample(["convinience", ""], pweights([p_convinience, 1 - p_convinience])))
    push!(popstore, sample(["other retail", ""], pweights([p_other_retail, 1 - p_other_retail])))
    push!(popstore, sample(["discount", ""], pweights([p_discount, 1 - p_discount])))
    push!(popstore, sample(["grocery", ""], pweights([p_discount, 1 - p_discount])))
    push!(popstore, sample(["mass merchandise", ""], pweights([p_mass_merchandise, 1 - p_mass_merchandise])))
    popstore = popstore[popstore .!= ""]; print(popstore)
    
    
    if size(popstore, 1) > 0
        
        for i in popstore
            dist_shopping_H = distance.(dict_df_DAcentroids[DA_home][1, :ENU], 
                                        dict_df_business_popstores[i][:ENU])
            dist_shopping_W = distance.(dict_df_DAcentroids[DA_work][1, :ENU], 
                                        dict_df_business_popstores[i][:ENU])

            nearest_H = minimum(dist_shopping_H)
            nearest_W = minimum(dist_shopping_W)

            if nearest_H <= nearest_W
                index = dist_shopping_H .== nearest_H
                dist = nearest_H
            else
                index = dist_shopping_W .== nearest_W
                dist = nearest_W
            end

            push!(df_AdditionalActivity, ["shopping", "after", 
                  (dict_df_business_popstores[i][index, :LATITUDE][1], 
                   dict_df_business_popstores[i][index, :LONGITUDE][1]), i, dist])
            
        end
    end
end



###################################
# shopping centres

"""
Checks if an agent goes to the shopping centre based on shopping frequency assumptions and if so 
it selects shopping centre location

**Arguments**
* `agent_profile` : agent demographic profile::DemoProfile with sex
* `DA_home` : DA_home unique id selected for an agent
* `DA_work` : DA_work unique id selected for an agent
* `dict_df_DAcentroids` : dictionary of dataframes with :LATITUDE and :LONGITUDE for each DA
* `df_AdditionalActivity`  : a dataframe initially empty for each agent created in additional_activity_selector
* `df_shopping` : shopping centres dataframe along with its locations and attributes 
* `distance_radius_H`  :  radius around Home within which an agent might go shopping
* `distance_radius_W`  :  radius around Work within which an agent might go shopping
* `p_shoppingcentre`  :  probability of going to shopping centre represented by shopping frequency per week - females
* `p_shoppingMale`  :  male probability of going to shopping centre - relative to female probabilites
             
**Assumptions**
- agent goes to the shopping centre depending on the probability of going shopping for males and females
- agent goes shopping near home if Geographical Potential [GP] for shopping is higher there than near work
- factors affecting GP: number of the shopping centres nearby, distance to the shopping centres, 
their gross leasing area size and the number of anchor stores
- final shopping centre is selected again based on above factors

### TODO: 
- agent chooses the shopping centre also by optimizing the way home-work
- different probabilities for males and females
"""
function additional_activity_shoppingcentre(agent_profile, DA_home, DA_work, 
                                            dict_df_DAcentroids, df_AdditionalActivity, df_shopping,
                                            distance_radius_H, distance_radius_W, 
                                            p_shoppingcentre, p_shoppingMale)

    if agent_profile.sex == "female"
        goes_shopping = sample(["yes", "no"], pweights([p_shoppingcentre, 1 - p_shoppingcentre]))
    else
        goes_shopping = sample(["yes", "no"], pweights([p_shoppingcentre*p_shoppingMale, 
                                                        1 - (p_shoppingcentre*p_shoppingMale)]))
    end
    
    if goes_shopping == "yes"
        
        # select shopping location - near home or near work
        dist_shopping_H = distance.(dict_df_DAcentroids[DA_home][1, :ENU], 
                                    df_shopping[:ENU])
        dist_shopping_W = distance.(dict_df_DAcentroids[DA_work][1, :ENU], 
                                    df_shopping[:ENU])

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
            GP            = GP_H
            dist_array    = dist_shopping_H
        else
            index_nearest = index_nearest_W
            GP            = GP_W
            dist_array    = dist_shopping_W
        end

        if sum(GP) == 0 
            # do nothing

        else        
            df_shopping[:dist_array] = dist_array
            df_shopping_temp = df_shopping[index_nearest, :]
            index = sample(1:size(df_shopping_temp, 1), fweights(GP))

            push!(df_AdditionalActivity, 
                  ["shopping", "after", (df_shopping_temp[index, :LATITUDE][1], 
                   df_shopping_temp[index, :LONGITUDE][1]), 
                   "shopping centre", df_shopping_temp[index, :dist_array]])
        end
    
    end
end



###################################
# recreation complexes

"""
Checks if an agent goes to the recreaton complex based on his demographic profile.
If he goes, a recreation complex is selected based on it's distance from home / work

**Arguments**
* `agent_profile` : agent demographic profile::DemoProfile with sex
* `DA_home` : DA_home unique id selected for an agent
* `DA_work` : DA_work unique id selected for an agent
* `dict_df_DAcentroids` : dictionary of dataframes with :LATITUDE and :LONGITUDE for each DA
* `df_AdditionalActivity`  : a dataframe initially empty for each agent created in additional_activity_selector
* `df_recreationComplex` : recreation complexes dataframe along with its locations and attributes 
* `p_recreation_before`  :  probability of working-out before work
* `p_recreation_F`  :  working-out probability for Females
* `p_recreation_M`  :  working-out probability for Males
* `p_recreation_younger`  :  working-out probability for younger
* `p_recreation_older`  :  working-out probability for older
* `young_old_limit`  :  age at which agents get from younger to older
* `p_recreation_poorer`  :  working-out probability for poorer
* `p_recreation_richer`  :  working-out probability for richer
* `poor_rich_limit`  :  income at which agents get from poorer to richer
             
**Assumptions**
- the probability of working out is calculated based on agent age, sex and income. 
Younger, males and richer people work out more often.
- agent goes to the nearest recreation complex to home or work

### TODO: 
- probabilities to Dict
"""
function additional_activity_recreation(agent_profile, DA_home, DA_work, 
                                        dict_df_DAcentroids, df_AdditionalActivity, df_recreationComplex, , 
                                        p_recreation_before, p_recreation_F, p_recreation_M,
                                        p_recreation_younger, p_recreation_older, young_old_limit,
                                        p_recreation_poorer, p_recreation_richer, poor_rich_limit)
   
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
        dist_recreation_H = distance.(dict_df_DAcentroids[DA_home][1, :ENU], 
                                      df_recreationComplex[:ENU])
        dist_recreation_W = distance.(dict_df_DAcentroids[DA_home][1, :ENU], 
                                      df_recreationComplex[:ENU])
        
        if minimum(dist_recreation_H) < minimum(dist_recreation_W)
            index      = dist_recreation_H .== minimum(dist_recreation_H)
            detail     = "near home"
            dist       = minimum(dist_recreation_H)
        else
            index      = dist_recreation_W .== minimum(dist_recreation_W)
            detail     = "near work"
            dist       = minimum(dist_recreation_W)
        end

        df_recreationComplex_temp = df_recreationComplex[index, :]   
        points_recreation = df_recreationComplex_temp[:LATITUDE][1], 
                            df_recreationComplex_temp[:LONGITUDE][1]
        index = [df_recreationComplex_temp[i][1] == true for i in 1:size(df_recreationComplex_temp, 2)]
        detail = join(names(df_recreationComplex_temp)[index], ", ")
        
        push!(df_AdditionalActivity, ["recreation", when, points_recreation, detail, dist])
    
    end
end



"""
Additional activity selector

Creates df_AdditionalActivity dataframe and returns point_before and point_after on the way 
pointA - point_before - pointB - point_after, if they exist.

** Arguments   
* `routingMode` : TODO explain
* `agent_profile` : TODO explain
* `DA_home` : TODO explain
* `DA_work`  : TODO explain
TODO : explain other args
             
** Assumptions
 - there is max one point_before and max one point_after for each agent
 - model can be extended by introducing more points_before and more points_after based on 
   df_AdditionalActivity dataframe, which already returns multiply before and after points. 
   To do so one should modify below "if" condintion


   
TODO : explain what it does
```julia
routingMode == googlemapsroute ? mode = fastestRoute : mode = routingMode
```


TODO : explain what it does
```julia
findRoutes(pointA, pointB, mapD, network, routingMode = mode)
```

TODO : explain what it does
```julia
find waypoints based on route time/distance optimisation
```

"""
function additional_activity_selector(routingMode, agent_profile, DA_home, DA_work, 
                                    df_recreationComplex, df_schools, df_shopping,
                                    dict_df_business_popstores, dict_df_DAcentroids, dict_schoolcategory, 
                                    distance_radius_H, distance_radius_W, 
                                    p_shoppingcentre, p_shoppingMale,
                                    p_drugstore, p_petrol_station, p_supermarket, p_convinience, 
                                    p_other_retail, p_grocery, p_discount, p_mass_merchandise, 
                                    p_recreation_before, p_recreation_F, p_recreation_M,
                                    p_recreation_younger, p_recreation_older, young_old_limit,
                                    p_recreation_poorer, p_recreation_richer, poor_rich_limit)::AdditionalActivity

    
    df_AdditionalActivity = DataFrame([String, String, Tuple, String, Float64], 
                                   [:what, :when, :coordinates, :details, :distance], 0)
    
    additional_activity_schools(agent_profile, DA_home, dict_df_DAcentroids, dict_schoolcategory,
                                df_AdditionalActivity, df_schools)
    
    additional_activity_popularstores(agent_profile, DA_home, DA_work, 
                                      dict_df_business_popstores, dict_df_DAcentroids, df_AdditionalActivity,
                                      p_drugstore, p_petrol_station, p_supermarket, p_convinience, 
                                      p_other_retail, p_grocery, p_discount, p_mass_merchandise, p_shoppingMale)
    
    additional_activity_shoppingcentre(agent_profile, DA_home, DA_work, 
                                       dict_df_DAcentroids, df_AdditionalActivity, df_shopping,
                                       distance_radius_H, distance_radius_W, 
                                       p_shoppingcentre, p_shoppingMale)
    
    additional_activity_recreation(agent_profile, DA_home, DA_work, 
                                   dict_df_DAcentroids, df_AdditionalActivity, df_recreationComplex, , 
                                   p_recreation_before, p_recreation_F, p_recreation_M,
                                   p_recreation_younger, p_recreation_older, young_old_limit,
                                   p_recreation_poorer, p_recreation_richer, poor_rich_limit)

    before, point_before, after, point_after = "", 0, "", 0

    if size(df_AdditionalActivity, 1) > 0
        
        if any(df_AdditionalActivity[:when] .== "before")
            x = sort!(df_AdditionalActivity[df_AdditionalActivity[:when] .== "before", :], :distance)[1, :]
            before = x[:what][1]
            point_before = x[:coordinates][1]
        end
        
        if any(df_AdditionalActivity[:when] .== "after")
            x = sort!(df_AdditionalActivity[df_AdditionalActivity[:when] .== "after", :], :distance)[1, :]
            after = x[:what][1]
            point_after = x[:coordinates][1]
        end    
    end

    return(AdditionalActivity(before, point_before, after, point_after))
    
end


