"""
    InflationEvalTools

Tipos, funciones y demás utilidades de simulación para evaluación de medidas
inflación.
"""
module InflationEvalTools

    using DrWatson 
    using Dates
    using CPIDataBase
    using InflationFunctions
    using Random, Distributions
    using ProgressMeter
    using Distributed
    using SharedArrays
    using Reexport
    using StableRNGs
    using OnlineStats: Mean, fit!, merge, value
    using LinearAlgebra: det, mul!

    ## Configuración por defecto de la semilla para el proceso de simulación
    """
        const DEFAULT_SEED

    Semilla por defecto utilizada para el proceso de simulación y la
    reproducibilidad de los resultados.
    """
    const DEFAULT_SEED = 314159


    ## Funciones de remuestreo de bases del IPC
    export ResampleSBB, ResampleGSBB, ResampleScrambleVarMonths, ResampleGSBBMod
    export get_param_function, method_name, method_tag
    
    # Métodos generales para funciones de remuestreo 
    include("resample/ResampleFunction.jl")

    # Método de remuestreo de remuestreo utilizando selección de mismos meses de
    # ocurrencia
    include("resample/ResampleScrambleVarMonths.jl")
    # Método de remuestreo con Stationary Block Bootstrap
    include("resample/ResampleSBB.jl")
    # Método de remuestreo con Generalized Seasonal Block Bootstrap modificado
    # para 300 observaciones de salida
    include("resample/ResampleGSBBMod.jl")
    # Método de remuestreo con Generalized Seasonal Block Bootstrap 
    include("resample/ResampleGSBB.jl")
    
    ## Funciones para aplicación de tendencia
    export RWTREND
    include("trend/RWTREND.jl") 
    
    export TrendRandomWalk, TrendAnalytical, TrendExponential, TrendIdentity
    include("trend/TrendFunction.jl")

    ## Métodos para obtener las bases de variaciones intermensuales paramétricas
    export param_gsbb_mod, param_sbb
    include("param/param.jl")

    export InflationParameter, ParamTotalCPIRebase, ParamTotalCPI, ParamWeightedMean
    export ParamTotalCPILegacyRebase # parámetro evaluación 2019
    include("param/InflationParameter.jl")

    # Tipos para configuración de simulaciones
    export AbstractConfig, SimConfig, CrossEvalConfig
    export CompletePeriod, EvalPeriod, eval_periods, period_tag
    export GT_EVAL_B00, GT_EVAL_B10, GT_EVAL_T0010
    include("config/SimConfig.jl")
    include("config/EvalPeriod.jl")
    
    ## Funciones de generación de trayectorias
    export gentrayinfl, pargentrayinfl
    include("simulate/gentrayinfl.jl")
    include("simulate/pargentrayinfl.jl") 
    
    ## Funciones de evaluación  
    export evalsim, makesim, dict_config, run_batch, eval_metrics
    export eval_mse_online # Función de evaluación de MSE online 
    include("simulate/metrics.jl")
    include("simulate/simutils.jl")
    include("simulate/eval_mse_online.jl")

    ## Combinación óptima MSE de estimadores 
    export combination_weights
    include("combination/combination_weights.jl")

    ## Funciones en desarrollo 
    include("dev/dev_pargentrayinfl.jl")

end
