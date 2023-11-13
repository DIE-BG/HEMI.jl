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
loadpath = datadir("optim_comb_2024", "2000_2010","tray_infl","corr")
combination_loadpath = datadir("optim_comb_2024","2000_2010","optim_combination","corr","fx")

results_df = collect_results(loadpath)
results_df.rank = rank.(results_df.inflfn) # para ordenar por medida
sort!(results_df,:rank)

combination_df = collect_results(combination_loadpath)


# TABLAS DE EVALUACION
eval_df = vcat(results_df, combination_df, cols=:union)

eval_df.name = measure_name.(eval_df.inflfn)

pretty_table(eval_df[:,[:name, :gt_b00_corr, :gt_t0010_corr, :gt_b10_corr, :gt_b2020_corr, :corr]])

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
# │  Subyacente Óptima CORR 2024 │    0.979212 │      0.971603 │    0.949007 │      0.931304 │ 0.991756 │
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

# concatenamos
tray_infl = hcat(tray_infl[:,1:6,:], combination_tray)

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
    "Subyacente Óptima CORR 2024"
]

savename = [
    datadir("optim_comb_2024","2000_2010","graph","corr","fx","PercEq.png"),
    datadir("optim_comb_2024","2000_2010","graph","corr","fx","PercW.png"),
    datadir("optim_comb_2024","2000_2010","graph","corr","fx","TMEQ.png"),
    datadir("optim_comb_2024","2000_2010","graph","corr","fx","TMW.png"),
    datadir("optim_comb_2024","2000_2010","graph","corr","fx","DE.png"),
    datadir("optim_comb_2024","2000_2010","graph","corr","fx","FE.png"),
    datadir("optim_comb_2024","2000_2010","graph","corr","fx","OPT.png"),
]

cloud_plot(tray_infl, tray_infl_pob, gtdata_eval; title=measure, savename=savename, cmu_font=true)