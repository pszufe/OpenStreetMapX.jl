"""
World Geodetic Coordinate System of 1984 (WGS 84)
Standardized coordinate system for Earth
Global ellipsoidal reference surface
"""
const WGS84  = OpenStreetMapX.Ellipsoid(a = 6378137.0, f_inv = 298.257223563)
const OSGB36 = OpenStreetMapX.Ellipsoid(a = 6377563.396, b = 6356256.909)
const NAD27  = OpenStreetMapX.Ellipsoid(a = 6378206.4,   b = 6356583.8)

#########################
### s ###
#########################
"""
Point Translator gets longitude
"""
getX(lla::OpenStreetMapX.LLA) = lla.lon
"""
Point Translator gets lattitude
"""
getY(lla::OpenStreetMapX.LLA) = lla.lat
"""
Point Translator gets altitude
"""
getZ(lla::OpenStreetMapX.LLA) = lla.alt
"""
Point Translator gets enu `east` value
"""
getX(enu::OpenStreetMapX.ENU) = enu.east
"""
Point Translator gets enu `north` value
"""
getY(enu::OpenStreetMapX.ENU) = enu.north
"""
Point Translator gets `up` value
"""
getZ(enu::OpenStreetMapX.ENU) = enu.up

"""
    distance(a::ENU, b::ENU)

Calculates a distance between two points `a` and `b`
"""
distance(a::ENU, b::ENU) = OpenStreetMapX.distance(a.east, a.north, a.up,
                                    b.east, b.north, b.up)

"""
    distance(a::ECEF, b::ECEF)

Calculates a distance between two points `a` and `b`
"""
distance(a::ECEF, b::ECEF) = OpenStreetMapX.distance(a.x, a.y, a.z,
                                      b.x, b.y, b.z)

function distance(x1, y1, z1, x2, y2, z2)
    return sqrt((x2-x1)^2 + (y2-y1)^2 + (z2-z1)^2)
end
