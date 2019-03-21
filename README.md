# OpenStreetMapX.jl

* Package for spatial analysis, simulation and vizualization of Open Street Map data 
* The plotting functionality is provided via a separate package [`OpenStreetMapXPlot.jl`](https://github.com/pszufe/OpenStreetMapXPlot.jl)

The goal of this package is to provide a backbone for multi-agent simulation of cities. 



| **Documentation** | **Build Status** |
|---------------|--------------|
|[![][docs-stable-img]][docs-stable-url] <br/> [![][docs-latest-img]][docs-dev-url]| [![Build Status][travis-img]][travis-url]  [![Coverage Status][codecov-img]][codecov-url] <br/> Linux and macOS |

## Documentation

- [**STABLE**][docs-stable-url] &mdash; **documentation of the most recently tagged version.**
- [**DEV**][docs-dev-url] &mdash; **documentation of the development version.**

[docs-latest-img]: https://img.shields.io/badge/docs-latest-blue.svg
[docs-stable-img]: https://img.shields.io/badge/docs-stable-blue.svg
[docs-dev-url]: https://pszufe.github.io/OpenStreetMapX.jl/dev
[docs-stable-url]: https://pszufe.github.io/OpenStreetMapX.jl/stable

[travis-img]: https://travis-ci.org/pszufe/OpenStreetMapX.jl.svg?branch=master
[travis-url]: https://travis-ci.org/pszufe/OpenStreetMapX.jl

[codecov-img]: https://coveralls.io/repos/github/pszufe/OpenStreetMapX.jl/badge.svg?branch=master
[codecov-url]: https://coveralls.io/github/pszufe/OpenStreetMapX.jl?branch=master

## Installation

The current version uses Julia 1.0

```julia
using Pkg; Pkg.add("OpenStreetMapX.jl")
```

Note that on Linux platform you need to separately install `libexpat` used by the library to parse XML (on Windows this step is not required). For example, on Ubuntu run in bash shell:
```bash
sudo apt install libexpat-dev
```

## Usage

```julia
using OpenStreetMapX
map_data = get_map_data("/home/ubuntu/mymap.osm");

println("The map contains $(length(map_data.nodes)) nodes")
```

See the [samples](https://github.com/pszufe/OpenStreetMapX.jl/tree/master/samples) directory for a more complete example and have a look at [`OpenStreetMapXPlot.jl`](https://github.com/pszufe/OpenStreetMapXPlot.jl) for a route plotting.  

## Obtaining map data

The simplest way to get the map data is to go to the Open Street Map project [web page](https://www.openstreetmap.org/).

In order to obtain the `*.osm` file follow the steps below:

1. Got to the area of your interest at [https://www.openstreetmap.org/](https://www.openstreetmap.org/)
2. Click the "*Export*" button at the top of the page
3. Click "*Manually select a different area*" to select the area of your interest
4. Press the "*Export*" button on the left. Note that sometimes the *Export* link does not work - in this case click one of the links below the Export button (for example the *Overpass API* link)


**Any pull requests are welcome!**




#### Acknowledgments
<sup>This code is a major re-write of project - available at [https://github.com/tedsteiner/OpenStreetMap.jl](https://github.com/tedsteiner/OpenStreetMap.jl) .


Compared to the original package major changes include:

- `LightGraphs.jl` is used for map data storage
- Several changes with routing algorithm (currently finding a route in a 1 million people city takes around 150ms)
- Added support for using Google Maps API for routing
- Data structure adjustment to make the library more suitable to run simulations of cities. 
- `Plots.jl` with GR is used as backend for map vizualization (via a separate package   [`OpenStreetMapXPlot.jl`](https://github.com/pszufe/OpenStreetMapXPlot.jl))

The creation of some parts of this source code was partially financed by research project supported by the Ontario Centres of Excellence ("OCE") under Voucher for Innovation and Productivity (VIP) program, OCE Project Number: 30293, project name: "Agent-based simulation modelling of out-of-home advertising viewing opportunity conducted in cooperation with Environics Analytics of Toronto, Canada. </sup>


