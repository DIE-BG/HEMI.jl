using DrWatson
@quickactivate "HEMI" 

using HEMI 
using DataFrames, Chain, PrettyTables

# incluimos scripts auxiliares
include(scriptsdir("TOOLS","INFLFNS","rank.jl"))
include(scriptsdir("TOOLS","PLOT","cloud_plot.jl"))

# CARGANDO DATOS
gtdata_eval = GTDATA[Date(2022, 12)]


# cargamos dataframes de resultados individuales y combinacion
loadpath = loadpath = datadir("results","optim_comb_2024_B","tray_infl","mse")
combination_loadpath = datadir("results","optim_comb_2024_B","optim_combination","mse")

results_df = collect_results(loadpath)
results_df.rank = rank.(results_df.inflfn) # para ordenar por medida
sort!(results_df,:rank)

combination_df = collect_results(combination_loadpath)


# TABLAS DE EVALUACION
eval_df = vcat(results_df, combination_df, cols=:union)

eval_df.name = measure_name.(eval_df.inflfn)

pretty_table(eval_df[:,[:name, :gt_b00_mse, :gt_t0010_mse, :gt_b10_mse, :gt_b0820_mse,:mse]])

# ┌───────────────────────────────────────────────┬────────────┬──────────────┬────────────┬──────────────┬──────────┐
# │                                          name │ gt_b00_mse │ gt_t0010_mse │ gt_b10_mse │ gt_b0820_mse │      mse │
# │                                        String │   Float32? │     Float32? │   Float32? │     Float32? │ Float32? │
# ├───────────────────────────────────────────────┼────────────┼──────────────┼────────────┼──────────────┼──────────┤
# │                  Percentil equiponderado 72.0 │   0.198929 │      0.13699 │  0.0716826 │    0.0931889 │ 0.129344 │
# │                      Percentil ponderado 70.0 │   0.449025 │     0.262252 │   0.235587 │      0.28721 │ 0.328702 │
# │     Media Truncada Equiponderada (62.0, 80.0) │   0.206065 │     0.175873 │  0.0616246 │    0.0764381 │ 0.128821 │
# │         Media Truncada Ponderada (23.0, 95.0) │   0.322878 │      0.20989 │   0.161363 │     0.172707 │ 0.233058 │
# │    Inflación de exclusión dinámica (0.3, 1.5) │   0.306323 │     0.225251 │   0.117095 │     0.156506 │ 0.203323 │
# │ Exclusión fija de gastos básicos IPC (13, 18) │   0.840445 │     0.922123 │   0.460784 │     0.523076 │ 0.644412 │
# │                  Subyacente óptima MSE 2024 B │   0.187105 │     0.140689 │  0.0623177 │    0.0805274 │ 0.119487 │
# └───────────────────────────────────────────────┴────────────┴──────────────┴────────────┴──────────────┴──────────┘


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
    "Subyacente Óptima MSE 2024 B"
]

mkpath(datadir("results","optim_comb_2024_B","graph","mse"))

savename = [
    datadir("results","optim_comb_2024_B","graph","mse","PercEq.png")
    datadir("results","optim_comb_2024_B","graph","mse","PercW.png")
    datadir("results","optim_comb_2024_B","graph","mse","TMEQ.png")
    datadir("results","optim_comb_2024_B","graph","mse","TMW.png")
    datadir("results","optim_comb_2024_B","graph","mse","DE.png")
    datadir("results","optim_comb_2024_B","graph","mse","FE.png")
    datadir("results","optim_comb_2024_B","graph","mse","OPT.png")
]

cloud_plot(tray_infl, tray_infl_pob, gtdata_eval; title=measure, savename=savename, cmu_font=true)