#cd("$(homedir())/open_map")

include("map_snippet.jl")

md = loadMapData("map.osm");

routes = []

for i in 1:5
    pointA = generatePointInBounds(md);
    pointB = generatePointInBounds(md);
    r = findRoutes(pointA,pointB,md)
	push!(routes,r)
end

