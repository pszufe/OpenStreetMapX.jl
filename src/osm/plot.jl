########################################################
### Functions for Plotting Using the Winston Package ###
########################################################

################################
### Styles Used for Plotting ###
################################

const Styles = Union{OpenStreetMap.Style,Dict{Int,OpenStreetMap.Style}}
gr();

const gr_linestyles = Dict("-" => :solid, ":"=>:dot, ";"=>:dashdot, "-."=>:dashdot,"--"=>:dash)                                                                                               ####################
### Aspect Ratio ###
####################

### Compute approximate "aspect ratio" at mean latitude ###

function aspect_ratio(bounds::OpenStreetMap.Bounds{OpenStreetMap.LLA})
    c_adj = cosd((bounds.min_y + bounds.max_y) / 2)
    range_y = bounds.max_y - bounds.min_y
    range_x = bounds.max_x - bounds.min_x
    return range_x * c_adj / range_y
end

### Compute exact "aspect ratio" ###
aspect_ratio(bounds::OpenStreetMap.Bounds{OpenStreetMap.ENU}) = (bounds.max_x - bounds.min_x) / (bounds.max_y - bounds.min_y)

#################
### Draw Ways ###
#################

### Without defined layers ###

function draw_ways!(p::Plots.Plot,nodes::Dict{Int,T}, ways::Vector{OpenStreetMap.Way}, style::OpenStreetMap.Styles,km::Bool) where T<:Union{OpenStreetMap.LLA,OpenStreetMap.ENU}
    for way in ways
        X = [OpenStreetMap.getX(nodes[node]) for node in way.nodes]
        Y = [OpenStreetMap.getY(nodes[node]) for node in way.nodes]
        if isa(nodes,Dict{Int,OpenStreetMap.ENU}) && km
            X /= 1000
            Y /= 1000
        end
        #length(X) > 1 && Plots.plot(p, X, Y, style.spec, color=style.color, linewidth=style.width)
		length(X) > 1 && Plots.plot!(p, X, Y, color=style.color,width=style.width,linestyle=gr_linestyles[style.spec])
    end
end

### With defined Layers ###

function draw_ways!(p::Plots.Plot,nodes::Dict{Int,T}, ways::Vector{OpenStreetMap.Way},class::Dict{Int,Int}, style::OpenStreetMap.Styles,km::Bool) where T<:Union{OpenStreetMap.LLA,OpenStreetMap.ENU}
    for i = 1:length(ways)
        lineStyle = style[class[ways[i].id]]
        X = [OpenStreetMap.getX(nodes[node]) for node in ways[i].nodes]
        Y = [OpenStreetMap.getY(nodes[node]) for node in ways[i].nodes]
        if isa(nodes,Dict{Int,OpenStreetMap.ENU}) && km
            X /= 1000
            Y /= 1000
        end
        #length(X) > 1 && Winston.plot(p, X, Y, lineStyle.spec, color=lineStyle.color, linewidth=lineStyle.width)
		length(X) > 1 && Plots.plot!(p, X, Y, color=lineStyle.color,width=lineStyle.width,linestyle=gr_linestyles[lineStyle.spec])
    end
end

######################
### Draw Buildings ###
######################

function draw_buildings!(p::Plots.Plot,nodes::Dict{Int,T}, buildings::Vector{OpenStreetMap.Way}, style::OpenStreetMap.Styles,km::Bool) where T<:Union{OpenStreetMap.LLA,OpenStreetMap.ENU}
    if isa(style, OpenStreetMap.Style)
        OpenStreetMap.draw_ways!(p,nodes,buildings,style,km)
    else
        classes = OpenStreetMap.classify_buildings(buildings)
        OpenStreetMap.draw_ways!(p,nodes,buildings, classes, style,km)
    end
end

#####################
### Draw Roadways ###
#####################

function draw_roadways!(p::Plots.Plot,nodes::Dict{Int,T}, roadways::Vector{OpenStreetMap.Way}, style::OpenStreetMap.Styles,km::Bool) where T<:Union{OpenStreetMap.LLA,OpenStreetMap.ENU}
    if isa(style, OpenStreetMap.Style)
        OpenStreetMap.draw_ways!(p,nodes,roadways,style,km)
    else
        classes = OpenStreetMap.classify_roadways(roadways)
        OpenStreetMap.draw_ways!(p,nodes,roadways, classes, style,km)
    end
