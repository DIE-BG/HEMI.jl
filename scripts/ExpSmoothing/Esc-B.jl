# # Escenario B: replica del trabajo efectuado en 2020 (hasta diciembre 2020) 
using DrWatson
using Plots
using Chain
@quickactivate "HEMI"

# Cargar el módulo de Distributed para computación paralela
using Distributed
# Agregar procesos trabajadores
addprocs(4, exeflags="--project")

# Cargar los paquetes utilizados en todos los procesos
@everywhere using HEMI

# CountryStructure con datos hasta diciembre de 2020
gtdata_eval = gtdata[Date(2020, 12)]

# ## Parámetros de evaluación
# Directorio principal de resultados y datos
SETTINGNAME = "EscB"
SAVEPATH = datadir("results", "ExponentialSmoothing", SETTINGNAME)
DATA = gtdata

# Diccionario de configuración: 
# crea un vector con diccionario con todas opciones de parámetro de decaimiento
# de 0.0 hasta 1.0 en pasos discretos de 0.1
dict_config = Dict(
    :inflfn => InflationExpSmoothing.(InflationTotalCPI(), 0.0:0.1:1.0), 
    :resamplefn => ResampleScrambleVarMonths(), 
    :trendfn => TrendRandomWalk(),
    :paramfn => InflationTotalRebaseCPI(36, 2),
    :nsim => 125_000, 
    :traindate => Date(2020, 12)
) |> dict_list

# ## Ejecución de evaluación
run_batch(DATA, dict_config, SAVEPATH)

# ## Revisión de resultados
using DataFrames
df = collect_results(SAVEPATH)
p = plot(InflationTotalCPI(), gtdata, fmt = :svg)

# Obteniendo el minimo MSE en función del parámetro de decaimiento
infle=minimum(df.mse[:,:])
bas = df[df[!,:mse].==infle,:]


plot!(InflationExpSmoothing(InflationTotalCPI(), bas.params[1][1]), gtdata, fmt = :svg)


PLOTSPATH = joinpath("docs", "src", "eval", SETTINGNAME, "images", "exponential_smoothing")
Plots.svg(p, joinpath(PLOTSPATH, "obs_trajectory"))

dots = DataFrame(df.params[:,1])
dots = dots[:,:1]
q= plot(dots,df.mse[:,:], seriestype =:scatter, title= "MSE vs smoothing parameter", label=["MSE"], xlabel="Smoothing parameter", ylabel="MSE")
Plots.svg(q, joinpath(PLOTSPATH, "Minimization"))




