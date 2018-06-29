### Julia OpenStreetMap Package ###
### MIT License                 ###
### Copyright 2014              ###


###################
### Bounds Type ###
###################

type Bounds{T <: Union{LLA, ENU}}
    min_y::Float64
    max_y::Float64
    min_x::Float64
    max_x::Float64
end
function Bounds(min_lat, max_lat, min_lon, max_lon)
    if !(-90 <= min_lat <= max_lat <= 90 &&
         -180 <= min_lon <= 180 &&
         -180 <= max_lon <= 180)
        throw(ArgumentError("Bounds out of range of LLA coordinate system. " *
                            "Perhaps you're looking for Bounds{ENU}(...)"))
    end
    Bounds{LLA}(min_lat, max_lat, min_lon, max_lon)
end


### Get bounds of mapped region ###
function getBounds(street_map::LightXML.XMLDocument)

    xroot = LightXML.root(street_map)
    bounds = LightXML.get_elements_by_tagname(xroot, "bounds")

    min_lat = float(LightXML.attribute(bounds[1], "minlat"))
    max_lat = float(LightXML.attribute(bounds[1], "maxlat"))
    min_lon = float(LightXML.attribute(bounds[1], "minlon"))
    max_lon = float(LightXML.attribute(bounds[1], "maxlon"))

    return Bounds(min_lat, max_lat, min_lon, max_lon)
end


#############################
### Convenience Functions ###
#############################

### Get center point of Bounds region ###
function center(bounds::Bounds{ENU})
    x_mid = (bounds.min_x + bounds.max_x) / 2
    y_mid = (bounds.min_y + bounds.max_y) / 2

    return ENU(x_mid, y_mid)
end

function center(bounds::Bounds{LLA})
    x_mid = (bounds.min_x + bounds.max_x) / 2
    y_mid = (bounds.min_y + bounds.max_y) / 2

    if bounds.min_x > bounds.max_x
        x_mid = x_mid > 0 ? x_mid - 180 : x_mid + 180
    end

    return LLA(y_mid, x_mid)
end

### Check whether a location is within bounds ###
function inBounds(loc::ENU, bounds::Bounds{ENU})
    x, y = getX(loc), getY(loc)

    bounds.min_x <= x <= bounds.max_x &&
    bounds.min_y <= y <= bounds.max_y
end

function inBounds(loc::LLA, bounds::Bounds{LLA})
    x, y = getX(loc), getY(loc)

    min_x, max_x = bounds.min_x, bounds.max_x

    (min_x > max_x ? !(max_x < x < min_x) : min_x <= x <= max_x) &&
    bounds.min_y <= y <= bounds.max_y
end

# only for points that have passed the inBounds test
function onBounds{T<:Union{LLA,ENU}}(loc::T, bounds::Bounds{T})
    x, y = getX(loc), getY(loc)

    x == bounds.min_x || x == bounds.max_x ||
    y == bounds.min_y || y == bounds.max_y
end

# only for points where inBounds(p1) != inBounds(p2)
# TODO: fix for cases where bounds.min_x > bounds.max_x
function boundaryPoint{T<:Union{LLA,ENU}}(p1::T, p2::T, bounds::Bounds)
    x1, y1 = getX(p1), getY(p1)
    x2, y2 = getX(p2), getY(p2)

    x, y = Inf, Inf

    # Move x to x bound if segment crosses boundary
    if x1 < bounds.min_x < x2 || x1 > bounds.min_x > x2
        x = bounds.min_x
        y = y1 + (y2 - y1) * (bounds.min_x - x1) / (x2 - x1)
    elseif x1 < bounds.max_x < x2 || x1 > bounds.max_x > x2
        x = bounds.max_x
        y = y1 + (y2 - y1) * (bounds.max_x - x1) / (x2 - x1)
    end

    p3 = T(XY(x, y))
    inBounds(p3, bounds) && return p3

    # Move y to y bound if segment crosses boundary
    if y1 < bounds.min_y < y2 || y1 > bounds.min_y > y2
        x = x1 + (x2 - x1) * (bounds.min_y - y1) / (y2 - y1)
        y = bounds.min_y
    elseif y1 < bounds.max_y < y2 || y1 > bounds.max_y > y2
        x = x1 + (x2 - x1) * (bounds.max_y - y1) / (y2 - y1)
        y = bounds.max_y
    end

    p3 = T(XY(x, y))
    inBounds(p3, bounds) && return p3

    error("Failed to find boundary point.")
end