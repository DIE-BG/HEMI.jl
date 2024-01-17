using DrWatson
@quickactivate "HEMI" 

using HEMI 
using DataFrames, Chain, PrettyTables

# incluimos scripts auxiliares
include(scriptsdir("TOOLS","INFLFNS","rank.jl"))
include(scriptsdir("TOOLS","PLOT","cloud_plot.jl"))


# CARGANDO DATOS
data_loadpath = datadir("results", "no_trans", "data", "NOT_data.jld2")
NOT_GTDATA = load(data_loadpath, "NOT_GTDATA")
gtdata_eval = NOT_GTDATA[Date(2022, 12)]


# cargamos dataframes de resultados individuales y combinacion
loadpath = datadir("results","optim_comb_no_trans_2024","tray_infl","corr")
combination_loadpath = datadir("results","optim_comb_no_trans_2024","optim_combination","corr")

results_df = collect_results(loadpath)
results_df.rank = rank.(results_df.inflfn) # para ordenar por medida
sort!(results_df,:rank)

combination_df = collect_results(combination_loadpath)


# TABLAS DE EVALUACION
eval_df = vcat(results_df, combination_df, cols=:union)

eval_df.name = measure_name.(eval_df.inflfn)

pretty_table(eval_df[:,[:name, :gt_b00_corr, :gt_t0010_corr, :gt_b10_corr, :gt_b2020_corr,:corr]])

# ┌──────────────────────────────────────────┬─────────────┬───────────────┬─────────────┬───────────────┬──────────┐
# │                                     name │ gt_b00_corr │ gt_t0010_corr │ gt_b10_corr │ gt_b2020_corr │     corr │
# │                                   String │    Float32? │      Float32? │    Float32? │      Float32? │ Float32? │
# ├──────────────────────────────────────────┼─────────────┼───────────────┼─────────────┼───────────────┼──────────┤
# │                  Percentil Equiponderado │    0.865004 │      0.978975 │    0.829436 │      0.787508 │  0.97707 │
# │                      Percentil Ponderado │    0.843673 │      0.864051 │    0.649442 │      0.590779 │ 0.947842 │
# │             Media Truncada Equiponderada │    0.889519 │      0.945808 │    0.843442 │      0.803853 │ 0.975644 │
# │                 Media Truncada Ponderada │    0.876994 │      0.799852 │    0.700334 │      0.644639 │ 0.945173 │
# │                       Exclusion Dinámica │    0.871463 │      0.976091 │    0.710567 │       0.65531 │ 0.977173 │
# │                           Exclusion Fija │     0.81635 │      0.851208 │    0.506346 │      0.419585 │ 0.929513 │
# │ Subyacente Óptima CORR 2024 No Transable │    0.905868 │      0.940527 │    0.848451 │      0.809982 │ 0.974891 │
# └──────────────────────────────────────────┴─────────────┴───────────────┴─────────────┴───────────────┴──────────┘

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
    datadir("results","optim_comb_no_trans_2024","graph","corr","PercEq.png")
    datadir("results","optim_comb_no_trans_2024","graph","corr","PercW.png")
    datadir("results","optim_comb_no_trans_2024","graph","corr","TMEQ.png")
    datadir("results","optim_comb_no_trans_2024","graph","corr","TMW.png")
    datadir("results","optim_comb_no_trans_2024","graph","corr","DE.png")
    datadir("results","optim_comb_no_trans_2024","graph","corr","FE.png")
    datadir("results","optim_comb_no_trans_2024","graph","corr","OPT.png")
]

cloud_plot(tray_infl, tray_infl_pob, gtdata_eval; title=measure, savename=savename, cmu_font=true)