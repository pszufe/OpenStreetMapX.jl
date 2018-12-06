# OpenStreetMapX.jl
This is a complete re-write of OpenStreetMap.jl package.  

Compared to the original package major changes include:

- `Plots.jl` with GR is used as backend for map vizualization (via a separate package   [`OpenStreetMapXPlot.jl`](https://github.com/pszufe/OpenStreetMapXPlot.jl))
- `LightGraphs.jl` is used for map data storage
- Several changes with routing algorithm (currently finding a route in a 1 million people city takes around 250ms)
- Data structure adjustment to make the library more suitable to run simulations of cities. 

The goal of this package is to provide a backbone for multi-agent simulation of cities. The prototype simulator has been implemented in [`OpenStreetMapXSim.jl`](https://github.com/pszufe/OpenStreetMapXSim.jl)).

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

## Obtaining map data

The simplest way to get the map data is to go to the Open Street Map project [web page](https://www.openstreetmap.org/).

In order to obtain the `*.osm` file follow the steps below:

1. Got to the area of your interest at [https://www.openstreetmap.org/](https://www.openstreetmap.org/)
2. Click the "*Export*" button at the top of the page
3. Click "*Manually select a different area*" to select the area of your interest
4. Press the "*Export*" button on the left. Note that sometimes the *Export* link does not work - in this case click one of the links below the Export button (for example the *Overpass API* link)


**Any pull requests are welcome!**




#### Acknowledgments
<sup>This code is a major re-write of [https://github.com/tedsteiner/OpenStreetMap.jl](https://github.com/tedsteiner/OpenStreetMap.jl) project.
The creation of this source code was partially financed by research project supported by the Ontario Centres of Excellence ("OCE") under Voucher for Innovation and Productivity (VIP) program, OCE Project Number: 30293, project name: "Agent-based simulation modelling of out-of-home advertising viewing opportunity conducted in cooperation with Environics Analytics of Toronto, Canada. </sup>
