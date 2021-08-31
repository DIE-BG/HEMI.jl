# # Escenario A: replica del trabajo efectuado en 2020 (criterios básicos a dic-19)

using DrWatson
using Chain
using Plots
@quickactivate "HEMI"

# ## Configuración para computación paralela

# Cargar el módulo de Distributed para computación paralela
using Distributed
# Agregar procesos trabajadores
addprocs(4, exeflags="--project")

# Cargar los paquetes utilizados en todos los procesos
@everywhere using HEMI

# ## Parámetros de evaluación

# Directorio principal de resultados y datos
SETTINGNAME = "EscE"
SAVEPATH = datadir("results", "dynamic-exclusion", SETTINGNAME)
DATA = gtdata

# Diccionario de configuración

dict_config = Dict(
    :inflfn => InflationDynamicExclusion(0.56952786f0, 2.6672454f0),
    :resamplefn => ResampleSBB(36),
    :trendfn => TrendRandomWalk(),
    :paramfn => InflationTotalRebaseCPI(60),
    :nsim => 125_000,
    :traindate => Date(2018, 12)
) |> dict_list


# ## Ejecución de evaluación

run_batch(DATA, dict_config, SAVEPATH)

# ## Revisión de resultados

df = collect_results(SAVEPATH)

p = plot(InflationTotalCPI(), gtdata, fmt = :svg)
plot!(InflationDynamicExclusion(df.params[1]), gtdata, fmt = :svg)

PLOTSPATH = joinpath("docs", "src", "eval", SETTINGNAME, "images", "dynamic-exclusion")

Plots.svg(p, joinpath(PLOTSPATH, "obs_trajectory"))
