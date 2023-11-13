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
loadpath = datadir("optim_comb_2024", "2000_2010","tray_infl","mse")
combination_loadpath = datadir("optim_comb_2024","2000_2010","optim_combination","mse","fx")

results_df = collect_results(loadpath)
results_df.rank = rank.(results_df.inflfn) # para ordenar por medida
sort!(results_df,:rank)

combination_df = collect_results(combination_loadpath)


# TABLAS DE EVALUACION
eval_df = vcat(results_df, combination_df, cols=:union)

eval_df.name = measure_name.(eval_df.inflfn)

pretty_table(eval_df[:,[:name, :gt_b00_mse, :gt_t0010_mse, :gt_b10_mse, :gt_b2020_mse,:mse]])

# ┌──────────────────────────────┬────────────┬──────────────┬────────────┬──────────────┬──────────┐
# │                         name │ gt_b00_mse │ gt_t0010_mse │ gt_b10_mse │ gt_b2020_mse │      mse │
# │                       String │   Float32? │     Float32? │   Float32? │     Float32? │ Float32? │
# ├──────────────────────────────┼────────────┼──────────────┼────────────┼──────────────┼──────────┤
# │      Percentil Equiponderado │   0.198929 │      0.13699 │  0.0716826 │    0.0617605 │ 0.129344 │
# │          Percentil Ponderado │    0.38762 │     0.229226 │    0.16323 │     0.149672 │ 0.262773 │
# │ Media Truncada Equiponderada │   0.171876 │     0.126962 │     0.0611 │    0.0422035 │ 0.111689 │
# │     Media Truncada Ponderada │    0.30943 │     0.188247 │   0.151998 │     0.141188 │   0.2214 │
# │           Exclusion Dinámica │   0.306323 │     0.208572 │   0.107959 │    0.0882536 │ 0.197794 │
# │               Exclusion Fija │   0.831064 │     0.884405 │   0.454582 │     0.431349 │  0.63547 │
# │   Subyacente Óptima MSE 2024 │   0.169787 │     0.119768 │  0.0601923 │    0.0430559 │ 0.109999 │
# └──────────────────────────────┴────────────┴──────────────┴────────────┴──────────────┴──────────┘

#Con Exclusión Fija
# ┌──────────────────────────────┬────────────┬──────────────┬────────────┬──────────────┬───────────┐
# │                         name │ gt_b00_mse │ gt_t0010_mse │ gt_b10_mse │ gt_b2020_mse │       mse │
# │                       String │   Float32? │     Float32? │   Float32? │     Float32? │  Float32? │
# ├──────────────────────────────┼────────────┼──────────────┼────────────┼──────────────┼───────────┤
# │      Percentil Equiponderado │   0.198929 │      0.13699 │  0.0716826 │    0.0617605 │  0.129344 │
# │          Percentil Ponderado │    0.38762 │     0.229226 │    0.16323 │     0.149672 │  0.262773 │
# │ Media Truncada Equiponderada │   0.171876 │     0.126962 │     0.0611 │    0.0422035 │  0.111689 │
# │     Media Truncada Ponderada │    0.30943 │     0.188247 │   0.151998 │     0.141188 │    0.2214 │
# │           Exclusion Dinámica │   0.306323 │     0.208572 │   0.107959 │    0.0882536 │  0.197794 │
# │               Exclusion Fija │   0.831064 │     0.884405 │   0.454582 │     0.431349 │   0.63547 │
# │   Subyacente Óptima MSE 2024 │   0.136108 │    0.0958987 │  0.0601923 │    0.0430559 │ 0.0944514 │
# └──────────────────────────────┴────────────┴──────────────┴────────────┴──────────────┴───────────┘

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
    "Subyacente Óptima MSE 2024"
]

savename = [
    datadir("optim_comb_2024","2000_2010","graph","mse","PercEq.png"),
    datadir("optim_comb_2024","2000_2010","graph","mse","PercW.png"),
    datadir("optim_comb_2024","2000_2010","graph","mse","TMEQ.png"),
    datadir("optim_comb_2024","2000_2010","graph","mse","TMW.png"),
    datadir("optim_comb_2024","2000_2010","graph","mse","DE.png"),
    datadir("optim_comb_2024","2000_2010","graph","mse","FE.png"),
    datadir("optim_comb_2024","2000_2010","graph","mse","OPT.png"),
]

cloud_plot(tray_infl, tray_infl_pob, gtdata_eval; title=measure, savename=savename, cmu_font=true)