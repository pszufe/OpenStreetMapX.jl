########################################################
### Functions for Plotting Using the Winston Package ###
########################################################

################################
### Styles Used for Plotting ###
################################

const Styles = Union{Style,Dict{Int,Style}}

####################
### Aspect Ratio ###
####################

### Compute approximate "aspect ratio" at mean latitude ###

function aspectRatio(bounds::OpenStreetMap.Bounds{LLA})
    c_adj = cosd((bounds.min_y + bounds.max_y) / 2)
    range_y = bounds.max_y - bounds.min_y
    range_x = bounds.max_x - bounds.min_x
    return range_x * c_adj / range_y
end

### Compute exact "aspect ratio" ###
aspectRatio(bounds::OpenStreetMap.Bounds{ENU}) = (bounds.max_x - bounds.min_x) / (bounds.max_y - bounds.min_y)

#################
### Draw Ways ###
#################

### Without defined layers ###

function drawWays!{T<:Union{LLA,ENU}}(p::Winston.FramedPlot,nodes::Dict{Int,T}, ways::Vector{OpenStreetMap.Way}, style::Styles,km::Bool)
    for way in ways
        X = [getX(nodes[node]) for node in way.nodes]
        Y = [getY(nodes[node]) for node in way.nodes]
        if isa(nodes,Dict{Int,ENU}) && km
            X /= 1000
            Y /= 1000
        end
        length(X) > 1 && Winston.plot(p, X, Y, style.spec, color=style.color, linewidth=style.width)
    end
end

### With defined Layers ###

function drawWays!{T<:Union{LLA,ENU}}(p::Winston.FramedPlot,nodes::Dict{Int,T}, ways::Vector{OpenStreetMap.Way},class::Dict{Int,Int}, style::Styles,km::Bool)
    for i = 1:length(ways)
        lineStyle = style[class[ways[i].id]]
        X = [getX(nodes[node]) for node in ways[i].nodes]
        Y = [getY(nodes[node]) for node in ways[i].nodes]
        if isa(nodes,Dict{Int,ENU}) && km
            X /= 1000
            Y /= 1000
        end
        length(X) > 1 && Winston.plot(p, X, Y, lineStyle.spec, color=lineStyle.color, linewidth=lineStyle.width)
    end
end

######################
### Draw Buildings ###
######################

function drawBuildings!{T<:Union{LLA,ENU}}(p::Winston.FramedPlot,nodes::Dict{Int,T}, buildings::Vector{OpenStreetMap.Way}, style::Styles,km::Bool)
    if isa(style, Style)
        drawWays!(p,nodes,buildings,style,km)
    else
        classes = classifyBuildings(buildings)
        drawWays!(p,nodes,buildings, classes, style,km)
    end
end

#####################
### Draw Roadways ###
#####################

function drawRoadways!{T<:Union{LLA,ENU}}(p::Winston.FramedPlot,nodes::Dict{Int,T}, roadways::Vector{OpenStreetMap.Way}, style::Styles,km::Bool)
    if isa(style, Style)
        drawWays!(p,nodes,roadways,style,km)
    else
        classes = classifyRoadways(roadways)
        drawWays!(p,nodes,roadways, classes, style,km)
    end
end

#####################
### Draw Walkways ###
#####################

function drawWalkways!{T<:Union{LLA,ENU}}(p::Winston.FramedPlot,nodes::Dict{Int,T}, walkways::Vector{OpenStreetMap.Way}, style::Styles,km::Bool)
    if isa(style, Style)
        drawWays!(p,nodes,walkways,style,km)
    else
        classes = classifyWalkways(walkways)
        drawWays!(p,nodes,walkways, classes, style,km)
    end
end

######################
### Draw Cycleways ###
######################

function drawCycleways!{T<:Union{LLA,ENU}}(p::Winston.FramedPlot,nodes::Dict{Int,T}, cycleways::Vector{OpenStreetMap.Way}, style::Styles,km::Bool)
    if isa(style, Style)
        drawWays!(p,nodes,cycleways,style,km)
    else
        classes = classifyCycleways(cycleways)
        drawWays!(p,nodes,cycleways, classes, style,km)
    end
end

#####################
### Draw Features ###
#####################

function drawFeatures!{T<:Union{LLA,ENU}}(p::Winston.FramedPlot,nodes::Dict{Int,T}, features::Dict{Int,Tuple{String,String}}, style::Styles,km::Bool)
    if isa(style, Style)
        X = [getX(nodes[node]) for node in keys(features)]
        Y = [getY(nodes[node]) for node in keys(features)]
        if isa(nodes,Dict{Int,ENU}) && km
                X /= 1000
                Y /= 1000
        end
        length(X) > 1 && Winston.plot(p, X, Y, style.spec, color=style.color, linewidth=style.width) 
    else
        classes = classifyFeatures(features)
        for (key,val) in style
            indices = [id for id in keys(classes) if classes[id] == key]
            X = [getX(nodes[node]) for node in indices]
            Y = [getY(nodes[node]) for node in indices]
            if isa(nodes,Dict{Int,ENU}) && km
                X /= 1000
                Y /= 1000
            end
            length(X) > 1 && Winston.plot(p, X, Y, val.spec, color=val.color, linewidth=val.width) 
        end
    end