end

#####################
### Draw Walkways ###
#####################

function draw_walkways!(p::Plots.Plot,nodes::Dict{Int,T}, walkways::Vector{OpenStreetMap.Way}, style::OpenStreetMap.Styles,km::Bool) where T<:Union{OpenStreetMap.LLA,OpenStreetMap.ENU}
    if isa(style, OpenStreetMap.Style)
        OpenStreetMap.draw_ways!(p,nodes,walkways,style,km)
    else
        classes = OpenStreetMap.classify_walkways(walkways)
        OpenStreetMap.draw_ways!(p,nodes,walkways, classes, style,km)
    end
end

######################
### Draw Cycleways ###
######################

function draw_cycleways!(p::Plots.Plot,nodes::Dict{Int,T}, cycleways::Vector{OpenStreetMap.Way}, style::OpenStreetMap.Styles,km::Bool) where T<:Union{OpenStreetMap.LLA,OpenStreetMap.ENU}
    if isa(style, OpenStreetMap.Style)
        OpenStreetMap.draw_ways!(p,nodes,cycleways,style,km)
    else
        classes = OpenStreetMap.classify_cycleways(cycleways)
        OpenStreetMap.draw_ways!(p,nodes,cycleways, classes, style,km)
    end
end

#####################
### Draw Features ###
#####################

function draw_features!(p::Plots.Plot,nodes::Dict{Int,T}, features::Dict{Int,Tuple{String,String}}, style::OpenStreetMap.Styles,km::Bool) where T<:Union{OpenStreetMap.LLA,OpenStreetMap.ENU}
    if isa(style, OpenStreetMap.Style)
        X = [OpenStreetMap.getX(nodes[node]) for node in keys(features)]
        Y = [OpenStreetMap.getY(nodes[node]) for node in keys(features)]
        if isa(nodes,Dict{Int,OpenStreetMap.ENU}) && km
                X /= 1000
                Y /= 1000
        end
        #length(X) > 1 && Winston.plot(p, X, Y, style.spec, color=style.color, linewidth=style.width)
		length(X) > 1 && Plots.plot!(p, X, Y, color=style.color,width=style.width,linestyle=gr_linestyles[style.spec])
    else
        classes = OpenStreetMap.classify_features(features)
        for (key,val) in style
            indices = [id for id in keys(classes) if classes[id] == key]
            X = [OpenStreetMap.getX(nodes[node]) for node in indices]
            Y = [OpenStreetMap.getY(nodes[node]) for node in indices]
            if isa(nodes,Dict{Int,OpenStreetMap.ENU}) && km
                X /= 1000
                Y /= 1000
            end
            #length(X) > 1 && Winston.plot(p, X, Y, val.spec, color=val.color, linewidth=val.width)
			length(X) > 1 && Plots.plot!(p, X, Y, color=val.color,width=val.width,linestyle=gr_linestyles[val.spec])
        end
    end
end

