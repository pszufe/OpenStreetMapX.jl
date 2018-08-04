# OSMsim.jl
OpenStreetMap - routing and simulations library

## Installation

The current version uses JuliaPro 0.6.4

Before using the library you need to install Julia packages:

```julia
Pkg.add("Winston")
Pkg.add("Distributions")
Pkg.add("DataFrames")
```

Once the packages are installed you need to replace the *tkwidget.jl* file that can be found (assuming a default JuliaPro installation) at: 

```
C:\JuliaPro-0.6.4.1\pkgs-0.6.4.1\v0.6\Tk\src\tkwidget.jl
```

Please use the tkwidget.jl [supplied in this project](https://github.com/pszufe/OSMsim.jl/raw/master/tkwidget.jl_for_replacement/tkwidget.jl). 





## TODOs



1. Buffering - if the pair DA_home and DA_work has already been secelected.
2. Add waypoints for additional activities - before and after work and optimize tha path.
3. Calculate stats for each given intersection - agentProfileAgregator
   a) DA distribution   (simplified)
   b) demographic distribution (if demographic profile determines moving patterns)
   
## 



