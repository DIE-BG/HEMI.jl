"""
    InflationFunctions

Funciones para computar estimadores muestrales de inflación. 
"""
module InflationFunctions

    using CPIDataBase
    using Statistics
    using StatsBase

    ## Métodos a extender 
    import CPIDataBase: measure_name, measure_tag, params

    
    ## Media simple interanual 
    export InflationSimpleMean
    include("InflationSimpleMean.jl")

    ## Media ponderada interanual 
    export InflationWeightedMean
    include("InflationWeightedMean.jl")

    ## Método de medias móviles
    export InflationMovingAverage
    include("InflationMovingAverage.jl")


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
    export InflationFixedExclusionCPI
    include("InflationFixedExclusionCPI.jl")

    ## Exclusión dinámica
    export InflationDynamicExclusion
    include("InflationDynamicExclusion.jl")

    ## Desarrollo 
    include("dev/totalcpi_methods.jl")

end
