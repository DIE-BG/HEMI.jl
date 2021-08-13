# # Escenario C19: evaluación de criterios básicos con cambio de parámetro de evaluación

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
SETTINGNAME = "EscC19"
SAVEPATH = datadir("results", "dynamic-exclusion", SETTINGNAME)
DATA = gtdata

# Diccionario de configuración

dict_config = Dict(
    :inflfn => InflationDynamicExclusion(0.36832944f0, 2.2156405f0),
    :resamplefn => ResampleScrambleVarMonths(),
    :trendfn => TrendRandomWalk(),
    :paramfn => InflationTotalRebaseCPI(60),
    :nsim => 125_000,
    :traindate => Date(2019, 12)
) |> dict_list


# ## Ejecución de evaluación

run_batch(DATA, dict_config, SAVEPATH)

# ## Revisión de resultados

df = collect_results(SAVEPATH)

p = plot(InflationTotalCPI(), gtdata, fmt = :svg)
plot!(InflationDynamicExclusion(df.params[1]), gtdata, fmt = :svg)

PLOTSPATH = joinpath("docs", "src", "eval", SETTINGNAME[begin:end-2], "images", "dynamic-exclusion")

Plots.svg(p, joinpath(PLOTSPATH, "obs_trajectory_c19"))
