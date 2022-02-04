using DrWatson
@quickactivate "HEMI" 

using HEMI 

## Parallel processing
using Distributed
nprocs() < 5 && addprocs(4, exeflags="--project")
@everywhere using HEMI 

## Otras librerías
using DataFrames, Chain
using Plots

## Directorios de resultados 
config_savepath = datadir("results", "absme-combination", "Esc-G18")
tray_dir = datadir(config_savepath, "tray_infl")

# Directorios de resultados de combinación MAI 
maioptfn_path = datadir("results", "CoreMai", "Esc-G", "BestOptim", "absme-weights", "maioptfn.jld2")

# CountryStructure con datos hasta período de evaluación 
FINAL_DATE = Date(2018, 12)
gtdata_eval = gtdata[FINAL_DATE]

##  ----------------------------------------------------------------------------
#   Configuración de simulación para generación de trayectorias de combinación
#   de valor absoluto de error medio
#   ----------------------------------------------------------------------------

## Se obtiene la función de inflación, de remuestreo y de tendencia a aplicar
resamplefn = ResampleScrambleVarMonths()
trendfn = TrendRandomWalk() 
paramfn = InflationTotalRebaseCPI(36, 2)

# Medidas óptimas a diciembre de 2018

# Cargar función de inflación MAI óptima
optmai2018_absme = wload(maioptfn_path, "maioptfn")

# Configurar el conjunto de medidas a combinar

# Medida de exclusión fija óptima para minimizar el ABSME
infxexc = InflationFixedExclusionCPI(
    [35, 30, 190, 36, 37, 40, 31, 104, 162], 
    [29, 116, 31, 46, 39, 40])

inflfn = InflationEnsemble(
    InflationPercentileEq(71.6344), 
    InflationPercentileWeighted(69.5585), 
    InflationTrimmedMeanEq(35.2881, 93.4009), 
    InflationTrimmedMeanWeighted(34.1943, 93), 
    InflationDynamicExclusion(1.03194, 3.42365), 
    infxexc,
    optmai2018_absme
)

##  ----------------------------------------------------------------------------
#   Generación de datos de simulación 
#
#   Generar datos de simulación para algoritmo de combinación de valor absoluto
#   de error medio. 
#   ----------------------------------------------------------------------------

config_absme = Dict(
    :inflfn => [inflfn.functions...], 
    :resamplefn => resamplefn, 
    :trendfn => trendfn,
    :paramfn => paramfn, 
    :traindate => FINAL_DATE,
    :nsim => 125_000) |> dict_list

run_batch(gtdata, config_absme, config_savepath)

## Combinación de valor absoluto de error medio 
df_results = collect_results(config_savepath)

@chain df_results begin 
    select(:measure, :absme, :me)
end
