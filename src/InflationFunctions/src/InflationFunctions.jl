"""
    InflationFunctions

Funciones para computar estimadores muestrales de inflación. 
"""
module InflationFunctions

    using CPIDataBase
    using Statistics
    using StatsBase
    using SparseArrays
    using RecipesBase

    ## Métodos a extender 
    import CPIDataBase: measure_name, measure_tag, params

    
    ## Media simple interanual 
    export InflationSimpleMean
    include("InflationSimpleMean.jl")

    ## Media ponderada interanual 
    export InflationWeightedMean
    include("InflationWeightedMean.jl")

    ## Método de medias móviles y suavizamiento exponencial simple (SES)
    export InflationMovingAverage, InflationExpSmoothing
    include("InflationMovingAverage.jl")
    include("InflationExpSmoothing.jl")

    ## Percentiles equiponderados
    export InflationPercentileEq
    include("InflationPercentileEq.jl")

    ## Percentiles ponderados
    export InflationPercentileWeighted
    include("InflationPercentileWeighted.jl")

    ## Variación interanual IPC con cambio de base sintético 
    export InflationTotalRebaseCPI
    include("InflationTotalRebaseCPI.jl")

    ## Media Truncada Equiponderada 
    export InflationTrimmedMeanEq
    include("InflationTrimmedMeanEq.jl")

    ## Media Truncada Ponderada 
    export InflationTrimmedMeanWeighted
    include("InflationTrimmedMeanWeighted.jl")

    ## Exclusión Fija de gastos básicos
    export InflationFixedExclusion, InflationFixedExclusionCPI
    include("InflationFixedExclusionCPI.jl")
    include("InflationFixedExclusion.jl")

    ## Subyacente MAI (muestra ampliada implícitamente)
    export MaiG, MaiF, MaiFP
    export InflationCoreMai
    include("mai/TransversalDistr.jl")
    include("mai/renormalize.jl")
    include("mai/InflationCoreMai.jl")

    ## Exclusión dinámica
    export InflationDynamicExclusion
    include("InflationDynamicExclusion.jl")

    ## Inflación constante 
    export InflationConstant
    include("InflationConstant.jl")
    
    ## Etiquetas 
    include("inflation_tags.jl")

    ## Desarrollo 
    include("dev/totalcpi_methods.jl")

    ## Recetas para Gráficas
    include("recipes/plotrecipes.jl")

end
