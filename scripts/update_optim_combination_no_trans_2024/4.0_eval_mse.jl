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
loadpath = datadir("results","optim_comb_no_trans_2024","tray_infl","mse")
combination_loadpath = datadir("results","optim_comb_no_trans_2024","optim_combination","mse")

results_df = collect_results(loadpath)
results_df.rank = rank.(results_df.inflfn) # para ordenar por medida
sort!(results_df,:rank)

combination_df = collect_results(combination_loadpath)


# TABLAS DE EVALUACION
eval_df = vcat(results_df, combination_df, cols=:union)

eval_df.name = measure_name.(eval_df.inflfn)

pretty_table(eval_df[:,[:name, :gt_b00_mse, :gt_t0010_mse, :gt_b10_mse, :gt_b2020_mse,:mse]])

# ┌─────────────────────────────────────────┬─────────────┬───────────────┬─────────────┬───────────────┬───────────┐
# │                                    name │ gt_b00_mse  │ gt_t0010_mse  │ gt_b10_mse  │ gt_b2020_mse  │      mse  │
# │                                  String │   Float32?  │     Float32?  │   Float32?  │     Float32?  │ Float32?  │
# ├─────────────────────────────────────────┼─────────────┼───────────────┼─────────────┼───────────────┼───────────┤
# │                 Percentil Equiponderado │   0.895777  │     0.500595  │  0.0782798  │    0.0723668  │ 0.448844  │
# │                     Percentil Ponderado │   0.882502  │     0.516457  │   0.251338  │       0.2353  │  0.53479  │
# │            Media Truncada Equiponderada │    0.49936  │     0.374291  │  0.0561285  │    0.0523266  │ 0.260919  │
# │                Media Truncada Ponderada │   0.539072  │     0.302937  │   0.123416  │     0.115473  │ 0.310298  │
# │                      Exclusion Dinámica │   0.575653  │     0.387586  │   0.212323  │     0.191696  │ 0.376476  │
# │                          Exclusion Fija │   0.707091  │     0.478594  │   0.254387  │     0.244626  │ 0.459174  │
# │ Subyacente Óptima MSE 2024 No Transable │    0.40652* │     0.246328* │  0.0547357* │    0.0511158* │ 0.214625* │
# └─────────────────────────────────────────┴─────────────┴───────────────┴─────────────┴───────────────┴───────────┘



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
    "Subyacente Óptima MSE 2024 No Transable"
]

savename = [
    datadir("results","optim_comb_no_trans_2024","graph","mse","PercEq.png")
    datadir("results","optim_comb_no_trans_2024","graph","mse","PercW.png")
    datadir("results","optim_comb_no_trans_2024","graph","mse","TMEQ.png")
    datadir("results","optim_comb_no_trans_2024","graph","mse","TMW.png")
    datadir("results","optim_comb_no_trans_2024","graph","mse","DE.png")
    datadir("results","optim_comb_no_trans_2024","graph","mse","FE.png")
    datadir("results","optim_comb_no_trans_2024","graph","mse","OPT.png")
]

cloud_plot(tray_infl, tray_infl_pob, gtdata_eval; title=measure, savename=savename, cmu_font=true)