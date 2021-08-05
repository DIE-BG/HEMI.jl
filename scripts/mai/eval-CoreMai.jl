# # Script de evaluación de variantes de inflación subyacente MAI
using DrWatson
@quickactivate "HEMI"

# Cargar el módulo de Distributed para computación paralela
using Distributed
# Agregar procesos trabajadores
addprocs(4, exeflags="--project")

# Cargar los paquetes utilizados en todos los procesos
@everywhere using HEMI

##
# ## Configuración para simulaciones

# Funciones de remuestreo y tendencia
resamplefn = ResampleScrambleVarMonths() 
trendfn = TrendRandomWalk()

variants = [3, 4, 5, 8, 10, 20, 40]
maifps = [InflationCoreMai(MaiFP(i)) for i in variants]
maifs = [InflationCoreMai(MaiF(i)) for i in variants]
maigs = [InflationCoreMai(MaiG(i)) for i in variants]

# inflfns = vcat(maifs, maigs)
inflfns = maifps

config_mai = Dict(
    :inflfn => inflfns, 
    :resamplefn => resamplefn, 
    :trendfn => trendfn,
    :paramfn => InflationTotalRebaseCPI(36, 2), 
    :traindate => Date(2019,12)
    :nsim => 125_000) |> dict_list


# Definimos el folder para almacenar los resultados 
savepath = datadir("results", "CoreMai", "Esc-A")

## Ejecutar la simulación 
# Usamos run_batch para gnenerar la evaluación de las configuraciones en config_mai
run_batch(gtdata_eval, config_mai, savepath, savetrajectories=false)

## 
# ## Revisión de resultados, utilizando `collect_results`
using DataFrames
using Chain
df_mai = collect_results(savepath)


df_results = @chain df_mai begin 
    select(:measure, :resamplefn, :mse, :mse_std_error, :rmse, :me, :mae, :huber)
    sort(:mse)
end

df_results

## 
# ## Gráficas de resultados

plotspath = mkpath(plotsdir("CoreMai"))

using Plots

# Generar las gráficas de las siguientes métricas de evaluación 
measures = [:mse, :me, :mae, :rmse]
for m in measures
    lblm = uppercase(string(m))
    bar(df_results.measure, df_results[!, m], 
        label=lblm, legend=:topleft,     
        xrotation=45)
    savefig(plotsdir(plotspath, lblm))
end