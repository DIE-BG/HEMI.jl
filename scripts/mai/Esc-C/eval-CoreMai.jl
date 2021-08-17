# # Script de evaluación de variantes de inflación subyacente MAI
using DrWatson
@quickactivate "HEMI"
using HEMI 
using Plots
using DataFrames
using Chain
using PrettyTables


## Definimos directorios para almacenar los resultados 
savepath = datadir("results", "CoreMai", "Esc-C", "Standard")
plotspath = mkpath(plotsdir("CoreMai", "Esc-C"))

## Cargar el módulo de Distributed para computación paralela
using Distributed
# Agregar procesos trabajadores
nprocs() < 5 && addprocs(4, exeflags="--project")
# Cargar los paquetes utilizados en todos los procesos
@everywhere using HEMI

##
# ## Configuración para simulaciones

# Funciones de remuestreo y tendencia
paramfn = InflationTotalRebaseCPI(60)
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
    :traindate => [Date(2019,12), Date(2020,12)],
    :nsim => 125_000) |> dict_list

## Ejecutar la simulación 
# Usamos run_batch para gnenerar la evaluación de las configuraciones en config_mai
run_batch(gtdata, config_mai, savepath, savetrajectories=true)

## 
# ## Revisión de resultados, utilizando `collect_results`
df_mai = collect_results(savepath)
EVALDATE = Date(2020,12)

# Agregar :nseg y :maitype para filtrar y ordenar resultados 
df_results = @chain df_mai begin 
    filter(r -> r.traindate == EVALDATE, _)
    transform(
        :inflfn => ByRow(fn -> fn.method.n) => :nseg,
        :measure => ByRow(s -> match(r"MAI \((\w+)", s).captures[1]) => :maitype)
    sort([:maitype, :nseg])
end

# Tabla de resultados principales del escenario 
main_results = @chain df_results begin 
    select(:measure, :mse, :mse_std_error)
    # filter(:measure => s -> !occursin("FP",s), _)
end

# Descomposición aditiva del MSE 
mse_decomp = @chain df_results begin 
    select(:measure, :mse, r"^mse_[bvc]")
end

# Otras métricas de evaluación 
sens_metrics = @chain df_results begin 
    select(:measure, :rmse, :me, :mae, :huber, :corr)
end 


pretty_table(main_results, tf=tf_markdown, formatters=ft_round(4))
pretty_table(mse_decomp, tf=tf_markdown, formatters=ft_round(4))
pretty_table(sens_metrics, tf=tf_markdown, formatters=ft_round(4))