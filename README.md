# OpenStreetMapX.jl
This is a complete re-write of OpenStreetMap.jl package.  

Compared to the original package major changes include:

- `Plots.jl` with GR is used as backend for map vizualization (via a separate package `OpenStreetMapXPlot.jl`)
- `LightGraphs.jl` is used for map data storage
- Several changes with routing algorithm (currently finding a route in a 1 million people city takes around 250ms)
- Data structure adjusment to make the library more suitable to run simulations of cities. 



## Installation

The current version uses Julia 1.0.0

```julia
using Pkg; Pkg.add(PackageSpec(url="https://github.com/pszufe/OpenStreetMapX.jl"))
```



## Usage

```julia
using OpenStreetMapX
map_data = OpenStreetMapX.get_map_data("/home/ubuntu/", "mymap.osm");

println("The map contains $(length(map_data.nodes)) nodes")

```

See the `samples` directory for a more complete example.  



**Any push requests are welcome!**