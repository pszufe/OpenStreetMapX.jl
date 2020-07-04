using OpenStreetMapX, LightGraphs, PyCall

# This code assumes that folium has benn installed


function plot_map(m::MapData, filename::AbstractString; tiles="Stamen Toner" )
    MAP_BOUNDS = [ ( m.bounds.min_y, m.bounds.min_x), ( m.bounds.max_y, m.bounds.max_x) ]
    flm = pyimport("folium")
    m_plot = flm.Map(tiles=tiles)
    for e in edges(m.g)
		info = "Edge from: $(e.src) to $(e.dst)<br>[information from the <pre>.e</pre> and <pre>.w</pre> fields] "
        flm.PolyLine(  (latlon(m,e.src), latlon(m,e.dst)),
            color="brown", weight=4, opacity=1).add_to(m_plot)
    end

    for n in keys(m.nodes)
        lla = LLA(m.nodes[n],m.bounds)
        info = "Node: $(n)\n<br>Lattitude: $(lla.lat)\n<br>Longitude: $(lla.lon)<br>[information from the <pre>.node</pre> field] "
        flm.Circle(
            (lla.lat, lla.lon),
            popup=info,
            tooltip=info,
            radius=10,
            color="orange",
            weight=3,
            fill=true,
            fill_color="orange"
          ).add_to(m_plot)
    end

	for nn in keys(m.n)
		n = m.n[nn]
        lla = LLA(m.nodes[n],m.bounds)
        info =     "Graph: $nn <br>Node: $(n)\n<br>Lattitude: $(lla.lat)\n<br>Longitude: $(lla.lon)<br>
		[The node identifiers are hold in the <pre>.n</pre> field and location in the <pre>.nodes</pre> field]"
		flm.Rectangle(
            [(lla.lat-0.00014, lla.lon-0.0002), (lla.lat+0.00014, lla.lon+0.0002)],
            popup=info,
            tooltip=info,
            color="green",
            weight=1.5,
            fill=false,
            fill_opacity=0.2,
            fill_color="green",
        ).add_to(m_plot)
    end


    MAP_BOUNDS = [( m.bounds.min_y, m.bounds.min_x),( m.bounds.max_y, m.bounds.max_x)]
    flm.Rectangle(MAP_BOUNDS, color="black",weight=4).add_to(m_plot)
    m_plot.fit_bounds(MAP_BOUNDS)
    m_plot.save(filename)
end

pth = joinpath(dirname(pathof(OpenStreetMapX)),"..","test","data","reno_east3.osm")

m2 =  OpenStreetMapX.get_map_data(pth,use_cache = false, trim_to_connected_graph=true);

plot_map(m2, "mymap.html")
