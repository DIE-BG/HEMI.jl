"""
    InflationEvalTools

Funciones y demás utilidades de simulación para evaluación.
"""
module InflationEvalTools

    using CPIDataBase: getunionalltype
using Dates, CPIDataBase
    using Random, Distributions
    using ProgressMeter
    using Distributed
    using SharedArrays
    using Reexport

    ## Funciones de generación de trayectorias
    export gentrayinfl, pargentrayinfl
    
    include("gentrayinfl.jl")
    include("pargentrayinfl.jl") 
    

    ## Funciones de aplicación de tendencia
    export apply_trend
    export RWTREND, SNTREND

    include("apply_trend.jl") 
    

    ## Módulo de remuestreo
    export ResampleSBB, ResampleGSBB
    export scramblevar, scramblevar!
    
    # Métodos generales para funciones de remuestreo 
    include("resample.jl")

    # Método de remuestreo de selección de mismos meses
    include("scramblevar.jl")
    # Método de remuestreo con Stationary Block Bootstrap
    include("stationary_block_bootstrap.jl")
    # Método de remuestreo con Generalized Seasonal Block Bootstrap
    include("generalized_seasonal_block_bootstrap.jl")


    ## Módulo de obtención de trayectorias paramétricas
    export param_gsbb_mod, param_sbb

    include("param.jl")


    ## Funciones en desarrollo 
    include("dev/dev_pargentrayinfl.jl")

    ## Módulo de desarrollo experimental
    export Devel
    module Devel
        # Development functions

    end

end
