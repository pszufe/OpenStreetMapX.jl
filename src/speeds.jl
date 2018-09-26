### Julia OpenStreetMap2 Package ###
### MIT License                 ###
### Copyright 2014              ###

### Default Speed Limits in Kilometers Per Hour ###
const SPEED_ROADS_URBAN = Dict(
    1 => 100,    # Motorway
    2 => 90,    # Trunk
    3 => 90,    # Primary
    4 => 70,    # Secondary
    5 => 50,    # Tertiary
    6 => 40,    # Residential/Unclassified
    7 => 20,     # Service
    8 => 10)     # Living street

const SPEED_ROADS_RURAL = Dict(
    1 => 100,
    2 => 90,
    3 => 90,
    4 => 70,
    5 => 50,
    6 => 40,
    7 => 40,
    8 => 30)
