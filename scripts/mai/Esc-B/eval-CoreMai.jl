# # Script de evaluación de variantes de inflación subyacente MAI
using DrWatson
@quickactivate "HEMI"
using HEMI 
using Plots

## Datos de evaluación 
const EVALDATE = Date(2020,12)
gtdata_eval = gtdata[EVALDATE]

## Definimos directorios para almacenar los resultados 
savepath = datadir("results", "CoreMai", "Esc-B", "Standard")
plotspath = mkpath(plotsdir("CoreMai", "Esc-B"))

## Cargar el módulo de Distributed para computación paralela
using Distributed
# Agregar procesos trabajadores
addprocs(4, exeflags="--project")
# Cargar los paquetes utilizados en todos los procesos
@everywhere using HEMI

##
# ## Configuración para simulaciones

# Funciones de remuestreo y tendencia
paramfn = InflationTotalRebaseCPI(36, 2)
resamplefn = ResampleScrambleVarMonths() 
trendfn = TrendRandomWalk()

variants = [3, 4, 5, 8, 10, 20, 40]
maifps = [InflationCoreMai(MaiFP(i)) for i in variants]
maifs = [InflationCoreMai(MaiF(i)) for i in variants]
maigs = [InflationCoreMai(MaiG(i)) for i in variants]

inflfns = vcat(maifs, maigs, maifps)

config_mai = Dict(
    :inflfn => inflfns, 
    :resamplefn => resamplefn, 
    :trendfn => trendfn,
    :paramfn => paramfn, 
    :traindate => EVALDATE,
    :nsim => 125_000) |> dict_list

## Ejecutar la simulación 
# Usamos run_batch para gnenerar la evaluación de las configuraciones en config_mai
run_batch(gtdata, config_mai, savepath, savetrajectories=true)

## 
# ## Revisión de resultados, utilizando `collect_results`
using DataFrames
using Chain
using PrettyTables
df_mai = collect_results(savepath)

# Tabla de resultados principales del escenario 
df_results = @chain df_mai begin 
    select(:measure, :mse, :mse_std_error)
    sort(:mse)
    # filter(:measure => s -> !occursin("FP",s), _)
end
# select(df_results, :measure => ByRow(s -> match(r"(?:\w), (?:\d{1,2})", s).match |> split))
vscodedisplay(df_results)
pretty_table(df_results, tf=tf_markdown, formatters=ft_round(4))


sens_metrics = @chain df_mai begin 
    select(:measure, :rmse, :me, :mae, :huber, :corr)
    sort(:mse)
end 
# select(:measure, :mse, r"^mse_[bvc]",)
# select(:measure, :mse, :mse_std_error, r"^mse_[bvc]", :rmse, :me, :mae, :huber, :corr)
vscodedisplay(sens_metrics)
pretty_table(sens_metrics, tf=tf_markdown, formatters=ft_round(4))

## Gráficas de resultados

# Generar las gráficas de las siguientes métricas de evaluación 
measures = [:mse, :me, :mae, :rmse]
for m in measures
    lblm = uppercase(string(m))
    bar(df_results.measure, df_results[!, m], 
        label=lblm, legend=:topleft,     
        xrotation=45)
    savefig(plotsdir(plotspath, lblm))
end