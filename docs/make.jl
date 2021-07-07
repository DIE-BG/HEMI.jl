using HEMI
using CPIDataBase
using InflationFunctions
using InflationEvalTools
using Documenter, Literate

# DocMeta.setdocmeta!(HEMI, :DocTestSetup, :(using HEMI); recursive=true)

EXAMPLES_DIR = joinpath(@__DIR__, "..", "scripts", "examples")
OUTPUT_DIR   = joinpath(@__DIR__, "src", "generated")
examples = ["explore_data.jl"]

for example in examples
    example_path = joinpath(EXAMPLES_DIR, example)
    Literate.markdown(example_path, OUTPUT_DIR, documenter=true)
end

example_pages = [
    "Carga de datos y exploración de estructuras" => "generated/explore_data.md"
]

makedocs(;
    modules=[HEMI, CPIDataBase, InflationFunctions, InflationEvalTools],
    authors="DIEBG",
    repo="https://github.com/DIE-BG/HEMI/blob/{commit}{path}#{line}",
    sitename="HEMI",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://die-bg.github.io/HEMI",
        assets=String[],
    ),
    doctest = false, 
    pages=[
        "Acerca" => "index.md",
        "Inicio" => "Inicio.md",
        "Guía rápida" => "guides/Guia-rapida.md",
        "Ejemplos" => example_pages,
        "API" => 
            ["modules/API.md",
            "modules/HEMI.md",
            "modules/CPIDataBase.md",
            "modules/InflationFunctions.md",
            "modules/InflationEvalTools.md"]
    ],
)

deploydocs(;
    repo="github.com/DIE-BG/HEMI",
    devbranch = "main",
    push_preview = true 
)
