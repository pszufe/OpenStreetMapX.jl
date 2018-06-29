### Julia OpenStreetMap Package ###
### MIT License                 ###
### Copyright 2014              ###

### Functions for plotting using the Winston package ###

const Styles = @compat Union{Style,Dict{Int,Style}}

### Generic Map Plot ###
function plotMap(nodes::@compat(Union{Dict{Int,LLA},Dict{Int,ENU}}) ;
                 highways::@compat(Union{@compat(Void),Dict{Int,Highway}}) = nothing,
                 buildings::@compat(Union{@compat(Void),Dict{Int,Building}}) = nothing,
                 features::@compat(Union{@compat(Void),Dict{Int,Feature}}) = nothing,
                 bounds::@compat(Union{@compat(Void),Bounds}) = nothing,
                 intersections::@compat(Union{@compat(Void),Dict{Int,Intersection}}) = nothing,
                 roadways=nothing,
                 cycleways=nothing,
                 walkways=nothing,
                 feature_classes::@compat(Union{@compat(Void),Dict{Int,Int}}) = nothing,
                 building_classes::@compat(Union{@compat(Void),Dict{Int,Int}}) = nothing,
                 route::@compat(Union{@compat(Void),Vector{Int},Vector{Vector{Int}}}) = nothing,
                 highway_style::Styles=Style(0x007CFF, 1.5, "-"),
                 building_style::Styles=Style(0x000000, 1, "-"),
                 feature_style::Styles=Style(0xCC0000, 2.5, "."),
                 route_style::@compat(Union{Style,Vector{Style}}) = Style(0xFF0000, 3, "-"),
                 intersection_style::Style=Style(0x000000, 3, "."),
                 width::Integer=500,
                 fontsize::Integer=0,
                 km::Bool=false,
                 realtime::Bool=false)

    # Chose labels according to point type and scale
    xlab, ylab = if isa(nodes, Dict{Int,LLA})
        "Longitude (deg)", "Latitude (deg)"
    elseif km
        "East (km)", "North (km)"
    else
        "East (m)", "North (m)"
    end

    # Waiting for Winston to add capability to force equal scales. For now:
    if VERSION.minor < 4
        height = isa(bounds, @compat(Void)) ? width : int(width / aspectRatio(bounds))
    else
        height = isa(bounds, @compat(Void)) ? width : round(Int, width / aspectRatio(bounds))
    end
    
    if Winston.output_surface != :none # Allow for plotting in IJulia/Jupyter to work
        # Create the figure
        fignum = Winston.figure(name="OpenStreetMap Plot", width=width, height=height)
    end

    if isa(bounds, @compat(Void))
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

    # Iterate over all buildings and draw
    if !isa(buildings, @compat(Void))
        if !isa(building_classes, @compat(Void))
            if isa(building_style, Dict{Int,Style})
                drawWayLayer(p, nodes, buildings, building_classes, building_style, km, realtime)
            else
                drawWayLayer(p, nodes, buildings, building_classes, LAYER_BUILDINGS, km, realtime)
            end
        else
            for (key, building) in buildings
                # Get coordinates of all nodes for object
                coords = getNodeCoords(nodes, building.nodes, km)

                # Add line(s) to plot
                drawNodes(p, coords, building_style, realtime)
            end
        end
    end

    # Iterate over all highways and draw
    if !isa(highways, @compat(Void))
        if !(nothing == roadways == cycleways == walkways)
            if !isa(roadways, @compat(Void))
                if isa(highway_style, Dict{Int,Style})
                    drawWayLayer(p, nodes, highways, roadways, highway_style, km, realtime)
                else
                    drawWayLayer(p, nodes, highways, roadways, LAYER_STANDARD, km, realtime)
                end
            end
            if !isa(cycleways, @compat(Void))
                if isa(highway_style, Dict{Int,Style})
                    drawWayLayer(p, nodes, highways, cycleways, highway_style, km, realtime)
                else
                    drawWayLayer(p, nodes, highways, cycleways, LAYER_CYCLE, km, realtime)
                end
            end
            if !isa(walkways, @compat(Void))
                if isa(highway_style, Dict{Int,Style})
                    drawWayLayer(p, nodes, highways, walkways, highway_style, km, realtime)
                else
                    drawWayLayer(p, nodes, highways, walkways, LAYER_PED, km, realtime)
                end
            end
        else
            for (key, highway) in highways
                # Get coordinates of all nodes for object
                coords = getNodeCoords(nodes, highway.nodes, km)

                # Add line(s) to plot
                drawNodes(p, coords, highway_style, realtime)
            end
        end
    end

    # Iterate over all features and draw
    if !isa(features, @compat(Void))
        if !isa(feature_classes, @compat(Void))
            if isa(feature_style, Dict{Int,Style})
                drawFeatureLayer(p, nodes, features, feature_classes, feature_style, km, realtime)
            else
                drawFeatureLayer(p, nodes, features, feature_classes, LAYER_FEATURES, km, realtime)
            end
        else
            coords = getNodeCoords(nodes, collect(keys(features)), km)

            # Add feature point(s) to plot
            drawNodes(p, coords, feature_style, realtime)
        end
    end

    # Draw route
    if isa(route, Vector{Int})
        # Get coordinates of all nodes for route
        coords = getNodeCoords(nodes, route, km)

        # Add line(s) to plot
        drawNodes(p, coords, route_style, realtime)
    elseif isa(route, Vector{Vector{Int}})
        for k = 1:length(route)
            coords = getNodeCoords(nodes, route[k], km)
            if isa(route_style, Vector{Style})
                drawNodes(p, coords, route_style[k], realtime)
            else
                drawNodes(p, coords, route_style, realtime)
            end
        end
    end

    # Iterate over all intersections and draw
    if !isa(intersections, @compat(Void))
        coords = Array{Float64}(length(intersections), 2)
        k = 1
        for key in keys(intersections)
            coords[k, :] = getNodeCoords(nodes, key, km)
            k += 1
        end

        # Add intersection(s) to plot
        drawNodes(p, coords, intersection_style, realtime)
    end

    if fontsize > 0
        attr = Dict(:fontsize => fontsize)
        Winston.setattr(p.x1, "label_style", attr)
        Winston.setattr(p.y1, "label_style", attr)
        Winston.setattr(p.x1, "ticklabels_style", attr)
        Winston.setattr(p.y1, "ticklabels_style", attr)
    end

    # Return figure object (enables further manipulation)

    return p
