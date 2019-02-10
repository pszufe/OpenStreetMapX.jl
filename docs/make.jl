using Documenter
try
    using OpenStreetMapX
catch
    if !("../src/" in LOAD_PATH)
       push!(LOAD_PATH,"../src/")
       @info "Added \"../src/\"to the path: $LOAD_PATH "
       using OpenStreetMapX
    end
end

makedocs(
    sitename = "OpenStreetMapX",
    format = format = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true"
    ),
    modules = [OpenStreetMapX],
    pages = ["index.md", "reference.md"],
    doctest = true
)


deploydocs(
    repo ="github.com/pszufe/OpenStreetMapX.jl.git",
    target="build"
)
