"""
    InflationFunctions

Funciones para computar estimadores muestrales de inflación. 
"""
module InflationFunctions

    using Base: skip_deleted_floor!
using CPIDataBase
    using Statistics

    ## Métodos a extender 
    import CPIDataBase: measure_name, measure_tag

    
    ## Media simple interanual 
    export InflationSimpleMean
    include("simple_mean.jl")

    ## Percentiles equiponderados
    export InflationPercentileEq
    include("percentiles_eq.jl")

    ## Variación interanual IPC con cambio de base sintético 
    export InflationTotalRebaseCPI
    include("total_cpi_rebase.jl")

    ## Media Truncada Equiponderada 
    export InflationTrimmedMeanEq
    include("InflationTrimmedMeanEq.jl")

    ## Media Truncada Ponderada 
    export InflationTrimmedMeanWeighted
    include("InflationTrimmedMeanWeighted.jl")


    ## Desarrollo 
    include("dev/totalcpi_methods.jl")

end
