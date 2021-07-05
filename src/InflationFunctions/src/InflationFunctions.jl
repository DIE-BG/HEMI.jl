"""
    InflationFunctions

Funciones para computar estimadores muestrales de inflación. 
"""
module InflationFunctions

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

    ## Exclusión Fija de gastos básicos
    export InflationFixedExclusionCPI
    include("InflationFixedExclusionCPI.jl")

    # Temporal
    export InflationFixedExclusionCPIVarCPIBase
    include("InflationFixedExclusionCPI-VarCPIBase.jl")

    ## Desarrollo 
    include("dev/totalcpi_methods.jl")

end
