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
loadpath = datadir("results","optim_comb_no_trans_2024","tray_infl","absme")
combination_loadpath = datadir("results","optim_comb_no_trans_2024","optim_combination","absme")

results_df = collect_results(loadpath)
results_df.rank = rank.(results_df.inflfn) # para ordenar por medida
sort!(results_df,:rank)

combination_df = collect_results(combination_loadpath)


# TABLAS DE EVALUACION
eval_df = vcat(results_df, combination_df, cols=:union)

eval_df.name = measure_name.(eval_df.inflfn)

pretty_table(eval_df[:,[:name, :gt_b00_absme, :gt_t0010_absme, :gt_b10_absme, :gt_b2020_absme,:absme]])

# ┌──────────────────────────────┬──────────────┬────────────────┬──────────────┬────────────────┬───────────┐
# │                         name │ gt_b00_absme │ gt_t0010_absme │ gt_b10_absme │ gt_b2020_absme │     absme │
# │                       String │     Float32? │       Float32? │     Float32? │       Float32? │  Float32? │
# ├──────────────────────────────┼──────────────┼────────────────┼──────────────┼────────────────┼───────────┤
# │      Percentil Equiponderado │     0.136008 │       0.450985 │    0.0335151 │      0.0397933 │ 0.0566069 │
# │          Percentil Ponderado │    0.0756432 │       0.101324 │     0.169452 │       0.171871 │ 0.0608958 │
# │ Media Truncada Equiponderada │   0.00247808 │       0.389971 │     0.125841 │       0.128893 │  0.050266 │
# │     Media Truncada Ponderada │   0.00046241 │       0.100216 │     0.161393 │       0.163815 │  0.089001 │
# │           Exclusion Dinámica │   0.00169049 │       0.270622 │     0.251607 │       0.234534 │  0.144762 │
# │               Exclusion Fija │    0.0427078 │       0.124941 │    0.0500076 │      0.0850925 │  0.013321 │
# │ Subyacente Óptima ABSME 2024 │   6.87607e-7 │      0.0280824 │    0.0332901 │      0.0395762 │ 0.0187216 │
# └──────────────────────────────┴──────────────┴────────────────┴──────────────┴────────────────┴───────────┘

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
    "Subyacente Óptima ABSME 2024"
]

savename = [
    datadir("results","optim_comb_no_trans_2024","graph","absme","PercEq.png")
    datadir("results","optim_comb_no_trans_2024","graph","absme","PercW.png")
    datadir("results","optim_comb_no_trans_2024","graph","absme","TMEQ.png")
    datadir("results","optim_comb_no_trans_2024","graph","absme","TMW.png")
    datadir("results","optim_comb_no_trans_2024","graph","absme","DE.png")
    datadir("results","optim_comb_no_trans_2024","graph","absme","FE.png")
    datadir("results","optim_comb_no_trans_2024","graph","absme","OPT.png")
]

cloud_plot(tray_infl, tray_infl_pob, gtdata_eval; title=measure, savename=savename, cmu_font=true)