using Documenter, CompleteDung

makedocs(
    modules = [CompleteDung],
    format = :html,
    sitename = "CompleteDung.jl",
    pages = Any["index.md"]
)

deploydocs(
    repo = "github.com/yakir12/CompleteDung.jl.git",
    target = "build",
    julia = "1.0",
    deps = nothing,
    make = nothing,
)
