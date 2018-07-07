
#cd("$(homedir())/open_map")

include("map_snippet.jl")



md = loadMapData("map.osm");

r = :none

for i in 1:5
    pointA = generatePointInBounds(md);
    pointB = generatePointInBounds(md);
    r = findRoute(pointA,pointB,md,true,r==:none?(:none):(r.p))
end

display(r.p)
