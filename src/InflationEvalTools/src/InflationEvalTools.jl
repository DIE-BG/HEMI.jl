"""
    InflationEvalTools

Tipos, funciones y demás utilidades de simulación para evaluación de medidas
inflación.
"""
module InflationEvalTools

    using Dates, CPIDataBase
    using InflationFunctions
    using Random, Distributions
    using ProgressMeter
    using Distributed
    using SharedArrays
    using Reexport

    ## Funciones de remuestreo de bases del IPC
    export ResampleSBB, ResampleGSBB, ResampleScrambleVarMonths
    export get_param_function, method_name, method_tag
    
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

    export InflationParameter, ParamTotalCPIRebase, ParamTotalCPI, ParamWeightedMean
    include("param/InflationParameter.jl")

    
    ## Funciones para aplicación de tendencia
    export RWTREND
    include("trend/RWTREND.jl") 
    
    export TrendRandomWalk, TrendAnalytical, TrendIdentity
    include("trend/TrendFunction.jl")

    
    ## Funciones de generación de trayectorias
    export gentrayinfl, pargentrayinfl
    
    include("simulate/gentrayinfl.jl")
    include("simulate/pargentrayinfl.jl") 


    ## Funciones en desarrollo 
    include("dev/dev_pargentrayinfl.jl")

end
