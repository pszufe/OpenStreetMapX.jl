##########################
### Points Conversions ###
##########################

###############################################
### Conversion from LLA to ECEF coordinates ###
###############################################


function ECEF(lla::OpenStreetMap.LLA, datum::OpenStreetMap.Ellipsoid = OpenStreetMap.WGS84)
    ϕdeg, λdeg, h = lla.lat, lla.lon, lla.alt
    d = datum

    sinϕ, cosϕ = sind(ϕdeg), cosd(ϕdeg)
    sinλ, cosλ = sind(λdeg), cosd(λdeg)

    N = d.a / sqrt(1 - d.e² * sinϕ^2)  # Radius of curvature (meters)

    x = (N + h) * cosϕ * cosλ
    y = (N + h) * cosϕ * sinλ
    z = (N * (1 - d.e²) + h) * sinϕ

    return OpenStreetMap.ECEF(x, y, z)
end

###############################################
### Conversion from ECEF to LLA coordinates ###
###############################################

function LLA(ecef::OpenStreetMap.ECEF, datum::OpenStreetMap.Ellipsoid = OpenStreetMap.WGS84)
    x, y, z = ecef.x, ecef.y, ecef.z
    d = datum

    p = hypot(x, y)
    θ = atan(z*d.a, p*d.b)
    λ = atan(y, x)
    ϕ = atan(z + d.e′² * d.b * sin(θ)^3, p - d.e²*d.a*cos(θ)^3)

    N = d.a / sqrt(1 - d.e² * sin(ϕ)^2)  # Radius of curvature (meters)
    h = p / cos(ϕ) - N

    return OpenStreetMap.LLA(rad2deg(ϕ), rad2deg(λ), h)
end

###############################################
### Conversion from ECEF to ENU coordinates ###
###############################################

# Given a reference point for linarization
function ENU(ecef::OpenStreetMap.ECEF, lla_ref::OpenStreetMap.LLA, datum::OpenStreetMap.Ellipsoid = OpenStreetMap.WGS84)
    ϕdeg, λdeg = lla_ref.lat, lla_ref.lon

    ecef_ref = OpenStreetMap.ECEF(lla_ref, datum)
    ∂x = ecef.x - ecef_ref.x
    ∂y = ecef.y - ecef_ref.y
    ∂z = ecef.z - ecef_ref.z

    # Compute rotation matrix
    sinλ, cosλ = sind(λdeg), cosd(λdeg)
    sinϕ, cosϕ = sind(ϕdeg), cosd(ϕdeg)

    # R = [     -sinλ       cosλ  0.0
    #      -cosλ*sinϕ -sinλ*sinϕ cosϕ
    #       cosλ*cosϕ  sinλ*cosϕ sinϕ]
    #
    # east, north, up = R * [∂x, ∂y, ∂z]
    east  = ∂x * -sinλ      + ∂y * cosλ       + ∂z * 0.0
    north = ∂x * -cosλ*sinϕ + ∂y * -sinλ*sinϕ + ∂z * cosϕ
    up    = ∂x * cosλ*cosϕ  + ∂y * sinλ*cosϕ  + ∂z * sinϕ

    return OpenStreetMap.ENU(east, north, up)
end


# Given Bounds object for linearization
ENU(ecef::OpenStreetMap.ECEF, bounds::OpenStreetMap.Bounds{OpenStreetMap.LLA}, datum::OpenStreetMap.Ellipsoid = OpenStreetMap.WGS84) = OpenStreetMap.ENU(ecef, OpenStreetMap.center(bounds), datum)


###############################################
### Conversion from ENU to ECEF coordinates ###
###############################################

function ECEF(enu::OpenStreetMap.ENU, lla_ref::OpenStreetMap.LLA, datum::OpenStreetMap.Ellipsoid = OpenStreetMap.WGS84)
    ϕdeg, λdeg = lla_ref.lat, lla_ref.lon

    ecef_ref = OpenStreetMap.ECEF(lla_ref, datum)

    # Compute rotation matrix
    sinλ, cosλ = sind(λdeg), cosd(λdeg)
    sinϕ, cosϕ = sind(ϕdeg), cosd(ϕdeg)

    # R = [-sinλ -sinϕ*cosλ  cosϕ*cosλ
    #      	cosλ -sinϕ*sinλ  cosϕ*sinλ
    #        0.0       cosϕ       sinϕ]
    #
    # x,y,z = R * [east, north, up] + [ecef_ref.x, ecef_ref.y, ecef_ref.z]
	
	
	
	
    x  = -sinλ*enu.east + -sinϕ*cosλ*enu.north + cosϕ*cosλ*enu.up + ecef_ref.x
    y = cosλ*enu.east +  -sinϕ*sinλ*enu.north + cosϕ*sinλ*enu.up + ecef_ref.y
    z    = 0.0*enu.east + cosϕ*enu.north + sinϕ*enu.up + ecef_ref.z

    return OpenStreetMap.ECEF(x, y, z)
end

# Given Bounds object for linearization
ECEF(enu::OpenStreetMap.ENU, bounds::OpenStreetMap.Bounds{OpenStreetMap.LLA}, datum::OpenStreetMap.Ellipsoid = OpenStreetMap.WGS84) = OpenStreetMap.ECEF(enu, OpenStreetMap.center(bounds), datum)