end

########################
### Generic Map Plot ###
########################

function plotMap{T<:Union{LLA,ENU}}(nodes::Dict{Int,T},
                                    bounds::Union{Void,OpenStreetMap.Bounds} = nothing;
                                    buildings::Union{Void,Vector{OpenStreetMap.Way}} = nothing,
                                    buildingStyle::Styles=Style(0x000000, 1, "-"),
                                    roadways::Union{Void,Vector{OpenStreetMap.Way}} = nothing,
                                    roadwayStyle::Styles=Style(0x007CFF, 1.5, "-"),
                                    walkways::Union{Void,Vector{OpenStreetMap.Way}} = nothing,
                                    walkwayStyle::Styles=Style(0x007CFF, 1.5, "-"),
                                    cycleways::Union{Void,Vector{OpenStreetMap.Way}} = nothing,
                                    cyclewayStyle::Styles=Style(0x007CFF, 1.5, "-"),
                                    features::Union{Void,Dict{Int64,Tuple{String,String}}} = nothing,
                                    featureStyle::Styles=Style(0xCC0000, 2.5, "."),
                                    width::Int=500,
                                    fontsize::Integer=0,
                                    km::Bool=false)
    # Chose labels according to point type and scale
    xlab, ylab = if isa(nodes, Dict{Int,LLA})
        "Longitude (deg)", "Latitude (deg)"
    elseif km
        "East (km)", "North (km)"
    else
        "East (m)", "North (m)"
    end
    # Calculating aspect Ratio:
    height = isa(bounds,Void) ? width : round(Int, width / aspectRatio(bounds))
    if Winston.output_surface != :none # Allow for plotting in IJulia/Jupyter to work
        # Create the figure
        fig = Winston.figure(name="OpenStreetMap Plot", width=width, height=height)
    end
    if isa(bounds,Void)
        p = Winston.FramedPlot("xlabel", xlab, "ylabel", ylab)
    else # Limit plot to specified bounds
        Winston.xlim(bounds.min_x, bounds.max_x)
        Winston.ylim(bounds.min_y, bounds.max_y)
        if km && isa(nodes, Dict{Int,ENU})
            xrange = (bounds.min_x/1000, bounds.max_x/1000)
            yrange = (bounds.min_y/1000, bounds.max_y/1000)
        else
            xrange = (bounds.min_x, bounds.max_x)
            yrange = (bounds.min_y, bounds.max_y)
        end
        p = Winston.FramedPlot("xlabel", xlab, "ylabel", ylab, xrange=xrange, yrange=yrange)
    end
    # Draw all buildings
    if !isa(buildings,Void)
        drawBuildings!(p,nodes, buildings, buildingStyle, km)
    end
    # Draw all roadways
    if !isa(roadways,Void)
        drawRoadways!(p,nodes, roadways, roadwayStyle, km)
    end
    # Draw all walkways
    if !isa(walkways,Void)
        drawWalkways!(p,nodes, walkways, walkwayStyle, km)
    end
    # Draw all cycleways
    if !isa(cycleways,Void)
        drawCycleways!(p,nodes, cycleways, cyclewayStyle, km)
    end
    #Draw all features
    if !isa(features,Void)
        drawFeatures!(p,nodes, features, featureStyle, km)
    end
    if fontsize > 0
        attr = Dict(:fontsize => fontsize)
        Winston.setattr(p.x1, "label_style", attr)
        Winston.setattr(p.y1, "label_style", attr)
        Winston.setattr(p.x1, "ticklabels_style", attr)
        Winston.setattr(p.y1, "ticklabels_style", attr)
    end
    return p
end

##########################
### Add Routes to Plot ###
##########################

function addRoute!{T<:Union{LLA,ENU}}(p::Winston.FramedPlot, nodes::Dict{Int,T}, route::Vector{Int}; routeColor::UInt32 =0x000053, km::Bool=false)
    routeStyle = Style(routeColor, 3, "-")
    X = [getX(nodes[node]) for node in route]
    Y = [getY(nodes[node]) for node in route]
    if isa(nodes,Dict{Int,ENU}) && km
        X /= 1000
        Y /= 1000
    end
    length(X) > 1 && Winston.plot(p, X, Y, routeStyle.spec, color=routeStyle.color, linewidth=routeStyle.width)
end