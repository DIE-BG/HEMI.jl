using DrWatson
@quickactivate "HEMI" 

using HEMI 

## Parallel processing
using Distributed
nprocs() < 5 && addprocs(4, exeflags="--project")
@everywhere using HEMI 

## Other libraries
using DataFrames, Chain
using Plots

## Directorios de resultados 
config_savepath = datadir("results", "CoreMai", "metrics-2022")
tray_dir = datadir(config_savepath, "tray_infl")

# Rutas a funciones de inflación MAI 
opt_corr_mai_path = datadir("results", "CoreMai", "Esc-F", "BestOptim", "corr-weights", "maioptfn.jld2")
opt_absme_mai_path = datadir("results", "CoreMai", "Esc-G", "BestOptim", "absme-weights", "maioptfn.jld2")
opt_mse_mai_path = datadir("results", "CoreMai", "Esc-E-Scramble", "BestOptim", "mse-weights", "maioptfn.jld2")

# CountryStructure con datos hasta período de evaluación 
gtdata_eval = gtdata[Date(2020, 12)]


##  ----------------------------------------------------------------------------
#   Configuración de simulación para generación de trayectorias de combinación
#   de valor absoluto de error medio
#   ----------------------------------------------------------------------------

## Se obtiene la función de inflación, de remuestreo y de tendencia a aplicar
resamplefn = ResampleScrambleVarMonths()
trendfn = TrendRandomWalk() 
paramfn = InflationTotalRebaseCPI(36, 2)

## Medidas óptimas a diciembre de 2018

# Cargar función de inflación MAI óptima
optmai_mse = wload(opt_mse_mai_path, "maioptfn")
optmai_absme = wload(opt_absme_mai_path, "maioptfn")
optmai_corr = wload(opt_corr_mai_path, "maioptfn")

inflfn = [
    optmai_mse.ensemble.functions..., 
    optmai_absme.ensemble.functions..., 
    optmai_corr.ensemble.functions...
]

##  ----------------------------------------------------------------------------
#   Generación de datos de simulación 
#
#   Generar datos de simulación para algoritmo de combinación de valor absoluto
#   de error medio. 
#   ----------------------------------------------------------------------------

mai_config = Dict(
    :inflfn => inflfn, 
    :resamplefn => resamplefn, 
    :trendfn => trendfn,
    :paramfn => paramfn, 
    :traindate => Date(2020,12),
    :nsim => 125_000
) |> dict_list

run_batch(gtdata, mai_config, config_savepath)

## Combinación de correlacion 
df_results = collect_results(config_savepath)

MSE_MAI = df_results[in.(df_results.measure,Ref(measure_name.(optmai_mse.ensemble.functions))),[:measure, :mse]]
ABSME_MAI = df_results[in.(df_results.measure,Ref(measure_name.(optmai_absme.ensemble.functions))),[:measure, :absme]]
CORR_MAI = df_results[in.(df_results.measure,Ref(measure_name.(optmai_corr.ensemble.functions))),[:measure, :corr]]

wsave(datadir(config_savepath, "opt_mai_eval", "optmaimse_evalresults.jld2"), "optmai_mse", MSE_MAI)
wsave(datadir(config_savepath, "opt_mai_eval", "optmaiabsme_evalresults.jld2"), "optmai_absme", ABSME_MAI)
wsave(datadir(config_savepath, "opt_mai_eval", "optmaicorr_evalresults.jld2"), "optmai_corr", CORR_MAI)
