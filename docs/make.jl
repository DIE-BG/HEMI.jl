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
                "eval/EscA/evaluacion-percentiles.md", 
                "eval/EscA/evaluacion-MT.md",
                "eval/EscA/evaluacion-dynEx.md", 
                "eval/EscA/evaluacion-exclusion-fija.md",
                "eval/EscA/evaluacion-MAI.md",
                "eval/EscA/evaluacion-combinacion-lineal-mse.md", 
                "eval/EscA/evaluacion-suavizamiento-exponencial.md",
            ],            
            "Escenario B" => [
                "eval/EscB/evaluacion-percentiles.md", 
                "eval/EscB/evaluacion-MT.md",
                "eval/EscB/evaluacion-dynEx.md",
                "eval/EscB/evaluacion-exclusion-fija.md",
                "eval/EscB/evaluacion-MAI.md",
                "eval/EscB/evaluacion-suavizamiento-exponencial.md",
            ],
            "Escenario C" => [
                "eval/EscC/evaluacion-percentiles.md",
                "eval/EscC/evaluacion-dynEx.md",
                "eval/EscC/evaluacion-MT.md", 
                "eval/EscC/evaluacion-exclusion-fija.md", 
                "eval/EscC/evaluacion-MAI.md",
                "eval/EscC/evaluacion-suavizamiento-exponencial.md",
            ],
            "Escenario D" => [
                "eval/EscD/evaluacion-percentiles.md",
                "eval/EscD/evaluacion-MT.md",
                # "eval/EscD/evaluacion-dynEx.md",
                # "eval/EscD/evaluacion-exclusion-fija.md",
                "eval/EscD/evaluacion-MAI.md",
            ], 
            "Escenario E" => [
                "eval/EscE/evaluacion-percentiles.md", 
                "eval/EscE/evaluacion-MT.md",
                # "eval/EscE/evaluacion-dynEx.md",
                # "eval/EscE/evaluacion-exclusion-fija.md",
                "eval/EscE/evaluacion-MAI.md",
                "eval/EscE/evaluacion-combinacion-lineal-mse.md",
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
