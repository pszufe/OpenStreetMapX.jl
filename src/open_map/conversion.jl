##########################
### Points Conversions ###
##########################

###############################################
### Conversion from LLA to ECEF coordinates ###
###############################################


function ECEF(lla::LLA, datum::Ellipsoid = WGS84)
    ϕdeg, λdeg, h = lla.lat, lla.lon, lla.alt
    d = datum

    sinϕ, cosϕ = sind(ϕdeg), cosd(ϕdeg)
    sinλ, cosλ = sind(λdeg), cosd(λdeg)

    N = d.a / sqrt(1 - d.e² * sinϕ^2)  # Radius of curvature (meters)

    x = (N + h) * cosϕ * cosλ
    y = (N + h) * cosϕ * sinλ
    z = (N * (1 - d.e²) + h) * sinϕ

    return ECEF(x, y, z)
end

###############################################
### Conversion from ECEF to LLA coordinates ###
###############################################

function LLA(ecef::ECEF, datum::Ellipsoid = WGS84)
    x, y, z = ecef.x, ecef.y, ecef.z
    d = datum

    p = hypot(x, y)
    θ = atan2(z*d.a, p*d.b)
    λ = atan2(y, x)
    ϕ = atan2(z + d.e′² * d.b * sin(θ)^3, p - d.e²*d.a*cos(θ)^3)

    N = d.a / sqrt(1 - d.e² * sin(ϕ)^2)  # Radius of curvature (meters)
    h = p / cos(ϕ) - N

    return LLA(rad2deg(ϕ), rad2deg(λ), h)
end

###############################################
### Conversion from ECEF to ENU coordinates ###
###############################################

# Given a reference point for linarization
function ENU(ecef::ECEF, lla_ref::LLA, datum::Ellipsoid = WGS84)
    ϕdeg, λdeg = lla_ref.lat, lla_ref.lon

    ecef_ref = ECEF(lla_ref, datum)
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

    return ENU(east, north, up)
end


# Given Bounds object for linearization
ENU(ecef::ECEF, bounds::Bounds{LLA}, datum::Ellipsoid = WGS84) = ENU(ecef, center(bounds), datum)


###############################################
### Conversion from ENU to ECEF coordinates ###
###############################################

function ECEF(enu::ENU, lla_ref::LLA, datum::Ellipsoid = WGS84)
    ϕdeg, λdeg = lla_ref.lat, lla_ref.lon

    ecef_ref = ECEF(lla_ref, datum)

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

    return ECEF(x, y, z)
end

# Given Bounds object for linearization
ECEF(enu::ENU, bounds::Bounds{LLA}, datum::Ellipsoid = WGS84) = ECEF(enu, center(bounds), datum)

##############################################
### Conversion from LLA to ENU coordinates ###
##############################################

# Given a reference point for linarization
ENU(lla::LLA, lla_ref::LLA, datum::Ellipsoid = WGS84) = ENU(ECEF(lla, datum), lla_ref, datum)

# Given Bounds object for linearization
ENU(lla::LLA, bounds::Bounds{LLA}, datum::Ellipsoid = WGS84) = ENU(ECEF(lla, datum), bounds, datum)

##############################################
### Conversion from ENU to LLA coordinates ###
##############################################

# Given a reference point for linarization
LLA(enu::ENU, lla_ref::LLA, datum::Ellipsoid = WGS84) = LLA(ECEF(enu,lla_ref))

# Given Bounds object for linearization
LLA(enu::ENU, bounds::Bounds{LLA}, datum::Ellipsoid = WGS84) = LLA(ECEF(enu,bounds))

#########################################
### Dictionaries of Nodes Conversions ###
#########################################

###############################################
### Conversion from LLA to ECEF coordinates ###
###############################################

function ECEF(nodes::Dict{Int,LLA}, datum::Ellipsoid = WGS84)
    r = Dict{Int,ECEF}()
    sizehint!(r, ceil(Int, 1.5*length(nodes)))

    for (key, node) in nodes
        r[key] = ECEF(node, datum)
    end

    return r
end

###############################################
### Conversion from ECEF to LLA coordinates ###
###############################################

function LLA(nodes::Dict{Int,ECEF}, datum::Ellipsoid = WGS84)
    r = Dict{Int,LLA}()
    sizehint!(r, ceil(Int, 1.5*length(nodes)))

    for (key, node) in nodes
        r[key] = LLA(node, datum)
    end

    return r
end


######################################################
### Conversion from LLA or ECEF to ENU coordinates ###
######################################################

# Given a reference point
function ENU{T<:Union{LLA,ECEF}}(nodes::Dict{Int,T},
                                         lla_ref::LLA,
                                         datum::Ellipsoid = WGS84)
    r = Dict{Int,ENU}()
    sizehint!(r, ceil(Int, 1.5*length(nodes)))

    for (key, node) in nodes
        r[key] = ENU(node, lla_ref, datum)
    end

    return r
end

# Given Bounds
ENU(nodes::Dict, bounds::Bounds{LLA}, datum::Ellipsoid = WGS84) = ENU(nodes, center(bounds), datum)

###############################################
### Conversion from ENU to ECEF coordinates ###
###############################################

function ECEF(nodes::Dict{Int,ENU},lla_ref::LLA , datum::Ellipsoid = WGS84)
    r = Dict{Int,ECEF}()
    sizehint!(r, ceil(Int, 1.5*length(nodes)))

    for (key, node) in nodes
        r[key] = ECEF(node, lla_ref, datum)
    end

    return r
end

# Given Bounds
ECEF(nodes::Dict, bounds::Bounds{LLA}, datum::Ellipsoid = WGS84) = ECEF(nodes, center(bounds), datum)

###############################################
### Conversion from ENU to LLA coordinates ###
###############################################

function LLA(nodes::Dict{Int,ENU},lla_ref::LLA , datum::Ellipsoid = WGS84)
    r = Dict{Int,LLA}()
    sizehint!(r, ceil(Int, 1.5*length(nodes)))

    for (key, node) in nodes
        r[key] = LLA(node, lla_ref, datum)
    end

    return r
end

# Given Bounds
LLA(nodes::Dict, bounds::Bounds{LLA}, datum::Ellipsoid = WGS84) = LLA(nodes, center(bounds), datum)
