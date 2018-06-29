
###############################
### LLA to ECEF coordinates ###
###############################

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

###############################
### ECEF to LLA coordinates ###
###############################

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

###############################
### ECEF to ENU coordinates ###
###############################

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
function ENU(ecef::ECEF, bounds::Bounds{LLA}, datum::Ellipsoid = WGS84)
    lla_ref = center(bounds)
    return ENU(ecef, lla_ref, datum)
end

##############################
### LLA to ENU coordinates ###
##############################

# Given a reference point for linarization
function ENU(lla::LLA, lla_ref::LLA, datum::Ellipsoid = WGS84)
    ecef = ECEF(lla, datum)
    return ENU(ecef, lla_ref, datum)
end

# Given Bounds object for linearization
function ENU(lla::LLA, bounds::Bounds{LLA}, datum::Ellipsoid = WGS84)
    ecef = ECEF(lla, datum)
    return ENU(ecef, bounds, datum)
end

#################################
### LLA to ENU Bounds objects ###
#################################

# there's not an unambiguous conversion, but for now,
# returning the minimum bounds that contain all points contained
# by the input bounds
function ENU(bounds::Bounds{LLA}, lla_ref::LLA = center(bounds), datum::Ellipsoid = WGS84)

    max_x = max_y = -Inf
    min_x = min_y = Inf

    xs = [bounds.min_x, bounds.max_x]
    ys = [bounds.min_y, bounds.max_y]
    if bounds.min_y < 0.0 < bounds.max_y
        push!(ys, 0.0)
    end
    ref_x = getX(lla_ref)
    if bounds.min_x < ref_x < bounds.max_x ||
       (bounds.min_x > bounds.max_x && !(bounds.min_x >= ref_x >= bounds.max_x))
        push!(xs, ref_x)
    end

    for x_lla in xs, y_lla in ys
        pt = ENU(LLA(y_lla, x_lla), lla_ref, datum)
        x, y = getX(pt), getY(pt)

        min_x, max_x = min(x, min_x), max(x, max_x)
        min_y, max_y = min(y, min_y), max(y, max_y)
    end

    return Bounds{ENU}(min_y, max_y, min_x, max_x)
end
