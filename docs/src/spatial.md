Notes on spatial data
=====================

Using the the library makes basic understanding of spatial data. The following [geographics coordinate systems](https://en.wikipedia.org/wiki/Geographic_coordinate_system) are supported:
- Latitude-Longitude-Altitude (LLA)
- Earth-centered, Earth-fixed (ECEF)
- East, North, Up (ENU)

The `LLA` node is the standard way to represent locations. The `ECEF` and `ENU` modes uses a distance (measured in meters) from a reference point. To better understand those modes have a look at the Wikipedia pictures below:

- Earth-centered, Earth-fixed (ECEF)

[![ECEF](https://upload.wikimedia.org/wikipedia/commons/8/88/Ecef.png "ECEF")](https://en.wikipedia.org/wiki/ECEF)

- East, North, Up (ENU)
[![ENU](https://upload.wikimedia.org/wikipedia/commons/thumb/7/73/ECEF_ENU_Longitude_Latitude_relationships.svg/800px-ECEF_ENU_Longitude_Latitude_relationships.svg.png "ENU")](https://en.wikipedia.org/wiki/Local_tangent_plane_coordinates)


Any point can be created using `LLA` struct: 
```julia
fields_institute_lla = LLA(43.658813, -79.397574, 0.0)
```
	LLA(43.658813, -79.397574, 0.0)


The library enables [conversion between diiferent coordinates systems](https://en.wikipedia.org/wiki/Geographic_coordinate_conversion). 


```julia
fields_ecef = OpenStreetMapX.ECEF(fields_institute_lla)
```
    ECEF(850365.5982110817, -4.542824565319083e6, 4.380743975743749e6)

Constructors for all-ways conversions are provided. 

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

