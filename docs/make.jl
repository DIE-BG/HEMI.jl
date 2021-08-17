using HEMI
using Documenter, Literate

DocMeta.setdocmeta!(HEMI, :DocTestSetup, :(using HEMI); recursive=true)
DocMeta.setdocmeta!(InflationFunctions, :DocTestSetup, :(using HEMI); recursive=true)
DocMeta.setdocmeta!(InflationEvalTools, :DocTestSetup, :(using HEMI); recursive=true)

EXAMPLES_DIR = joinpath(@__DIR__, "..", "scripts", "examples")
OUTPUT_DIR   = joinpath(@__DIR__, "src", "generated")
examples = ["explore_data.jl"]

# Función para preprocesar y remover secciones de vscode
function preprocess(content)
    return replace(content, r"^##$."ms => "")
end

for example in examples
    example_path = joinpath(EXAMPLES_DIR, example)
    Literate.markdown(example_path, OUTPUT_DIR, documenter=true, preprocess=preprocess)
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
    doctest = true, 
    pages=[
        "Acerca" => "index.md",
        "Guía rápida" => "guides/Guia-rapida.md",
        "Ejemplos" => example_pages,
        "Guía de evaluación" => "guides/Guia-evaluacion.md", 
        "Evaluación" => [
            "Escenario A" => [
                "eval/EscA/evaluacion-dynEx.md", 
                "eval/EscA/evaluacion-MT.md",
                "eval/EscA/evaluacion-MAI.md", 
            ],            
            "Escenario B" => [
                "eval/EscB/evaluacion-dynEx.md",
                "eval/EscB/evaluacion-MT.md",
                "eval/EscB/evaluacion-MAI.md",
            ],
            "Escenario C" => [
                "eval/EscC/evaluacion-dynEx.md", 
                "eval/EscC/evaluacion-MAI.md",
            ]
        ],
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
