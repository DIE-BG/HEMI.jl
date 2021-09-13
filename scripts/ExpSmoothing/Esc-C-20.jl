# # Escenario C: Evaluación de criterios básicos con cambio de parámetro de evaluación
using DrWatson
using Plots
using Chain
using DataFrames
@quickactivate "HEMI"

# Cargar el módulo de Distributed para computación paralela
using Distributed
# Agregar procesos trabajadores
addprocs(4, exeflags="--project")

# Cargar los paquetes utilizados en todos los procesos
@everywhere using HEMI

# CountryStructure con datos hasta diciembre de 2019
gtdata_eval = gtdata[Date(2020, 12)]

# ## Parámetros de evaluación
# Directorio principal de resultados y datos
SETTINGNAME = "EscC20"
SAVEPATH = datadir("results", "ExponentialSmoothing", SETTINGNAME)
DATA = gtdata

# Diccionario de configuración: 
# crea un vector con  diccionarios con una opción del parámetro de decaimiento
# en este caso alpha =0.7
dict_config = Dict(
    :inflfn => InflationExpSmoothing.(InflationTotalCPI(), 0.7), 
    :resamplefn => ResampleScrambleVarMonths(), 
    :trendfn => TrendRandomWalk(),
    :paramfn => InflationTotalRebaseCPI(60),
    :nsim => 125_000, 
    :traindate => Date(2020, 12)
) |> dict_list

# ## Ejecución de evaluación
run_batch(DATA, dict_config, SAVEPATH)

# ## Revisión de resultados
df = collect_results(SAVEPATH)
p = plot(InflationTotalCPI(), gtdata, fmt = :svg)

plot!(InflationExpSmoothing(InflationTotalCPI(), df.params[1][1]), gtdata, fmt = :svg)


PLOTSPATH = joinpath("docs", "src", "eval", SETTINGNAME, "images", "exponential_smoothing")
Plots.svg(p, joinpath(PLOTSPATH, "obs_trajectory"))





