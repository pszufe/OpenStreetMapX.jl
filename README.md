# OSMsim.jl
OpenStreetMap - routing and simulations library

## Installation

The current version uses Julia 0.7.0

Before using the library you need to install Julia packages, press `]` to go to package manager:

```julia
add Plots
add Distributions
add DataFrames
add DataFramesMeta
add FreqTables
add HTTP
add Query
add Shapefile
add LibExpat
add LightGraphs
add StatsBase
```







## TODOs

1. Buffering - if the pair DA_home and DA_work has already been selected.
2. Waypoints selection based on route optimization
3. Additional activity probabilities put into Dict and calibrated
4. Function select_starting_location in python
5. Calculate stats for each given intersection - agentProfileAgregator
   * DA distribution   (simplified)
   * demographic distribution (if demographic profile determines moving patterns)
   * crosstabs
   
## 



