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
loadpath = loadpath = datadir("results","optim_comb_2024_B","tray_infl","corr")
combination_loadpath = datadir("results","optim_comb_2024_B","optim_combination","corr")

results_df = collect_results(loadpath)
results_df.rank = rank.(results_df.inflfn) # para ordenar por medida
sort!(results_df,:rank)

combination_df = collect_results(combination_loadpath)


# TABLAS DE EVALUACION
eval_df = vcat(results_df, combination_df, cols=:union)

eval_df.name = measure_name.(eval_df.inflfn)

pretty_table(eval_df[:,[:name, :gt_b00_corr, :gt_t0010_corr, :gt_b10_corr, :gt_b0820_corr,:corr]], tf = tf_simple)

# ================================================ ============= =============== ============= =============== ===========
#                                            name   gt_b00_corr   gt_t0010_corr   gt_b10_corr   gt_b0820_corr       corr 
#                                          String      Float32?        Float32?      Float32?        Float32?   Float32?
# ================================================ ============= =============== ============= =============== ===========
#                    Percentil equiponderado 76.0       0.97486        0.973178      0.944827        0.991486   0.990339
#                        Percentil ponderado 76.0      0.938816        0.966129      0.843291        0.978655   0.976624
#       Media Truncada Equiponderada (60.0, 88.0)      0.978863        0.974105      0.948826        0.992603   0.991718
#           Media Truncada Ponderada (58.0, 91.0)      0.951716         0.97219      0.858007           0.982    0.98024
#      Inflación de exclusión dinámica (0.1, 0.4)       0.94383        0.810332      0.899561        0.932105   0.940384
#   Exclusión fija de gastos básicos IPC (14, 55)       0.94211        0.968968      0.859313        0.979252   0.975406
#                   Subyacente óptima CORR 2024 B      0.979062        0.974777      0.949086        0.992642   0.991828
# ================================================ ============= =============== ============= =============== ===========


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
    "Subyacente Óptima CORR 2024 B"
]

mkpath(datadir("results","optim_comb_2024_B","graph","corr"))

savename = [
    datadir("results","optim_comb_2024_B","graph","corr","PercEq.png")
    datadir("results","optim_comb_2024_B","graph","corr","PercW.png")
    datadir("results","optim_comb_2024_B","graph","corr","TMEQ.png")
    datadir("results","optim_comb_2024_B","graph","corr","TMW.png")
    datadir("results","optim_comb_2024_B","graph","corr","DE.png")
    datadir("results","optim_comb_2024_B","graph","corr","FE.png")
    datadir("results","optim_comb_2024_B","graph","corr","OPT.png")
]

cloud_plot(tray_infl, tray_infl_pob, gtdata_eval; title=measure, savename=savename, cmu_font=true)