########################
### Generic Map Plot ###
########################
function plotmap(nodes::Dict{Int,T},
                                    bounds::Union{Nothing,OpenStreetMap.Bounds{T}} = nothing;
                                    buildings::Union{Nothing,Vector{OpenStreetMap.Way}} = nothing,
                                    buildingStyle::Styles=OpenStreetMap.Style("0x000000", 1, "-"),
                                    roadways::Union{Nothing,Vector{OpenStreetMap.Way}} = nothing,
                                    roadwayStyle::Styles=OpenStreetMap.Style("0x007CFF", 1.5, "-"),
                                    walkways::Union{Nothing,Vector{OpenStreetMap.Way}} = nothing,
                                    walkwayStyle::Styles=OpenStreetMap.Style("0x007CFF", 1.5, "-"),
                                    cycleways::Union{Nothing,Vector{OpenStreetMap.Way}} = nothing,
                                    cyclewayStyle::Styles=OpenStreetMap.Style("0x007CFF", 1.5, "-"),
                                    features::Union{Nothing,Dict{Int64,Tuple{String,String}}} = nothing,
                                    featureStyle::Styles=OpenStreetMap.Style("0xCC0000", 2.5, "."),
                                    width::Int=600,
									height::Int=600,								
                                    fontsize::Integer=0,
                                    km::Bool=false) where T<:Union{OpenStreetMap.LLA,OpenStreetMap.ENU}
    # Chose labels according to point type and scale
    xlab, ylab = if isa(nodes, Dict{Int,OpenStreetMap.LLA})
        "Longitude (deg)", "Latitude (deg)"
    elseif km
        "East (km)", "North (km)"
    else
        "East (m)", "North (m)"
    end
    # Calculating aspect Ratio:
    #height = isa(bounds,Nothing) ? width : round(Int, width / aspect_ratio(bounds))
    #if Winston.output_surface != :none # Allow for plotting in IJulia/Jupyter to work
        # Create the figure
        #fig = Winston.figure(name="OpenStreetMap Plot", width=width, height=height)
    #end
    if isa(bounds,Nothing)
		p = Plots.plot(xlabel=xlab,ylabel=ylab,legend=false,size=(width,height))
    else # Limit plot to specified bounds
        #Winston.xlim(bounds.min_x, bounds.max_x)
        #Winston.ylim(bounds.min_y, bounds.max_y)
        if km && isa(nodes, Dict{Int,OpenStreetMap.ENU})
            xrange = (bounds.min_x/1000, bounds.max_x/1000)
            yrange = (bounds.min_y/1000, bounds.max_y/1000)
        else
            xrange = (bounds.min_x, bounds.max_x)
            yrange = (bounds.min_y, bounds.max_y)
        end
        p = Plots.plot(xlabel=xlab,ylabel=ylab,xlims=xrange,ylims=yrange,legend=false,size=(width,height))
    end
    # Draw all buildings
    if !isa(buildings,Nothing)
        OpenStreetMap.draw_buildings!(p,nodes, buildings, buildingStyle, km)
    end
    # Draw all roadways
    if !isa(roadways,Nothing)
        OpenStreetMap.draw_roadways!(p,nodes, roadways, roadwayStyle, km)
    end
    # Draw all walkways
    if !isa(walkways,Nothing)
        OpenStreetMap.draw_walkways!(p,nodes, walkways, walkwayStyle, km)
    end
    # Draw all cycleways
    if !isa(cycleways,Nothing)
        OpenStreetMap.draw_cycleways!(p,nodes, cycleways, cyclewayStyle, km)
    end
    #Draw all features
    if !isa(features,Nothing)
        OpenStreetMap.draw_features!(p,nodes, features, featureStyle, km)
    end
    if fontsize > 0
        attr = Dict(:fontsize => fontsize)
        #Winston.setattr(p.x1, "label_style", attr)
        #Winston.setattr(p.y1, "label_style", attr)
        #Winston.setattr(p.x1, "ticklabels_style", attr)
        #Winston.setattr(p.y1, "ticklabels_style", attr)
    end
    return p
end

##########################
### Add Routes to Plot ###
##########################

function addroute!(p::Plots.Plot, nodes::Dict{Int,T}, route::Vector{Int}; route_color::String ="0x000053", km::Bool=false) where T<:Union{OpenStreetMap.LLA,OpenStreetMap.ENU}
    route_style = OpenStreetMap.Style(route_color, 3, ";")
    X = [OpenStreetMap.getX(nodes[node]) for node in route]
    Y = [OpenStreetMap.getY(nodes[node]) for node in route]
    if isa(nodes,Dict{Int,OpenStreetMap.ENU}) && km
        X /= 1000
        Y /= 1000
    end
    #length(X) > 1 && Winston.plot(p, X, Y, route_style.spec, color=route_style.color, linewidth=route_style.width)
	if length(X) > 1 
		Plots.plot!(p, X, Y, color=route_style.color,width=route_style.width,linestyle=gr_linestyles[route_style.spec])
		Plots.annotate!(p,X[1],Y[1],text("A",15))
		Plots.annotate!(p,X[end],Y[end],text("B",15))		
	end
	
end
