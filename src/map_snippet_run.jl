# Note: install Winston using Pkg.chekout("Winston")
# this will ensure that you have the gtk plotting backend

include("map_snippet.jl")



# if you exported the map from OSM, before loading it consider using
# https://wiki.openstreetmap.org/wiki/Osmconvert
# osmconvert --drop-author winnipeg.osm -o=winn2.osm
# TODO: check what other data can be filtered out from the map

# The winnipeg.osm file can be obtained from https://szufel.pl/winnipeg.zip
md = loadMapData("winnipeg.osm")

# once you process osm.file the next time
# you can increase processing speed with load/saveMapData function
# that use fast Julia serialization instead of XML parsing
function saveMapData(md::MadData)
    f = open("map.data","w")
    serialize(f,md)
    close(f)
end

function loadMapData()::MapData
    f = open("map.data","r")
    md2 = deserialize(f)
    close(f)
    return md2
end

r = :none

for i in 1:3
    pointA = generatePointInBounds(md);
    pointB = generatePointInBounds(md);
    r = findRoute(pointA,pointB,md,true,r==:none?(:none):(r.p))
end

display(r.p)
