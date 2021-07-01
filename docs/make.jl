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
    push_preview = true
)
