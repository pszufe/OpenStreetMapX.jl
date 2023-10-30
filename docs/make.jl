using Documenter
using Pkg


if isfile("src/OpenStreetMapX.jl")
    if !("." in LOAD_PATH)
        push!(LOAD_PATH,".")
    end
elseif isfile("../src/OpenStreetMapX.jl")
    if !(".." in LOAD_PATH)
	   push!(LOAD_PATH,"..")
    end
end

using OpenStreetMapX

makedocs(
    sitename = "OpenStreetMapX",
    format = format = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true"
    ),
    modules = [OpenStreetMapX],
    pages = ["index.md", "spatial.md", "reference.md"],
    checkdocs = :exports,
    doctest = true
)


deploydocs(
    repo ="github.com/pszufe/OpenStreetMapX.jl.git",
    target="build"
)
