"""
    InflationEvalTools

Funciones y demás utilidades de simulación para evaluación.
"""
module InflationEvalTools

    using CPIDataBase
    using Random
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
    export scramblevar, scramblevar!
    
    include("scramblevar.jl")


    ## Funciones en desarrollo 
    include("dev/dev_pargentrayinfl.jl")

    ## Módulo de desarrollo experimental
    export Devel
    module Devel
        # Development functions

    end

end