end

function add_route!(plot::@compat(Winston.FramedPlot),
                    nodes::@compat(Union{Dict{Int,LLA},Dict{Int,ENU}}),
                    route ::@compat(Union{@compat(Void),Vector{Int},Vector{Vector{Int}}}),
					label::String;
                    route_color::UInt32 =0x000053,
                    km::Bool=false,
                    realtime::Bool=false)
      # Draw route
		route_style = Style(route_color, 3, "-")
        if isa(route, Vector{Int})
            # Get coordinates of all nodes for route
            coords = getNodeCoords(nodes, route, km)

            # Add line(s) to plot
			if length(label) > 0
				drawNodes(plot, coords, label, route_style, realtime)
			else 
				drawNodes(plot, coords, route_style, realtime)
			end
        elseif isa(route, Vector{Vector{Int}})
            for k = 1:length(route)
                coords = getNodeCoords(nodes, route[k], km)
                if isa(route_style, Vector{Style})
					if length(label) > 0
						drawNodes(plot, coords, label, route_style[k], realtime)
					else
						drawNodes(plot, coords, route_style[k], realtime)
					end
                else
					if length(label) > 0
						drawNodes(plot, coords, label, route_style,realtime)
					else 
						drawNodes(plot, coords, route_style,realtime)
					end
                end
            end
        end
    return plot
end

### Draw layered Map ###
function drawWayLayer(p::Winston.FramedPlot, nodes::Dict, ways, classes, layer, km=false, realtime=false)
    for (key, class) in classes
        # Get coordinates of all nodes for object
        if haskey(ways,key)
            coords = getNodeCoords(nodes, ways[key].nodes, km)

            # Add line(s) to plot
            drawNodes(p, coords, layer[class], realtime)
        end
    end
