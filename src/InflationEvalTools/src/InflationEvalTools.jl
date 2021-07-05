"""
    InflationEvalTools

Tipos, funciones y demás utilidades de simulación para evaluación de medidas
inflación.
"""
module InflationEvalTools

    using Dates, CPIDataBase
    using Random, Distributions
    using ProgressMeter
    using Distributed
    using SharedArrays
    using Reexport

    ## Funciones de aplicación de tendencia
    export apply_trend
    export RWTREND, SNTREND

    include("trend/apply_trend.jl") 
    

    ## Funciones de remuestreo de bases del IPC
    export ResampleSBB, ResampleGSBB, ResampleScrambleVarMonths
    export get_param_function, method_name
    
    # Métodos generales para funciones de remuestreo 
    include("resample/resample.jl")

    # Método de remuestreo de remuestreo utilizando selección de mismos meses de
    # ocurrencia
    include("resample/scramblevar.jl")
    # Método de remuestreo con Stationary Block Bootstrap
    include("resample/stationary_block_bootstrap.jl")
    # Método de remuestreo con Generalized Seasonal Block Bootstrap
    include("resample/generalized_seasonal_block_bootstrap.jl")


    ## Métodos para obtener las bases de variaciones intermensuales paramétricas
    export param_gsbb_mod, param_sbb

    include("param/param.jl")


    ## Funciones de tendencia
    export _get_ranges, TrendRandomWalk, TrendAnalytical
    include("trend/TrendFunction.jl")

    ## Funciones de generación de trayectorias
    export gentrayinfl, pargentrayinfl
    
    include("simulate/gentrayinfl.jl")
    include("simulate/pargentrayinfl.jl") 


    ## Funciones en desarrollo 
    include("dev/dev_pargentrayinfl.jl")

end