##############################################
### Conversion from LLA to ENU coordinates ###
##############################################

# Given a reference point for linarization
ENU(lla::OpenStreetMap.LLA, lla_ref::OpenStreetMap.LLA, datum::OpenStreetMap.Ellipsoid = OpenStreetMap.WGS84) = OpenStreetMap.ENU(OpenStreetMap.ECEF(lla, datum), lla_ref, datum)

# Given Bounds object for linearization
ENU(lla::OpenStreetMap.LLA, bounds::OpenStreetMap.Bounds{OpenStreetMap.LLA}, datum::OpenStreetMap.Ellipsoid = OpenStreetMap.WGS84) = OpenStreetMap.ENU(OpenStreetMap.ECEF(lla, datum), bounds, datum)

##############################################
### Conversion from ENU to LLA coordinates ###
##############################################

# Given a reference point for linarization
LLA(enu::OpenStreetMap.ENU, lla_ref::OpenStreetMap.LLA, datum::OpenStreetMap.Ellipsoid = OpenStreetMap.WGS84) = OpenStreetMap.LLA(OpenStreetMap.ECEF(enu,lla_ref))

# Given Bounds object for linearization
LLA(enu::OpenStreetMap.ENU, bounds::OpenStreetMap.Bounds{OpenStreetMap.LLA}, datum::OpenStreetMap.Ellipsoid = OpenStreetMap.WGS84) = OpenStreetMap.LLA(OpenStreetMap.ECEF(enu,bounds))

#########################################
### Dictionaries of Nodes Conversions ###
#########################################

###############################################
### Conversion from LLA to ECEF coordinates ###
###############################################

function ECEF(nodes::Dict{Int,OpenStreetMap.LLA}, datum::OpenStreetMap.Ellipsoid = OpenStreetMap.WGS84)
    r = Dict{Int,OpenStreetMap.ECEF}()
    sizehint!(r, ceil(Int, 1.5*length(nodes)))

    for (key, node) in nodes
        r[key] = OpenStreetMap.ECEF(node, datum)
    end

    return r
end

###############################################
### Conversion from ECEF to LLA coordinates ###
###############################################

function LLA(nodes::Dict{Int,OpenStreetMap.ECEF}, datum::OpenStreetMap.Ellipsoid = OpenStreetMap.WGS84)
    r = Dict{Int,OpenStreetMap.LLA}()
    sizehint!(r, ceil(Int, 1.5*length(nodes)))

    for (key, node) in nodes
        r[key] = OpenStreetMap.LLA(node, datum)
    end

    return r
end


######################################################
### Conversion from LLA or ECEF to ENU coordinates ###
######################################################

# Given a reference point
function ENU(nodes::Dict{Int,T}, lla_ref::OpenStreetMap.LLA,
            datum::OpenStreetMap.Ellipsoid = OpenStreetMap.WGS84) where T<:Union{OpenStreetMap.LLA,OpenStreetMap.ECEF}
    r = Dict{Int,OpenStreetMap.ENU}()
    sizehint!(r, ceil(Int, 1.5*length(nodes)))

    for (key, node) in nodes
        r[key] = OpenStreetMap.ENU(node, lla_ref, datum)
    end

    return r
end

# Given Bounds
ENU(nodes::Dict{Int,T}, bounds::OpenStreetMap.Bounds{OpenStreetMap.LLA}, datum::OpenStreetMap.Ellipsoid = OpenStreetMap.WGS84) where T<:Union{OpenStreetMap.LLA,OpenStreetMap.ECEF} = OpenStreetMap.ENU(nodes, OpenStreetMap.center(bounds), datum)

###############################################
### Conversion from ENU to ECEF coordinates ###
###############################################

function ECEF(nodes::Dict{Int,OpenStreetMap.ENU},lla_ref::OpenStreetMap.LLA , datum::OpenStreetMap.Ellipsoid = OpenStreetMap.WGS84)
    r = Dict{Int,OpenStreetMap.ECEF}()
    sizehint!(r, ceil(Int, 1.5*length(nodes)))

    for (key, node) in nodes
        r[key] = OpenStreetMap.ECEF(node, lla_ref, datum)
    end

    return r
end

# Given Bounds
ECEF(nodes::Dict{Int,OpenStreetMap.ENU}, bounds::Bounds{LLA}, datum::Ellipsoid = WGS84) = ECEF(nodes, OpenStreetMap.center(bounds), datum)

###############################################
### Conversion from ENU to LLA coordinates ###
###############################################

function LLA(nodes::Dict{Int,OpenStreetMap.ENU},lla_ref::OpenStreetMap.LLA , datum::OpenStreetMap.Ellipsoid = OpenStreetMap.WGS84)
    r = Dict{Int,OpenStreetMap.LLA}()
    sizehint!(r, ceil(Int, 1.5*length(nodes)))

    for (key, node) in nodes
        r[key] = OpenStreetMap.LLA(node, lla_ref, datum)
    end

    return r
end

# Given Bounds
LLA(nodes::Dict{Int,OpenStreetMap.ENU}, bounds::OpenStreetMap.Bounds{OpenStreetMap.LLA}, datum::OpenStreetMap.Ellipsoid = OpenStreetMap.WGS84) = OpenStreetMap.LLA(nodes, OpenStreetMap.center(bounds), datum)
