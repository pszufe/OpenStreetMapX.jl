### Julia OpenStreetMap Package ###
### MIT License                 ###
### Copyright 2014              ###

### Standard map display "layers." ###
const LAYER_STANDARD = Dict(
    1 => Style(0x7BB6EF, 4), # Soft blue
    2 => Style(0x66C266, 3), # Soft green
    3 => Style(0xE68080, 3), # Soft red
    4 => Style(0xFF9900, 3), # Soft orange
    5 => Style(0xDADA47, 3), # Dark yellow
    6 => Style(0x999999, 2), # Dark gray
    7 => Style(0xE0E0E0, 2), # Light gray
    8 => Style(0x999999, 1)) # Dark gray

const LAYER_CYCLE = Dict(
    1 => Style(0x006600, 3), # Green
    2 => Style(0x5C85FF, 3), # Blue
    3 => Style(0x5C85FF, 2), # Blue
    4 => Style(0x999999, 2)) # Dark gray

const LAYER_PED = Dict(
    1 => Style(0x999999, 3), # Dark gray
    2 => Style(0x999999, 3), # Dark gray
    3 => Style(0x999999, 2), # Dark gray
    4 => Style(0xE0E0E0, 2)) # Light gray

const LAYER_FEATURES = Dict(
    1 => Style(0x9966FF, 1.5, "."), # Lavender
    2 => Style(0xFF0000, 1.5, "."), # Red
    3 => Style(0x000000, 1.5, "."), # Black
    4 => Style(0xFF66FF, 1.5, "."), # Pink
    5 => Style(0x996633, 1.5, "."), # Brown
    6 => Style(0xFF9900, 2.0, "."), # Orange
    7 => Style(0xCC00CC, 1.5, ".")) # Brown

const LAYER_BUILDINGS = Dict(
    1 => Style(0xE1E1EB, 1, "-"), # Lighter gray
    2 => Style(0xB8DBFF, 1, "-"), # Light blue
    3 => Style(0xB5B5CE, 1, "-"), # Light gray
    4 => Style(0xFFFF99, 1, "-"), # Pale yellow
    5 => Style(0x006600, 1, "-")) # Green
