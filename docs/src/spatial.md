Notes on spatial data
=====================

Using the the library makes basic understanding of spatial data. The following [geographics coordinate systems](https://en.wikipedia.org/wiki/Geographic_coordinate_system) are supported:
- Latitude-Longitude-Altitude (LLA)
- Earth-centered, Earth-fixed (ECEF)
- East, North, Up (ENU)

The `LLA` node is the standard way to represent locations. The latitude is the angle between the equatorial plane and the straight line that passes through that point and through (or close to) the center of the Earth. The longitude is the angle east or west of a reference meridian to another meridian that passes through that point. The altitude is the height of a point in relation to sea level or ground level.

The `ECEF` and `ENU` modes uses a distance (measured in meters) from a reference point.
The `ECEF` mode is a cartesian spatial reference system that represents locations in the vicinity of the Earth as X, Y, and Z measurements from its point of origin. The ECEF that is used for the Global Positioning System (GPS) is the geocentric _WGS 84_, which currently includes its own ellipsoid definition.
The `ENU` mode is far more intuitive and practical than ECEF or Geodetic coordinates. The local ENU coordinates are formed from a plane tangent to the Earth's surface fixed to a specific location.

To better understand those modes have a look at the Wikipedia pictures below:

### Earth-centered, Earth-fixed (ECEF)

The point (0,0,0) denotes the centre of the Earth (hence the name 'Earth-Centred') and the system rotates in solidarity with the Earth. The X-Y plane is coincident with the equatorial plane with the respective versors pointing in the directions of longitude 0° and 90°, while the Z-axis orthogonal to this plane points in the direction of the North Pole. The X,Y,Z coordinates are represented in metres. ECEF coordinates are used in the GPS positioning system, as they are considered to be the conventional earth reference system.

[![ECEF](https://upload.wikimedia.org/wikipedia/commons/8/88/Ecef.png "ECEF")](https://en.wikipedia.org/wiki/ECEF)

### East, North, Up (ENU)

These references are location-dependent. For movements across the globe, such as air or sea navigation, the references are defined as tangents to the lines of geographical coordinates:
- East-west axis, that is tangent to parallels,
- North-south axis, that is tangent to meridians, and
- Up-down axis in the direction normal to the oblate spheroid used as Earth's ellipsoid, which generally does not pass through the center of the Earth.

[![ENU](https://upload.wikimedia.org/wikipedia/commons/thumb/7/73/ECEF_ENU_Longitude_Latitude_relationships.svg/800px-ECEF_ENU_Longitude_Latitude_relationships.svg.png "ENU")](https://en.wikipedia.org/wiki/Local_tangent_plane_coordinates)


In this library, any point can be created using `LLA` struct: 
```julia
fields_institute_lla = LLA(43.658813, -79.397574, 0.0)
```
	LLA(43.658813, -79.397574, 0.0)


The library enables [conversion between diiferent coordinates systems](https://en.wikipedia.org/wiki/Geographic_coordinate_conversion).


```julia
fields_ecef = OpenStreetMapX.ECEF(fields_institute_lla)
```
    ECEF(850365.5982110817, -4.542824565319083e6, 4.380743975743749e6)

Constructors for all-ways conversions are provided in the library. 

Once having a point it can be plotted (this requires installation of folium - see the README on the main project page):


```julia
using PyCall
flm = pyimport("folium") #note that this requires folium to be installed
m = flm.Map()

flm.CircleMarker((fields_LLA.lat, fields_LLA.lon),
        tooltip="Here is the Fields Institute"
    ).add_to(m)
MAP_BOUNDS = [ Tuple(m.get_bounds()[1,:].-0.005), Tuple(m.get_bounds()[2,:].+0.005)]


m.fit_bounds(MAP_BOUNDS)

m
```