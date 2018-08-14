### Julia OpenStreetMap Package ###
### MIT License                 ###
### Copyright 2014              ###

### Default Speed Limits in Kilometers Per Hour ###
const SPEED_ROADS_URBAN = Dict(
    1 => 95,    # Motorway
    2 => 72,    # Trunk
    3 => 48,    # Primary
    4 => 32,    # Secondary
    5 => 22,    # Tertiary
    6 => 12,    # Residential/Unclassified
    7 => 8,     # Service
    8 => 5)     # Living street

const SPEED_ROADS_RURAL = Dict(
    1 => 110,
    2 => 90,
    3 => 80,
    4 => 72,
    5 => 55,
    6 => 40,
    7 => 15,
    8 => 15)
