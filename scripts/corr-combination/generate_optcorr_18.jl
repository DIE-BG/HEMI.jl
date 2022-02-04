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
config_savepath = datadir("results", "corr-combination", "Esc-F18")
tray_dir = datadir(config_savepath, "tray_infl")

# Directorios de resultados de combinación MAI 
maioptfn_path = datadir("results", "CoreMai", "Esc-F", "BestOptim", "corr-weights", "maioptfn.jld2")

# CountryStructure con datos hasta período de evaluación 
gtdata_eval = gtdata[Date(2018, 12)]

##  ----------------------------------------------------------------------------
#   Configuración de simulación para generación de trayectorias de combinación
#   de correlación
#   ----------------------------------------------------------------------------

## Se obtiene la función de inflación, de remuestreo y de tendencia a aplicar
resamplefn = ResampleScrambleVarMonths()
trendfn = TrendRandomWalk() 
paramfn = InflationTotalRebaseCPI(36, 2)

# Medidas óptimas a diciembre de 2018

# Cargar función de inflación MAI óptima
optmai2018_corr = wload(maioptfn_path, "maioptfn")

# Configurar el conjunto de medidas a combinar

# Medida de exclusión fija óptima para minimizar el corr
infxexc = InflationFixedExclusionCPI(
    [35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159], 
    [29, 116, 31, 46, 39, 40, 186, 30, 35, 185, 197, 34, 48, 184, 41, 47, 37, 22, 25, 229, 38, 32, 274, 3, 45, 44, 33, 237, 19, 10, 24, 275, 115, 15, 59, 42, 61, 43, 113, 49, 27, 71, 23, 268, 9, 36, 236, 78, 20, 213, 273, 26]
)

inflfn = InflationEnsemble(
    InflationPercentileEq(0.7725222386666464), 
    InflationPercentileWeighted(0.8095570179714271), 
    InflationTrimmedMeanEq(55.90512060523032, 92.17767125368118), 
    InflationTrimmedMeanWeighted(46.44323324480888, 98.54608364886394), 
    InflationDynamicExclusion(0.46832260901857126, 4.974514492691691), 
    infxexc,
    optmai2018_corr
)

##  ----------------------------------------------------------------------------
#   Generación de datos de simulación 
#
#   Generar datos de simulación para algoritmo de combinación de valor absoluto
#   de error medio. 
#   ----------------------------------------------------------------------------

config_corr = Dict(
    :inflfn => [inflfn.functions...], 
    :resamplefn => resamplefn, 
    :trendfn => trendfn,
    :paramfn => paramfn, 
    :traindate => Date(2018,12),
    :nsim => 125_000) |> dict_list

run_batch(gtdata, config_corr, config_savepath)

## Combinación de correlacion 
df_results = collect_results(config_savepath)

@chain df_results begin 
    select(:measure, :corr, :me)
end

# DataFrame de combinación 
combine_df = @chain df_results begin 
    select(:measure, :corr, :me, :inflfn, 
        :path => ByRow(p -> joinpath(tray_dir, basename(p))) => :tray_path)
    sort(:corr)
end

## Obtener las trayectorias de los archivos guardados en el directorio tray_infl 
# Genera un arreglo de 3 dimensiones de trayectorias (T, n, K)
tray_infl = mapreduce(hcat, combine_df.tray_path) do path
    load(path, "tray_infl")
end