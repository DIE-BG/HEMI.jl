using HEMI
using CPIDataBase
using InflationFunctions
using InflationEvalTools
using Documenter

# DocMeta.setdocmeta!(HEMI, :DocTestSetup, :(using HEMI); recursive=true)

makedocs(;
    modules=[HEMI, CPIDataBase, InflationFunctions, InflationEvalTools],
    authors="DIEBG",
    repo="https://github.com/DIE-BG/HEMI/blob/{commit}{path}#{line}",
    sitename="HEMI.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://die-bg.github.io/HEMI.jl",
        assets=String[],
    ),
    pages=[
        "Acerca" => "index.md",
        "Inicio" => "Inicio.md",
        "API" => 
            ["API.md",
            "HEMI.md",
            "CPIDataBase.md",
            "InflationFunctions.md",
            "InflationEvalTools.md"]
    ],
)

deploydocs(;
    repo="github.com/DIE-BG/HEMI",
    push_preview = true
)
