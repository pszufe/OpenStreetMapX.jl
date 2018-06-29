
###################
### Point Types ###
###################

### Point in Latitude-Longitude-Altitude (LLA) coordinates
# Used to store node data in OpenStreetMap XML files
immutable LLA
    lat::Float64
    lon::Float64
    alt::Float64
end
LLA(lat, lon) = LLA(lat, lon, 0.0)

### Point in Earth-Centered-Earth-Fixed (ECEF) coordinates
# Global cartesian coordinate system rotating with the Earth
immutable ECEF
    x::Float64
    y::Float64
    z::Float64
end

### Point in East-North-Up (ENU) coordinates
# Local cartesian coordinate system
# Linearized about a reference point
immutable ENU
    east::Float64
    north::Float64
    up::Float64
end
ENU(x, y) = ENU(x, y, 0.0)

### Ellipsoid
# Specify datum for translation between LLA and other coordinate systems
immutable Ellipsoid
    a::Float64        # Semi-major axis
    b::Float64        # Semi-minor axis
    e²::Float64       # Eccentricity squared
    e′²::Float64      # Second eccentricity squared
end

function Ellipsoid(; a::String="", b::String="", f_inv::String="")
    if isempty(a) || isempty(b) == isempty(f_inv)
        throw(ArgumentError("Specify parameter 'a' and either 'b' or 'f_inv'"))
    end
    if isempty(b)
        _ellipsoid_af(BigFloat(a), BigFloat(f_inv))
    else
        _ellipsoid_ab(BigFloat(a), BigFloat(b))
    end
end

function _ellipsoid_ab(a::BigFloat, b::BigFloat)
    e² = (a^2 - b^2) / a^2
    e′² = (a^2 - b^2) / b^2

    Ellipsoid(a, b, e², e′²)
end
function _ellipsoid_af(a::BigFloat, f_inv::BigFloat)
    b = a * (1 - inv(f_inv))

    _ellipsoid_ab(a, b)
end

### World Geodetic Coordinate System of 1984 (WGS 84)
# Standardized coordinate system for Earth
# Global ellipsoidal reference surface
const WGS84  = Ellipsoid(a = "6378137.0", f_inv = "298.257223563")

const OSGB36 = Ellipsoid(a = "6377563.396", b = "6356256.909")
const NAD27  = Ellipsoid(a = "6378206.4",   b = "6356583.8")

### XYZ
# Helper for creating other point types in generic code
# e.g. myfunc{T <: Union(ENU, LLA)}(...) = (x, y = ...; T(XY(x, y)))
type XYZ
    x::Float64
    y::Float64
    z::Float64
end
XY(x, y) = XYZ(x, y, 0.0)

LLA(xyz::XYZ) = LLA(xyz.y, xyz.x, xyz.z)
ENU(xyz::XYZ) = ENU(xyz.x, xyz.y, xyz.z)

### get*
# Point translators
getX(lla::LLA) = lla.lon
getY(lla::LLA) = lla.lat
getZ(lla::LLA) = lla.alt

getX(enu::ENU) = enu.east
getY(enu::ENU) = enu.north
getZ(enu::ENU) = enu.up

### distance
# Point translators
distance(a::ENU, b::ENU) = distance(a.east, a.north, a.up,
                                    b.east, b.north, b.up)

distance(a::ECEF, b::ECEF) = distance(a.x, a.y, a.z,
                                      b.x, b.y, b.z)

function distance(x1, y1, z1, x2, y2, z2)
    return sqrt((x2-x1)^2 + (y2-y1)^2 + (z2-z1)^2)
end
