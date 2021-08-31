# # Escenario D19-60

using DrWatson
using Chain
using Plots
using PrettyTables
using DataFrames
@quickactivate :HEMI

# ## Configuración para computación paralela

# Cargar el módulo de Distributed para computación paralela
using Distributed
# Agregar procesos trabajadores
addprocs(4, exeflags="--project")

# Cargar los paquetes utilizados en todos los procesos
@everywhere using HEMI

# ## Parámetros de evaluación

# Directorio principal de resultados y datos
SETTINGNAME = "EscD19-60"
SAVEPATH = datadir("results", "dynamic-exclusion", SETTINGNAME)
DATA = gtdata



# Diccionario de configuración

dict_config = Dict(
    :inflfn => InflationDynamicExclusion(0.54500186f0, 2.5909572f0),
    :resamplefn => ResampleSBB(36),
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

PLOTSPATH = joinpath("docs", "src", "eval", SETTINGNAME[1:4], "images", "dynamic-exclusion")

Plots.svg(p, joinpath(PLOTSPATH, "obs_trajectory_d19-60"))

## ----------------------------------------------------------------------------------------------
# ESTO NO ES PARTE DEL SCRIPT. SE UTILIZA UNICAMENTE PARA ELABORAR LAS TABLAS EN LA PAGINA HEMI
#=

df.tag = measure_tag.(df.inflfn)

res1 = @chain df begin 
    select(:tag, :mse, :mse_std_error)
    sort(:mse)
    #filter(r -> r.mse < 1, _)
    filter(:tag => s -> !occursin("FP",s), _)
end

res2 = @chain df begin 
    select(:tag, :mse, r"^mse_[bvc]")
    sort(:mse)
    #filter(r -> r.mse < 1, _)
    filter(:tag => s -> !occursin("FP",s), _)
end

res3 = @chain df begin 
    select(:tag, :rmse, :me, :mae, :huber, :corr)
    sort(:rmse)
    #filter(r -> r.rmse < 1, _)
    filter(:tag => s -> !occursin("FP",s), _)
end

tab1 = pretty_table(res1, tf=tf_markdown, formatters=ft_round(4))
tab2 = pretty_table(res2, tf=tf_markdown, formatters=ft_round(4))
tab3 = pretty_table(res3, tf=tf_markdown, formatters=ft_round(4))
=#
