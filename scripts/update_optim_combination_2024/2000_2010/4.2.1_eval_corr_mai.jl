using DrWatson
@quickactivate "HEMI" 

using HEMI 
using DataFrames, Chain, PrettyTables

# incluimos scripts auxiliares
include(scriptsdir("TOOLS","INFLFNS","rank.jl"))
include(scriptsdir("TOOLS","PLOT","cloud_plot.jl"))

# definimos data a utilizar
gtdata_eval = GTDATA[Date(2022,12)]


# cargamos dataframes de resultados individuales y combinacion
loadpath = datadir("results","optim_comb_2024", "2000_2010","tray_infl","corr")
combination_loadpath = datadir("results","optim_comb_2024","2000_2010","optim_combination","corr","mai","fx")

results_df = collect_results(loadpath)
results_df.rank = rank.(results_df.inflfn) # para ordenar por medida
sort!(results_df,:rank)

combination_df = collect_results(combination_loadpath)


# TABLAS DE EVALUACION
eval_df = vcat(results_df, combination_df, cols=:union)

eval_df.name = measure_name.(eval_df.inflfn)

pretty_table(eval_df[:,[:name, :gt_b00_corr, :gt_t0010_corr, :gt_b10_corr, :gt_b2020_corr,:corr]])



#Evaluación considerando peso de Exclusión Fija en Base 00
# ┌──────────────────────────────┬─────────────┬───────────────┬─────────────┬───────────────┬──────────┐
# │                         name │ gt_b00_corr │ gt_t0010_corr │ gt_b10_corr │ gt_b2020_corr │     corr │
# │                       String │    Float32? │      Float32? │    Float32? │      Float32? │ Float32? │
# ├──────────────────────────────┼─────────────┼───────────────┼─────────────┼───────────────┼──────────┤
# │      Percentil Equiponderado │    0.975754 │     -0.479533 │    0.944824 │       0.92603 │  0.82705 │
# │          Percentil Ponderado │    0.938791 │      0.957443 │    0.842637 │      0.800629 │ 0.976889 │
# │ Media Truncada Equiponderada │    0.978948 │      0.972422 │    0.948786 │      0.931147 │ 0.991767 │
# │     Media Truncada Ponderada │    0.952713 │      0.972248 │    0.856049 │      0.816701 │ 0.980153 │
# │           Exclusion Dinámica │     0.95092 │      0.384818 │    0.900138 │       0.86652 │ 0.921108 │
# │               Exclusion Fija │     0.94211 │       0.96306 │    0.770841 │      0.692913 │ 0.973427 │
# │                       Mai FP │    0.975217 │      0.978015 │    0.935511 │      0.916071 │ 0.986009 │
# │                        Mai F │    0.975133 │      0.978349 │    0.935396 │      0.915787 │  0.98599 │
# │                        Mai G │    0.939986 │      0.973632 │    0.828343 │      0.787338 │ 0.970782 │
# │  Subyacente Óptima CORR 2024 │    0.979825 │      0.970921 │    0.948675 │      0.931004 │ 0.991251 │
# └──────────────────────────────┴─────────────┴───────────────┴─────────────┴───────────────┴──────────┘
# ----------------------------------------------------------------
## -------------- GRAFICAS DE TRAYECTORIAS ----------------------
# ---------------------------------------------------------------

# cargamos TRAYECTORIAS

# PATHS DE TRAYECTORIAS
results_df.tray_path = map(
    x->joinpath(
        loadpath,
        "tray_infl",
        basename(x)
    ),
    results_df.path
)

# TRAYECTORIAS
tray_infl = mapreduce(hcat, results_df.tray_path) do path
    load(path, "tray_infl")
end

# Cargamos trayectorias de la combinacion OPTIMA
combination_tray = collect_results(joinpath(combination_loadpath,"tray_infl")).tray_infl[1] 

#
n = sample(1:125_000,25_000)
tray_infl = tray_infl[:,:,n]
# concatenamos
tray_infl = hcat(tray_infl, combination_tray)

# Creamos trayectoria de PARAMETRO
# PARAMETRO HASTA 2022
param = InflationParameter(
    InflationTotalRebaseCPI(36, 3), 
    ResampleScrambleVarMonths(), 
    TrendRandomWalk()
)

# TRAYECOTRIAS DE LOS PARAMETROS 
tray_infl_pob      = param(gtdata_eval)

measure = [
    "Percentil Equiponderado", "Percentil Ponderado",
    "Media Truncada Equiponderada", "Media Truncada Ponderada",
    "Exclusión Dinámica", "Exclusión Fija",
    "MAI FP","MAI F","MAI G",
    "Subyacente Óptima CORR 2024"
]

save_name = [
    datadir("results","optim_comb_2024","2000_2010","graph","corr","mai","fx","PercEq.png"),
    datadir("results","optim_comb_2024","2000_2010","graph","corr","mai","fx","PercW.png"),
    datadir("results","optim_comb_2024","2000_2010","graph","corr","mai","fx","TMEQ.png"),
    datadir("results","optim_comb_2024","2000_2010","graph","corr","mai","fx","TMW.png"),
    datadir("results","optim_comb_2024","2000_2010","graph","corr","mai","fx","DE.png"),
    datadir("results","optim_comb_2024","2000_2010","graph","corr","mai","fx","FE.png"),
    datadir("results","optim_comb_2024","2000_2010","graph","corr","mai","fx","MAIFP.png"),
    datadir("results","optim_comb_2024","2000_2010","graph","corr","mai","fx","MAIF.png"),
    datadir("results","optim_comb_2024","2000_2010","graph","corr","mai","fx","MAIG.png"),
    datadir("results","optim_comb_2024","2000_2010","graph","corr","mai","fx","OPT.png"),
]

cloud_plot(tray_infl, tray_infl_pob, gtdata_eval; title=measure, savename=save_name, cmu_font=true)