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
    import Random
    using Distributions
    using ProgressMeter
    using Distributed
    using SharedArrays
    using Reexport
    using StableRNGs
    import OnlineStats
    import StatsBase
    using LinearAlgebra: I, det, mul!, dot
    using JuMP, Ipopt
    using Chain
    using JLD2
    import Optim 

    ## Configuración por defecto de la semilla para el proceso de simulación
    """
        const DEFAULT_SEED

    Semilla por defecto utilizada para el proceso de simulación y la
    reproducibilidad de los resultados.
    """
    const DEFAULT_SEED = 314159


    ## Funciones de remuestreo de bases del IPC
    export ResampleSBB, ResampleGSBB, ResampleScrambleVarMonths, ResampleGSBBMod
    export ResampleScrambleTrended
    export ResampleTrended
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
    # Método de remuestreo de remuestreo utilizando selección de mismos meses de
    # ocurrencia con distribuciones ponderadas para mantener la correlación en
    # el remuestreo
    include("resample/ResampleScrambleTrended.jl")
    # Similar al anterior, pero con parámetros individuales por base 
    include("resample/ResampleTrended.jl")
    
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
    include("config/EvalPeriod.jl")
    include("config/SimConfig.jl")
    
    ## Funciones de generación de trayectorias
    export gentrayinfl, pargentrayinfl
    include("simulate/gentrayinfl.jl")
    include("simulate/pargentrayinfl.jl") 
    
    ## Funciones de evaluación y métricas   
    export evalsim, makesim, dict_config, run_batch
    export eval_metrics, combination_metrics
    export eval_mse_online # Función de evaluación de MSE online 
    export eval_absme_online # Función de evaluación de ABSME online 
    export eval_corr_online # Función de evaluación de CORR online 
    include("simulate/metrics.jl")
    include("simulate/simutils.jl")
    include("simulate/eval_mse_online.jl")
    include("simulate/eval_absme_online.jl")
    include("simulate/eval_corr_online.jl")
    include("simulate/cvsimutils.jl") # funciones para metodología de validación cruzada
    

    ## Combinación óptima MSE de estimadores 
    export combination_weights, average_mats
    export ridge_combination_weights, lasso_combination_weights
    export share_combination_weights
    export elastic_combination_weights
    export metric_combination_weights
    export absme_combination_weights
    include("combination/combination_weights.jl")
    include("combination/metric_combination_weights.jl")
    include("combination/absme_combination_weights.jl")

    ## Funciones para evaluación cruzada
    export add_ones
    export crossvalidate
    include("combination/cross_validation.jl")

    ## Funciones en desarrollo 
    include("dev/dev_pargentrayinfl.jl")

end
