#################################
### Convert LLA Bounds to ENU ###
#################################

# there's not an unambiguous conversion, but for now,
# returning the minimum bounds that contain all points contained
# by the input bounds
function ENU(bounds::OpenStreetMap2.Bounds{OpenStreetMap2.LLA}, lla_ref::OpenStreetMap2.LLA = OpenStreetMap2.center(bounds), datum::OpenStreetMap2.Ellipsoid = OpenStreetMap2.WGS84)

    max_x = max_y = -Inf
    min_x = min_y = Inf

    xs = [bounds.min_x, bounds.max_x]
    ys = [bounds.min_y, bounds.max_y]
    if bounds.min_y < 0.0 < bounds.max_y
        push!(ys, 0.0)
    end
    ref_x = OpenStreetMap2.getX(lla_ref)
    if bounds.min_x < ref_x < bounds.max_x ||
       (bounds.min_x > bounds.max_x && !(bounds.min_x >= ref_x >= bounds.max_x))
        push!(xs, ref_x)
    end

    for x_lla in xs, y_lla in ys
        pt = OpenStreetMap2.ENU(OpenStreetMap2.LLA(y_lla, x_lla), lla_ref, datum)
        x, y = OpenStreetMap2.getX(pt), OpenStreetMap2.getY(pt)

        min_x, max_x = min(x, min_x), max(x, max_x)
        min_y, max_y = min(y, min_y), max(y, max_y)
    end

    return OpenStreetMap2.Bounds{OpenStreetMap2.ENU}(min_y, max_y, min_x, max_x)
end

#########################################
### Get Center Point of Bounds Region ###
#########################################

function center(bounds::OpenStreetMap2.Bounds{OpenStreetMap2.ENU})
    x_mid = (bounds.min_x + bounds.max_x) / 2
    y_mid = (bounds.min_y + bounds.max_y) / 2

    return OpenStreetMap2.ENU(x_mid, y_mid)
end

function center(bounds::OpenStreetMap2.Bounds{OpenStreetMap2.LLA})
    x_mid = (bounds.min_x + bounds.max_x) / 2
    y_mid = (bounds.min_y + bounds.max_y) / 2

    if bounds.min_x > bounds.max_x
        x_mid = x_mid > 0 ? x_mid - 180 : x_mid + 180
    end

    return OpenStreetMap2.LLA(y_mid, x_mid)
end

#################################################
### Check Whether a Location is Within Bounds ###
#################################################

function inbounds(loc::OpenStreetMap2.ENU, bounds::OpenStreetMap2.Bounds{OpenStreetMap2.ENU})
    x, y = OpenStreetMap2.getX(loc), OpenStreetMap2.getY(loc)
    bounds.min_x <= x <= bounds.max_x &&
    bounds.min_y <= y <= bounds.max_y
end

function inbounds(loc::OpenStreetMap2.LLA, bounds::OpenStreetMap2.Bounds{OpenStreetMap2.LLA})
    x, y = OpenStreetMap2.getX(loc), OpenStreetMap2.getY(loc)
    min_x, max_x = bounds.min_x, bounds.max_x
    (min_x > max_x ? !(max_x < x < min_x) : min_x <= x <= max_x) &&
    bounds.min_y <= y <= bounds.max_y
end

# only for points that have passed the inbounds test
function onbounds(loc::T, bounds::OpenStreetMap2.Bounds{T}) where T<:Union{OpenStreetMap2.LLA,OpenStreetMap2.ENU}
    x, y = OpenStreetMap2.getX(loc), OpenStreetMap2.getY(loc)
    x == bounds.min_x || x == bounds.max_x ||
    y == bounds.min_y || y == bounds.max_y
end

#############################################
### Find the Closest Point  Within Bounds ###
#############################################

# only for points where inbounds(p1) != inbounds(p2)
function boundary_point(p1::T, p2::T, bounds::OpenStreetMap2.Bounds{T}) where T<:Union{OpenStreetMap2.LLA,OpenStreetMap2.ENU}
    x1, y1 = OpenStreetMap2.getX(p1), OpenStreetMap2.getY(p1)
    x2, y2 = OpenStreetMap2.getX(p2), OpenStreetMap2.getY(p2)

    x, y = Inf, Inf

    if bounds.min_x >  bounds.max_x && x1*x2 < 0 
        
        if x1 < bounds.min_x && x2 < bounds.max_x || x2 < bounds.min_x && x1 < bounds.max_x
            x = bounds.min_x
            y = y1 + (y2 - y1) * (bounds.min_x - x1) / (x2 - x1)
        elseif x1 > bounds.max_x && x2 > bounds.min_x || x2 > bounds.max_x && x1 > bounds.min_x 
            x = bounds.max_x
            y = y1 + (y2 - y1) * (bounds.max_x - x1) / (x2 - x1)
        end
        
        p3 = T(OpenStreetMap2.XY(x, y))
        OpenStreetMap2.inbounds(p3, bounds) && return p3
    end
    
    # Move x to x bound if segment crosses boundary
    if x1 < bounds.min_x < x2 || x1 > bounds.min_x > x2
        x = bounds.min_x
        y = y1 + (y2 - y1) * (bounds.min_x - x1) / (x2 - x1)
    elseif x1 < bounds.max_x < x2 || x1 > bounds.max_x > x2
        x = bounds.max_x
        y = y1 + (y2 - y1) * (bounds.max_x - x1) / (x2 - x1)
    end

    p3 = T(OpenStreetMap2.XY(x, y))
    OpenStreetMap2.inbounds(p3, bounds) && return p3

    # Move y to y bound if segment crosses boundary
    if y1 < bounds.min_y < y2 || y1 > bounds.min_y > y2
        x = x1 + (x2 - x1) * (bounds.min_y - y1) / (y2 - y1)
        y = bounds.min_y
    elseif y1 < bounds.max_y < y2 || y1 > bounds.max_y > y2
        x = x1 + (x2 - x1) * (bounds.max_y - y1) / (y2 - y1)
        y = bounds.max_y
    end

    p3 = T(OpenStreetMap2.XY(x, y))
    OpenStreetMap2.inbounds(p3, bounds) && return p3

    error("Failed to find boundary point.")
end

