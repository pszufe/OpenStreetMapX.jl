##########################
### Points Conversions ###
##########################

"""
Create ECEF coordinates from a given `lla`
"""
function ECEF(lla::LLA, datum::OpenStreetMapX.Ellipsoid = OpenStreetMapX.WGS84)
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
"""
Create LLA coordinates from a given `ecef`
"""
function LLA(ecef::ECEF, datum::OpenStreetMapX.Ellipsoid = OpenStreetMapX.WGS84)
    x, y, z = ecef.x, ecef.y, ecef.z
    d = datum

    p = hypot(x, y)
    θ = atan(z*d.a, p*d.b)
    λ = atan(y, x)
    ϕ = atan(z + d.e′² * d.b * sin(θ)^3, p - d.e²*d.a*cos(θ)^3)

    N = d.a / sqrt(1 - d.e² * sin(ϕ)^2)  # Radius of curvature (meters)
    h = p / cos(ϕ) - N

    return LLA(rad2deg(ϕ), rad2deg(λ), h)
end

"""
Create ENU coordinates from given `ecef` coordinates
given a reference point `lla_ref` for linarization
"""
function ENU(ecef::ECEF, lla_ref::LLA, datum::OpenStreetMapX.Ellipsoid = OpenStreetMapX.WGS84)
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

"""
Create ENU coordinates from given `ecef` coordinates
given a center of reference point `bounds` for linarization
"""
ENU(ecef::ECEF, bounds::Bounds{LLA}, datum::OpenStreetMapX.Ellipsoid = OpenStreetMapX.WGS84) = ENU(ecef, OpenStreetMapX.center(bounds), datum)


"""
Create ECEF coordinates from given `enu` coordinates
and a reference point being center of `bounds` for linearization
"""
function ECEF(enu::ENU, lla_ref::LLA, datum::OpenStreetMapX.Ellipsoid = OpenStreetMapX.WGS84)
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

"""
Create ECEF coordinates from given `enu` coordinates
and a reference point being center of `bounds` for linearization
"""
ECEF(enu::ENU, bounds::Bounds{LLA}, datum::OpenStreetMapX.Ellipsoid = OpenStreetMapX.WGS84) = ECEF(enu, OpenStreetMapX.center(bounds), datum)


"""
Create ENU coordinates from given `lla` coordinates
and a reference point `lla_ref` for linearization
"""
ENU(lla::LLA, lla_ref::LLA, datum::OpenStreetMapX.Ellipsoid = OpenStreetMapX.WGS84) = ENU(ECEF(lla, datum), lla_ref, datum)

"""
Create ENU coordinates from given `lla` coordinates
and a reference point being center of `bounds` for linearization
"""
ENU(lla::LLA, bounds::Bounds{LLA}, datum::OpenStreetMapX.Ellipsoid = OpenStreetMapX.WGS84) = ENU(ECEF(lla, datum), bounds, datum)


"""
Create LLA coordinates from given `enu` coordinates
and a reference point `lla_ref` for linearization
"""
LLA(enu::ENU, lla_ref::LLA, datum::OpenStreetMapX.Ellipsoid = OpenStreetMapX.WGS84) = LLA(ECEF(enu,lla_ref))

"""
Create LLA coordinates from given `enu` coordinates
and a reference point being center of `bounds` for linearization
"""
LLA(enu::ENU, bounds::Bounds{LLA}, datum::OpenStreetMapX.Ellipsoid = OpenStreetMapX.WGS84) = LLA(ECEF(enu,bounds))

"""
Converts a dictionary of `LLA` `nodes` into a dictionary of `ECEF` values.
Uses a reference point `lla_ref` for linearization.
"""
function ECEF(nodes::Dict{Int,LLA}, datum::OpenStreetMapX.Ellipsoid = OpenStreetMapX.WGS84)
    r = Dict{Int,ECEF}()
    sizehint!(r, ceil(Int, 1.5*length(nodes)))

    for (key, node) in nodes
        r[key] = ECEF(node, datum)
    end

    return r
end

"""
Converts a dictionary of `ECEF` `nodes` into a dictionary of `LLA` values.
"""
function LLA(nodes::Dict{Int,ECEF}, datum::OpenStreetMapX.Ellipsoid = OpenStreetMapX.WGS84)
    r = Dict{Int,LLA}()
    sizehint!(r, ceil(Int, 1.5*length(nodes)))

    for (key, node) in nodes
        r[key] = LLA(node, datum)
    end

    return r
end

"""
Converts a dictionary of `LLA` and `ECEF` `nodes` into a dictionary of `ENU` values.
Uses a reference point `lla_ref` for linearization.
"""
function ENU(nodes::Dict{Int,T}, lla_ref::LLA,
            datum::OpenStreetMapX.Ellipsoid = OpenStreetMapX.WGS84) where T<:Union{LLA,ECEF}
    r = Dict{Int,ENU}()
    sizehint!(r, ceil(Int, 1.5*length(nodes)))

    for (key, node) in nodes
        r[key] = ENU(node, lla_ref, datum)
    end

    return r
end

"""
Converts a dictionary of `LLA` and `ECEF` `nodes` into a dictionary of `ENU` values.
Uses the center of the given `bounds` for linearization.
"""
ENU(nodes::Dict{Int,T}, bounds::Bounds{LLA}, datum::OpenStreetMapX.Ellipsoid = OpenStreetMapX.WGS84) where T<:Union{LLA,ECEF} = ENU(nodes, OpenStreetMapX.center(bounds), datum)


"""
Converts a dictionary of `ENU` `nodes` into a dictionary of `ECEF` values.
Uses a reference point `lla_ref` for linearization.
"""
function ECEF(nodes::Dict{Int,ENU},lla_ref::LLA , datum::OpenStreetMapX.Ellipsoid = OpenStreetMapX.WGS84)
    r = Dict{Int,ECEF}()
    sizehint!(r, ceil(Int, 1.5*length(nodes)))

    for (key, node) in nodes
        r[key] = ECEF(node, lla_ref, datum)
    end

    return r
end

"""
Converts a dictionary of `ENU` `nodes` into a dictionary of `ECEF` values.
Uses the center of the given `bounds` for linearization.
"""
ECEF(nodes::Dict{Int,ENU}, bounds::Bounds{LLA}, datum::Ellipsoid = WGS84) = ECEF(nodes, OpenStreetMapX.center(bounds), datum)


"""
Converts a dictionary of `ENU` `nodes` into a dictionary of `LLA` values.
Uses a reference point `lla_ref` for linearization.
"""
function LLA(nodes::Dict{Int,ENU},lla_ref::LLA , datum::OpenStreetMapX.Ellipsoid = OpenStreetMapX.WGS84)
    r = Dict{Int,LLA}()
    sizehint!(r, ceil(Int, 1.5*length(nodes)))

    for (key, node) in nodes
        r[key] = LLA(node, lla_ref, datum)
    end

    return r
end

"""
Converts a dictionary of `ENU` `nodes` into a dictionary of `LLA` values.
Uses the center of the given `bounds` for linearization.
"""
LLA(nodes::Dict{Int,ENU}, bounds::Bounds{LLA}, datum::OpenStreetMapX.Ellipsoid = OpenStreetMapX.WGS84) = LLA(nodes, OpenStreetMapX.center(bounds), datum)
