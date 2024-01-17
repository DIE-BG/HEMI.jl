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
loadpath = loadpath = datadir("results","optim_comb_2024_B","tray_infl","absme")
combination_loadpath = datadir("results","optim_comb_2024_B","optim_combination","absme")

results_df = collect_results(loadpath)
results_df.rank = rank.(results_df.inflfn) # para ordenar por medida
sort!(results_df,:rank)

combination_df = collect_results(combination_loadpath)


# TABLAS DE EVALUACION
eval_df = vcat(results_df, combination_df, cols=:union)

eval_df.name = measure_name.(eval_df.inflfn)

pretty_table(eval_df[:,[:name, :gt_b00_absme, :gt_t0010_absme, :gt_b10_absme, :gt_b0820_absme,:absme]])

# ┌─────────────────────────────────────────────┬──────────────┬────────────────┬──────────────┬────────────────┬─────────────┐
# │                                        name │ gt_b00_absme │ gt_t0010_absme │ gt_b10_absme │ gt_b0820_absme │       absme │
# │                                      String │     Float32? │       Float32? │     Float32? │       Float32? │    Float32? │
# ├─────────────────────────────────────────────┼──────────────┼────────────────┼──────────────┼────────────────┼─────────────┤
# │                Percentil equiponderado 72.0 │    0.0456552 │       0.244838 │    0.0967062 │       0.109643 │   0.0205229 │
# │                    Percentil ponderado 70.0 │     0.268304 │       0.174206 │     0.298182 │      0.0251735 │   0.0487327 │
# │   Media Truncada Equiponderada (25.0, 95.0) │     0.473779 │        0.32802 │     0.220536 │    0.000866812 │    0.102446 │
# │       Media Truncada Ponderada (62.0, 78.0) │     0.237734 │       0.201376 │     0.320162 │    0.000841053 │   0.0746387 │
# │  Inflación de exclusión dinámica (2.3, 5.0) │     0.166354 │       0.155558 │    0.0274009 │     0.00136838 │   0.0505026 │
# │ Exclusión fija de gastos básicos IPC (7, 6) │     0.303826 │        1.00973 │      0.43262 │      0.0408153 │    0.402223 │
# │              Subyacente óptima ABSME 2024 B │     0.047155 │       0.221235 │    0.0217087 │      0.0829893 │ 0.000715202 │
# └─────────────────────────────────────────────┴──────────────┴────────────────┴──────────────┴────────────────┴─────────────┘



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
    "Subyacente Óptima ABSME 2024 B"
]

mkpath(datadir("results","optim_comb_2024_B","graph","absme"))

savename = [
    datadir("results","optim_comb_2024_B","graph","absme","PercEq.png")
    datadir("results","optim_comb_2024_B","graph","absme","PercW.png")
    datadir("results","optim_comb_2024_B","graph","absme","TMEQ.png")
    datadir("results","optim_comb_2024_B","graph","absme","TMW.png")
    datadir("results","optim_comb_2024_B","graph","absme","DE.png")
    datadir("results","optim_comb_2024_B","graph","absme","FE.png")
    datadir("results","optim_comb_2024_B","graph","absme","OPT.png")
]

cloud_plot(tray_infl, tray_infl_pob, gtdata_eval; title=measure, savename=savename, cmu_font=true)