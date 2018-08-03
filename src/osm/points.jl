#########################################################
### World Geodetic Coordinate System of 1984 (WGS 84) ###
### Standardized coordinate system for Earth          ###
### Global ellipsoidal reference surface              ###
#########################################################

const WGS84  = Ellipsoid(a = 6378137.0, f_inv = 298.257223563)
const OSGB36 = Ellipsoid(a = 6377563.396, b = 6356256.909)
const NAD27  = Ellipsoid(a = 6378206.4,   b = 6356583.8)

#########################
### Point Translators ###
#########################

getX(lla::LLA) = lla.lon
getY(lla::LLA) = lla.lat
getZ(lla::LLA) = lla.alt

getX(enu::ENU) = enu.east
getY(enu::ENU) = enu.north
getZ(enu::ENU) = enu.up

################
### Distance ###
################

# Point translators
distance(a::ENU, b::ENU) = distance(a.east, a.north, a.up,
                                    b.east, b.north, b.up)

distance(a::ECEF, b::ECEF) = distance(a.x, a.y, a.z,
                                      b.x, b.y, b.z)

function distance(x1, y1, z1, x2, y2, z2)
    return sqrt((x2-x1)^2 + (y2-y1)^2 + (z2-z1)^2)
end
