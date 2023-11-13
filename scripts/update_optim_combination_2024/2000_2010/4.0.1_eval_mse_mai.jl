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
combination_loadpath = datadir("optim_comb_2024","2000_2010","optim_combination","mse","mai","fx")

results_df = collect_results(loadpath)
results_df.rank = rank.(results_df.inflfn) # para ordenar por medida
sort!(results_df,:rank)

combination_df = collect_results(combination_loadpath)


# TABLAS DE EVALUACION
eval_df = vcat(results_df, combination_df, cols=:union)

eval_df.name = measure_name.(eval_df.inflfn)

pretty_table(eval_df[:,[:name, :gt_b00_mse, :gt_t0010_mse, :gt_b10_mse, :gt_b2020_mse,:mse]])

# 
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
# │                       Mai FP │   0.240007 │     0.517885 │    1.35368 │      1.37794 │ 0.837538 │
# │                        Mai F │   0.215187 │     0.124751 │   0.114631 │     0.110408 │ 0.158393 │
# │                        Mai G │   0.848804 │      0.43127 │   0.361576 │      0.32134 │ 0.574519 │
# │   Subyacente Óptima MSE 2024 │   0.163287 │     0.105674 │  0.0538267 │    0.0407097 │  0.10324 │
# └──────────────────────────────┴────────────┴──────────────┴────────────┴──────────────┴──────────┘

#Evaluación considerando peso de Exclusión Fija en Base 00

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
# │                       Mai FP │   0.240007 │     0.517885 │    1.35368 │      1.37794 │  0.837538 │
# │                        Mai F │   0.215187 │     0.124751 │   0.114631 │     0.110408 │  0.158393 │
# │                        Mai G │   0.848804 │      0.43127 │   0.361576 │      0.32134 │  0.574519 │
# │   Subyacente Óptima MSE 2024 │   0.135299 │    0.0930298 │  0.0538267 │    0.0407097 │ 0.0906318 │
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
    "Subyacente Óptima MSE 2024"
]

save_name = [
    datadir("optim_comb_2024","2000_2010","graph","mse","mai","fx","PercEq.png"),
    datadir("optim_comb_2024","2000_2010","graph","mse","mai","fx","PercW.png"),
    datadir("optim_comb_2024","2000_2010","graph","mse","mai","fx","TMEQ.png"),
    datadir("optim_comb_2024","2000_2010","graph","mse","mai","fx","TMW.png"),
    datadir("optim_comb_2024","2000_2010","graph","mse","mai","fx","DE.png"),
    datadir("optim_comb_2024","2000_2010","graph","mse","mai","fx","FE.png"),
    datadir("optim_comb_2024","2000_2010","graph","mse","mai","fx","MAIFP.png"),
    datadir("optim_comb_2024","2000_2010","graph","mse","mai","fx","MAIF.png"),
    datadir("optim_comb_2024","2000_2010","graph","mse","mai","fx","MAIG.png"),
    datadir("optim_comb_2024","2000_2010","graph","mse","mai","fx","OPT.png"),
]

cloud_plot(tray_infl, tray_infl_pob, gtdata_eval; title=measure, savename=save_name, cmu_font=true)