end

### Draw layered features ###
function drawFeatureLayer(p::Winston.FramedPlot, nodes::Dict, features, classes, layer, km=false, realtime=false)

    for id in unique(values(classes))
        ids = Int[]

        for (key, class) in classes
            if class == id
                push!(ids, key)
            end
        end

        # Get coordinates of node for object
        coords = getNodeCoords(nodes, ids, km)

        # Add point to plot
        drawNodes(p, coords, layer[id], realtime)
    end
end

### Get coordinates of lists of nodes ###
# Nodes in LLA coordinates
function getNodeCoords(nodes::Dict{Int,LLA}, id_list, km=false)
    coords = Array{Float64}(length(id_list), 2)

    for k = 1:length(id_list)
        loc = nodes[id_list[k]]
        coords[k, 1] = loc.lon
        coords[k, 2] = loc.lat
    end

    return coords
end

# Nodes in ENU coordinates
function getNodeCoords(nodes::Dict{Int,ENU}, id_list, km=false)
    coords = Array{Float64}(length(id_list), 2)

    for k = 1:length(id_list)
        loc = nodes[id_list[k]]
        coords[k, 1] = loc.east
        coords[k, 2] = loc.north
    end

    if km
        coords /= 1000
    end

    return coords
end

### Draw a line between all points in a coordinate list ###
function drawNodes(p::Winston.FramedPlot, coords, style="k-", width=1, realtime=false)
    x = coords[:, 1]
    y = coords[:, 2]
    if length(x) > 1
        if realtime
            display(Winston.plot(p, x, y, style, linewidth=width))
        else
            Winston.plot(p, x, y, style, linewidth=width)
        end
    end
    nothing
end

### Draw a line between all points in a coordinate list given Style object ###
function drawNodes(p::Winston.FramedPlot, coords, line_style::Style, realtime=false)
    x = coords[:, 1]
    y = coords[:, 2]
    if length(x) > 1
        if realtime
            display(Winston.plot(p, x, y, line_style.spec, color=line_style.color, linewidth=line_style.width))
        else
            Winston.plot(p, x, y, line_style.spec, color=line_style.color, linewidth=line_style.width)
        end
    end
    nothing
end


### Draw a line between all points in a coordinate list given Style object and label###
function drawNodes(p::Winston.FramedPlot, coords, label, line_style::Style, realtime=false)
    x = coords[:, 1]
    y = coords[:, 2]
	lgnd = filter(x -> typeof(x) == Winston.Legend,p.content1.components)
    if length(x) > 1
        if realtime
			pnts = Curve(x, y,color=line_style.color, linewidth=line_style.width)
			setattr(pnts,"label",label)
			if length(lgnd) == 0
				lgnd = Winston.Legend(.05,.9,[pnts])
				Winston.add(p,pnts,lgnd)
			else
				Winston.add(p,pnts)
				push!(lgnd[1].components,pnts)
			end
			display(p)
        else
			pnts = Curve(x, y,color=line_style.color, linewidth=line_style.width)
			setattr(pnts,"label",label)
			if length(lgnd) == 0
				lgnd = Winston.Legend(.05,.9,[pnts])
				Winston.add(p,pnts,lgnd)
			else
				Winston.add(p,pnts)
				push!(lgnd[1].components,pnts)
			end
        end
    end
    nothing
end


### Compute approximate "aspect ratio" at mean latitude ###
function aspectRatio(bounds::Bounds{LLA})
    c_adj = cosd((bounds.min_y + bounds.max_y) / 2)
    range_y = bounds.max_y - bounds.min_y
    range_x = bounds.max_x - bounds.min_x

    return range_x * c_adj / range_y
end

### Compute exact "aspect ratio" ###
function aspectRatio(bounds::Bounds{ENU})
    range_y = bounds.max_y - bounds.min_y
    range_x = bounds.max_x - bounds.min_x

    return range_x / range_y
end
