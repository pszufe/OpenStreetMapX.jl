# OpenStreetMap2.jl
This is a complete re-write of OpenStreetMap.jl package.  

Compared to the original package major changes include:

- `Plots.jl` with GR is used as backend for map vizualization 
- `LightGraphs.jl` is used for map data storage
- Several changes with routing algorithm (currently finding a route in a 1 million people city takes around 250ms)
- Data structure adjusment to make the library more suitable to run simulations of cities. 



## Installation

The current version uses Julia 1.0.0

```julia
using Pkg; Pkg.add(PackageSpec(url="https://github.com/pszufe/OpenStreetMap2.jl"))
```



## Usage

```julia
using OpenStreetMap2
map_data = OpenStreetMap2.get_map_data("/home/ubuntu/", "mymap.osm");

p = OpenStreetMap2.plotmap(map_data.nodes, OpenStreetMap2.ENU(mapD.bounds), roadways=map_data.roadways,roadwayStyle = OpenStreetMap2.LAYER_STANDARD, width=600, height=600)
```

See the `samples` directory for a more complete example.  



**Any push requests are welcome!**