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
loadpath = datadir("optim_comb_2024", "2000_2010","tray_infl","absme")
combination_loadpath = datadir("optim_comb_2024","2000_2010","optim_combination","absme","fx")

results_df = collect_results(loadpath)
results_df.rank = rank.(results_df.inflfn) # para ordenar por medida
sort!(results_df,:rank)

combination_df = collect_results(combination_loadpath)


# TABLAS DE EVALUACION
eval_df = vcat(results_df, combination_df, cols=:union)

eval_df.name = measure_name.(eval_df.inflfn)

pretty_table(eval_df[:,[:name, :gt_b00_absme, :gt_t0010_absme, :gt_b10_absme, :gt_b2020_absme, :absme]])

# ┌──────────────────────────────┬──────────────┬────────────────┬──────────────┬────────────────┬───────────┐
# │                         name │ gt_b00_absme │ gt_t0010_absme │ gt_b10_absme │ gt_b2020_absme │     absme │
# │                       String │     Float32? │       Float32? │     Float32? │       Float32? │  Float32? │
# ├──────────────────────────────┼──────────────┼────────────────┼──────────────┼────────────────┼───────────┤
# │      Percentil Equiponderado │    0.0456552 │       0.244838 │    0.0967062 │       0.136627 │ 0.0205229 │
# │          Percentil Ponderado │    0.0721927 │      0.0765473 │     0.128889 │       0.167715 │  0.033325 │
# │ Media Truncada Equiponderada │   0.00251127 │       0.282779 │   0.00754266 │      0.0360675 │ 0.0151779 │
# │     Media Truncada Ponderada │    0.0030833 │      0.0172904 │      0.16029 │        0.19793 │ 0.0848399 │
# │           Exclusion Dinámica │   0.00195156 │      0.0665947 │    0.0298573 │      0.0705278 │ 0.0177504 │
# │               Exclusion Fija │     0.109512 │       0.692522 │      0.43262 │      0.0628707 │  0.304715 │
# │ Subyacente Óptima ABSME 2024 │   2.92431e-8 │       0.156374 │    0.0428695 │       0.084408 │ 0.0157373 │
# └──────────────────────────────┴──────────────┴────────────────┴──────────────┴────────────────┴───────────┘

#Evaluación considerando peso de Exclusión Fija en Base 00
# ┌──────────────────────────────┬──────────────┬────────────────┬──────────────┬────────────────┬───────────┐
# │                         name │ gt_b00_absme │ gt_t0010_absme │ gt_b10_absme │ gt_b2020_absme │     absme │
# │                       String │     Float32? │       Float32? │     Float32? │       Float32? │  Float32? │
# ├──────────────────────────────┼──────────────┼────────────────┼──────────────┼────────────────┼───────────┤
# │      Percentil Equiponderado │    0.0456552 │       0.244838 │    0.0967062 │       0.136627 │ 0.0205229 │
# │          Percentil Ponderado │    0.0721927 │      0.0765473 │     0.128889 │       0.167715 │  0.033325 │
# │ Media Truncada Equiponderada │   0.00251127 │       0.282779 │   0.00754266 │      0.0360675 │ 0.0151779 │
# │     Media Truncada Ponderada │    0.0030833 │      0.0172904 │      0.16029 │        0.19793 │ 0.0848399 │
# │           Exclusion Dinámica │   0.00195156 │      0.0665947 │    0.0298573 │      0.0705278 │ 0.0177504 │
# │               Exclusion Fija │     0.109512 │       0.692522 │      0.43262 │      0.0628707 │  0.304715 │
# │ Subyacente Óptima ABSME 2024 │   1.34031e-8 │      0.0588326 │    0.0428695 │       0.084408 │ 0.0199782 │
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
    datadir("optim_comb_2024","2000_2010","graph","absme","fx","PercEq.png"),
    datadir("optim_comb_2024","2000_2010","graph","absme","fx","PercW.png"),
    datadir("optim_comb_2024","2000_2010","graph","absme","fx","TMEQ.png"),
    datadir("optim_comb_2024","2000_2010","graph","absme","fx","TMW.png"),
    datadir("optim_comb_2024","2000_2010","graph","absme","fx","DE.png"),
    datadir("optim_comb_2024","2000_2010","graph","absme","fx","FE.png"),
    datadir("optim_comb_2024","2000_2010","graph","absme","fx","OPT.png"),
]

cloud_plot(tray_infl, tray_infl_pob, gtdata_eval; title=measure, savename=savename, cmu_font=true)