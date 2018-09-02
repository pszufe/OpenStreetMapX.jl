#################################
### Convert LLA Bounds to ENU ###
#################################

# there's not an unambiguous conversion, but for now,
# returning the minimum bounds that contain all points contained
# by the input bounds
function ENU(bounds::OpenStreetMap.Bounds{OpenStreetMap.LLA}, lla_ref::OpenStreetMap.LLA = OpenStreetMap.center(bounds), datum::OpenStreetMap.Ellipsoid = OpenStreetMap.WGS84)

    max_x = max_y = -Inf
    min_x = min_y = Inf

    xs = [bounds.min_x, bounds.max_x]
    ys = [bounds.min_y, bounds.max_y]
    if bounds.min_y < 0.0 < bounds.max_y
        push!(ys, 0.0)
    end
    ref_x = OpenStreetMap.getX(lla_ref)
    if bounds.min_x < ref_x < bounds.max_x ||
       (bounds.min_x > bounds.max_x && !(bounds.min_x >= ref_x >= bounds.max_x))
        push!(xs, ref_x)
    end

    for x_lla in xs, y_lla in ys
        pt = OpenStreetMap.ENU(OpenStreetMap.LLA(y_lla, x_lla), lla_ref, datum)
        x, y = OpenStreetMap.getX(pt), OpenStreetMap.getY(pt)

        min_x, max_x = min(x, min_x), max(x, max_x)
        min_y, max_y = min(y, min_y), max(y, max_y)
    end

    return OpenStreetMap.Bounds{OpenStreetMap.ENU}(min_y, max_y, min_x, max_x)
end

#########################################
### Get Center Point of Bounds Region ###
#########################################

function center(bounds::OpenStreetMap.Bounds{OpenStreetMap.ENU})
    x_mid = (bounds.min_x + bounds.max_x) / 2
    y_mid = (bounds.min_y + bounds.max_y) / 2

    return OpenStreetMap.ENU(x_mid, y_mid)
end

function center(bounds::OpenStreetMap.Bounds{OpenStreetMap.LLA})
    x_mid = (bounds.min_x + bounds.max_x) / 2
    y_mid = (bounds.min_y + bounds.max_y) / 2

    if bounds.min_x > bounds.max_x
        x_mid = x_mid > 0 ? x_mid - 180 : x_mid + 180
    end

    return OpenStreetMap.LLA(y_mid, x_mid)
end

#################################################
### Check Whether a Location is Within Bounds ###
#################################################

function inBounds(loc::OpenStreetMap.ENU, bounds::OpenStreetMap.Bounds{OpenStreetMap.ENU})
    x, y = OpenStreetMap.getX(loc), OpenStreetMap.getY(loc)
    bounds.min_x <= x <= bounds.max_x &&
    bounds.min_y <= y <= bounds.max_y
end

function inBounds(loc::OpenStreetMap.LLA, bounds::OpenStreetMap.Bounds{OpenStreetMap.LLA})
    x, y = OpenStreetMap.getX(loc), OpenStreetMap.getY(loc)
    min_x, max_x = bounds.min_x, bounds.max_x
    (min_x > max_x ? !(max_x < x < min_x) : min_x <= x <= max_x) &&
    bounds.min_y <= y <= bounds.max_y
end

# only for points that have passed the inBounds test
function onBounds(loc::T, bounds::OpenStreetMap.Bounds{T}) where T<:Union{OpenStreetMap.LLA,OpenStreetMap.ENU}
    x, y = OpenStreetMap.getX(loc), OpenStreetMap.getY(loc)
    x == bounds.min_x || x == bounds.max_x ||
    y == bounds.min_y || y == bounds.max_y
end

#############################################
### Find the Closest Point  Within Bounds ###
#############################################

# only for points where inBounds(p1) != inBounds(p2)
function boundaryPoint(p1::T, p2::T, bounds::OpenStreetMap.Bounds{T}) where T<:Union{OpenStreetMap.LLA,OpenStreetMap.ENU}
    x1, y1 = OpenStreetMap.getX(p1), OpenStreetMap.getY(p1)
    x2, y2 = OpenStreetMap.getX(p2), OpenStreetMap.getY(p2)

    x, y = Inf, Inf

    if bounds.min_x >  bounds.max_x && x1*x2 < 0 
        
        if x1 < bounds.min_x && x2 < bounds.max_x || x2 < bounds.min_x && x1 < bounds.max_x
            x = bounds.min_x
            y = y1 + (y2 - y1) * (bounds.min_x - x1) / (x2 - x1)
        elseif x1 > bounds.max_x && x2 > bounds.min_x || x2 > bounds.max_x && x1 > bounds.min_x 
            x = bounds.max_x
            y = y1 + (y2 - y1) * (bounds.max_x - x1) / (x2 - x1)
        end
        
        p3 = T(OpenStreetMap.XY(x, y))
        OpenStreetMap.inBounds(p3, bounds) && return p3
    end
    
    # Move x to x bound if segment crosses boundary
    if x1 < bounds.min_x < x2 || x1 > bounds.min_x > x2
        x = bounds.min_x
        y = y1 + (y2 - y1) * (bounds.min_x - x1) / (x2 - x1)
    elseif x1 < bounds.max_x < x2 || x1 > bounds.max_x > x2
        x = bounds.max_x
        y = y1 + (y2 - y1) * (bounds.max_x - x1) / (x2 - x1)
    end

    p3 = T(OpenStreetMap.XY(x, y))
    OpenStreetMap.inBounds(p3, bounds) && return p3

    # Move y to y bound if segment crosses boundary
    if y1 < bounds.min_y < y2 || y1 > bounds.min_y > y2
        x = x1 + (x2 - x1) * (bounds.min_y - y1) / (y2 - y1)
        y = bounds.min_y
    elseif y1 < bounds.max_y < y2 || y1 > bounds.max_y > y2
        x = x1 + (x2 - x1) * (bounds.max_y - y1) / (y2 - y1)
        y = bounds.max_y
    end

    p3 = T(OpenStreetMap.XY(x, y))
    OpenStreetMap.inBounds(p3, bounds) && return p3

    error("Failed to find boundary point.")
end

