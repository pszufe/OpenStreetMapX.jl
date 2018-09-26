### Julia OpenStreetMap2 Package ###
### MIT License                 ###
### Copyright 2014              ###

### Standard map display "layers." ###
const LAYER_STANDARD = Dict(
    1 => OpenStreetMap2.Style("0x7BB6EF", 4), # Soft blue
    2 => OpenStreetMap2.Style("0x66C266", 3), # Soft green
    3 => OpenStreetMap2.Style("0xE68080", 3), # Soft red
    4 => OpenStreetMap2.Style("0xFF9900", 3), # Soft orange
    5 => OpenStreetMap2.Style("0xDADA47", 3), # Dark yellow
    6 => OpenStreetMap2.Style("0x999999", 2), # Dark gray
    7 => OpenStreetMap2.Style("0xE0E0E0", 2), # Light gray
    8 => OpenStreetMap2.Style("0x999999", 1)) # Dark gray

const LAYER_CYCLE = Dict(
    1 => OpenStreetMap2.Style("0x006600", 3), # Green
    2 => OpenStreetMap2.Style("0x5C85FF", 3), # Blue
    3 => OpenStreetMap2.Style("0x5C85FF", 2), # Blue
    4 => OpenStreetMap2.Style("0x999999", 2)) # Dark gray

const LAYER_PED = Dict(
    1 => OpenStreetMap2.Style("0x999999", 3), # Dark gray
    2 => OpenStreetMap2.Style("0x999999", 3), # Dark gray
    3 => OpenStreetMap2.Style("0x999999", 2), # Dark gray
    4 => OpenStreetMap2.Style("0xE0E0E0", 2)) # Light gray

const LAYER_FEATURES = Dict(
    1 => OpenStreetMap2.Style("0x9966FF", 1.5, "."),  # Lavender
    2 => OpenStreetMap2.Style("0xFF0000", 1.5, "."),  # Red
    3 => OpenStreetMap2.Style("0x000000", 1.5, "."),  # Black
    4 => OpenStreetMap2.Style("0xFF66FF", 1.5, "."),  # Pink
    5 => OpenStreetMap2.Style("0x996633", 1.5, "."),  # Brown
    6 => OpenStreetMap2.Style("0xFF9900", 2.0, "."),  # Orange
    7 => OpenStreetMap2.Style("0xCC00CC", 1.5, "."),  # Brown
	8 => OpenStreetMap2.Style("0xFFFF00", 1.5, "."),  # Yellow
    9 => OpenStreetMap2.Style("0xF4CCCC", 1.5, "."),  # Vanilla Ice 
    10 => OpenStreetMap2.Style("0x351C75", 1.5, "."), # Persian Indigo 
    11 => OpenStreetMap2.Style("0x00FF00", 1.5, "."), # Lime
    12 => OpenStreetMap2.Style("0x00FFFF", 1.5, "."), # Aqua
    13 => OpenStreetMap2.Style("0x005353", 2.0, "."), # Sherpa Blue 
    14 => OpenStreetMap2.Style("0xBDAD7D", 1.5, "."), # Ecru
    15 => OpenStreetMap2.Style("0xFF00FF", 1.5, "."), # Fuchsia 
    16 => OpenStreetMap2.Style("0xB9D1D6", 1.5, "."), # Light Blue 
    17 => OpenStreetMap2.Style("0x7A00CC", 1.5, "."), # Violet
    18 => OpenStreetMap2.Style("0x004225", 1.5, "."), # British Racing Green 
    19 => OpenStreetMap2.Style("0x7E8386", 2.0, "."), # Silver
    20 => OpenStreetMap2.Style("0xB87333", 1.5, "."), # Copper
    21 => OpenStreetMap2.Style("0x800020", 1.5, "."), # Burgundy
    22 => OpenStreetMap2.Style("0x5B718D", 1.5, "."), # Ultramarine
    23 => OpenStreetMap2.Style("0x636F22", 1.5, "."), # Fiji Green 
    24 => OpenStreetMap2.Style("0xCAF4DF", 1.5, "."), # Mint
    25 => OpenStreetMap2.Style("0x231F66", 2.0, "."), # Midnight Blue
    26 => OpenStreetMap2.Style("0xE6DFE7", 1.5, ".")) # Selago

const LAYER_BUILDINGS = Dict(
    1 => OpenStreetMap2.Style("0xE1E1EB", 1, "-"), # Lighter gray
    2 => OpenStreetMap2.Style("0xB8DBFF", 1, "-"), # Light blue
    3 => OpenStreetMap2.Style("0xB5B5CE", 1, "-"), # Light gray
    4 => OpenStreetMap2.Style("0xFFFF99", 1, "-"), # Pale yellow
    5 => OpenStreetMap2.Style("0x006600", 1, "-")) # Green
