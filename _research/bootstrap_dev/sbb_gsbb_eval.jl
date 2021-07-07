# sbb_gsbb_eval.jl - Script de comparación de evaluación con los métodos de
# remuestreo de Stationary Block Bootstrap y Generalized Stational Block
# Bootstrap. 

# Se genera un lote de simulaciones para comparar ambos métodos de
# remuestreo utilizando como estimadores muestrales de inflación las medidas de:
# variación interanual del IPC y los percentiles 60 al 80 de la distribución
# transversal de variaciones intermensuales. 

using DrWatson
@quickactivate "bootstrap_dev"

## Cargar datos 
using HEMI
@load projectdir("..", "..", "data", "guatemala", "gtdata32.jld2") gt00 gt10
gtdata = UniformCountryStructure(gt00, gt10)

using Distributed
addprocs(4, exeflags="--project")

# Cargar paquetes de remuestreo y evaluación 
@everywhere begin
    using Dates, CPIDataBase
    using InflationEvalTools
    using InflationFunctions
end 

# Datos hasta dic-20
gtdata_eval = gtdata[Date(2020, 12)]



## Funciones para generar lote de simulaciones con DrWatson

# Los argumentos son strings o numéricos y dentro de la función se generan los
# valores y tipos adecuados para llevar a cabo la simulación 
function evalsim(data_eval, infl_method, resample_method, k=70, b=12; Ksim = 125_000, plotspath = nothing, period = 36)
    # Configurar la función de inflación 
    if infl_method == "total"
        inflfn = InflationTotalCPI() 
    elseif infl_method == "percentil"
        inflfn = InflationPercentileEq(k)
    end

    # Configurar el método de remuestreo y función para obtener variaciones
    # intermensuales paramétricas
    if resample_method == "sbb"
        resamplefn = ResampleSBB(b)
    elseif resample_method == "gsbb"
        resamplefn = ResampleGSBB() 
    elseif resample_method == "scramble"
        resamplefn = ResampleScrambleVarMonths() 
    end 
    paramfn = get_param_function(resamplefn)

    # Obtener la trayectoria paramétrica de inflación 
    data_param = paramfn(data_eval)
    totalrebasefn = InflationTotalRebaseCPI(period = period)
    tray_infl_pob = totalrebasefn(data_param)

    @info "Evaluación de medida de inflación" inflfn resamplefn k b Ksim

    # Generar las trayectorias de inflación de simulación 
    tray_infl = pargentrayinfl(inflfn, # función de inflación
        data_eval, # datos de evaluación hasta dic-20
        resamplefn, # remuestreo SBB
        SNTREND; # sin tendencia 
        rndseed = 0, K=Ksim)
    println()

    # Distribución del error cuadrático medio de evaluación 
    mse_dist = vec(mean((tray_infl .- tray_infl_pob) .^ 2; dims=1))

    # Generar y guardar gráficos 
    if !isnothing(plotspath)   
        histogram(mse_dist, 
            normalize=:probability, 
            label = measure_name(inflfn), 
            title = "Distribución de error cuadtrático medio (MSE)",
            xlabel = "MSE del período completo de simulación")


        params = @strdict infl_method resample_method k b Ksim
        savefig(joinpath(plotspath, savename("mse_dist", params)))
    end

    # Métricas de evaluación 
    std_mse = std(mse_dist)
    std_sim_error = std((tray_infl .- tray_infl_pob) .^ 2) / sqrt(Ksim)
    mse = mean( (tray_infl .- tray_infl_pob) .^ 2) 
    rmse = mean( sqrt.((tray_infl .- tray_infl_pob) .^ 2))
    me = mean((tray_infl .- tray_infl_pob))
    @info "Métricas de evaluación:" mse std_mse std_sim_error rmse me

    # Devolver estos valores
    mse_dist, mse, std_mse, std_sim_error, rmse, me
end


results = evalsim(gtdata_eval, "total", "sbb", 64, 36, Ksim = 10000, period = 60)

function makesim(data, params::Dict; path = nothing)
    # Obtener parámetros de simulación 
    @unpack infl_method, resample_method, k, b, Ksim = params

    # Ejecutar la simulación y obtener los resultados 
    mse_dist, mse, std_mse, std_sim_error, rmse, me = evalsim(data, infl_method, resample_method, k, b, Ksim=Ksim; plotspath = path)

    # Agregar resultados a diccionario 
    results = copy(params)
    results["mse_dist"] = mse_dist
    results["mse"] = mse
    results["std_mse"] = std_mse
    results["std_sim_error"] = std_sim_error
    results["rmse"] = rmse
    results["me"] = me

    return results 
end

## Definición de parámetros de simulación 

# Remuestreo GSBB para las medidas de percentiles 
gsbb_perc_params = Dict(
    "infl_method" => "percentil", 
    "resample_method" => "gsbb", 
    "k" => collect(60:80), 
    "b" => 0, 
    "Ksim" => [10_000, 125_000]
) |> dict_list

# Remuestreo SBB para las medidas de percentiles 
sbb_perc_params = Dict(
    "infl_method" => "percentil", 
    "resample_method" => "sbb", 
    "k" => collect(60:80), 
    "b" => [12, 25, 36], 
    "Ksim" => [10_000, 125_000]
) |> dict_list

# Remuestreo GSBB para la medida de inflación total 
gsbb_total_params = Dict(
    "infl_method" => "total", 
    "resample_method" => "gsbb", 
    "k" => 0, 
    "b" => 0, 
    "Ksim" => [10_000, 125_000]) |> dict_list

# Remuestreo SBB para la medida de inflación total
sbb_total_params = Dict(
    "infl_method" => "total", 
    "resample_method" => "sbb", 
    "k" => 0, 
    "b" => [12, 25, 36], 
    "Ksim" => [10_000, 125_000]) |> dict_list

# Remuestreo ResampleScrambleVarMonths para percentiles
scramble_perc_params = Dict(
    "infl_method" => "percentil", 
    "resample_method" => "scramble", 
    "k" => collect(60:80), 
    "b" => 0, 
    "Ksim" => [10_000, 125_000]) |> dict_list

# sim_params = vcat(scramble_perc_params)
sim_params = vcat(gsbb_perc_params, sbb_perc_params, gsbb_total_params, sbb_total_params)
# sim_params = vcat(gsbb_total_params, sbb_total_params)


## Generación de simulaciones 

function run_batch(data, sim_params, savepath, plotspath) 

    # Ejecutar lote de simulaciones 
    for (i, params) in enumerate(sim_params)
        @info "Ejecutando simulación $i..."
        results = makesim(data, params, path=plotspath)

        # Guardar los resultados 
        filename = savename("eval", params, "jld2")
        wsave(joinpath(savepath, filename), results)
    end

end 


## Ejecutar la simulación 

savepath = mkpath(datadir("bootstrap_methods", "eval_sbb_gsbbmod"))
plotspath = mkpath(plotsdir("bootstrap_methods", "eval_sbb_gsbbmod"))
run_batch(gtdata_eval, sim_params, savepath, plotspath)


## Análisis de resultados 

using DataFrames

# Obtener los resultados del directorio de simulaciones 
df = collect_results(savepath)

## Inspeccionar el DataFrame
select(df, Not(:mse_dist))

propertynames(df)

## Gráficas de evaluación de percentiles

# Función para graficar métricas en función del número de percentil
function percentile_eval_plot(df; K = 125_000, method = "sbb", b = 25, stat = :mse, ylabel = "MSE", title = "Evaluación")

    # Filtrar resultados 
    sbb_perc = filter(df) do r
        r.infl_method == "percentil" && r.Ksim == K && r.resample_method == method && r.b == b
    end

    # Obtener métrica de evaluación 
    if stat == :me
        kmin = argmin(abs.(sbb_perc[!, stat]))
    else
        kmin = argmin(sbb_perc[!, stat])
    end

    p = scatter(sbb_perc[!, :k], sbb_perc[!, stat], 
        label="Percentil equiponderado", 
        legend = :topleft, 
        xlabel = "Percentil equiponderado", 
        ylabel = ylabel, 
        title = title)
    scatter!(p, [sbb_perc[kmin, :k]], [sbb_perc[kmin, stat]], 
        label="Percentil óptimo")

    p
end

# Utiliza la función anterior para generar gráficas de las métricas dee MSE, ME y RMSE
function percentile_group_plot(; method, b, suptitle)
    p_mse = percentile_eval_plot(df, method = method, b = b, stat = :mse, 
        title = "")

    p_rmse = percentile_eval_plot(df, method = method, b = b, stat = :rmse, 
        title = "", 
        ylabel="RMSE")

    p_me = percentile_eval_plot(df, method = method, b = b, stat = :me, 
        title = "", 
        ylabel="ME")

    # Layout para gráficas de evaluación 
    l = @layout [a{0.001h}; grid(3,1)]
    p_group = plot(
        plot(title=suptitle, grid=false, showaxis = false, ticks = false), 
        p_mse, p_rmse, p_me, 
        size=(600, 800), 
        layout=l)

    p_group
end


## Gráficas de evaluación GSBB

p_gsbb = percentile_group_plot(method = "gsbb", b = 0, suptitle = "GSBB modificado")
savefig(joinpath(plotspath, "eval_perc_gsbb"))

# Gráficas de evaluación SBB
p_sbb = [] 
for b in [12, 25, 36]
    p = percentile_group_plot(method = "sbb", b = b, suptitle = "SBB, b=$b")
    push!(p_sbb, p)
    savefig(joinpath(plotspath, "eval_perc_sbb_b=$b"))
end

# Mosaico con todas las gráficas, GSBB y SBB con b = 12, 25, 36
plot(p_gsbb, p_sbb..., 
    size = (1200, 800),
    layout = (1, 4))
savefig(joinpath(plotspath, "eval_perc_sbb_gsbbmod"))



## Gráficas de evaluación de variación interanual del IPC

# Filtrar resultados 
results_total = filter(df) do r
    r.infl_method == "total" && r.Ksim == 125_000
end

# Gráficas de MSE, RMSE y ME (error medio)
total_mse = bar(["GSBB (modificado)", "SBB, b=12", "SBB, b=25", "SBB, b=36"], results_total.mse, 
    label = "Variación interanual IPC", 
    ylabel = "MSE")

total_rmse = bar(["GSBB (modificado)", "SBB, b=12", "SBB, b=25", "SBB, b=36"], results_total.rmse, 
    label = "Variación interanual IPC", 
    ylabel = "RMSE")
    
total_me = bar(["GSBB (modificado)", "SBB, b=12", "SBB, b=25", "SBB, b=36"], results_total.me, 
    label = "Variación interanual IPC", 
    ylabel = "ME")


# Gráfica de resultados de evaluación
l = @layout [a{0.001h}; grid(3,1)]
plot(
    plot(title="Evaluación de variación interanual IPC", grid=false, showaxis = false, ticks = false), 
    total_mse, total_rmse, total_me, 
    size = (600, 800), 
    layout = l)
savefig(joinpath(plotspath, "eval_total_sbb_gsbbmod"))

## Resultados resumidos 

using PrettyTables

# Se muestran resultados resumidos para los mejores percentiles y para la variación interanual del IPC

# Filtrar resultados 
sbb_perc = filter(df) do r
    r.infl_method == "percentil" && r.Ksim == 125_000 && r.k == 71 
end

best_perc = first(select(sbb_perc, [:resample_method, :b, :k, :mse, :std_mse, :rmse, :me]), 10)
pretty_table(best_perc, tf=tf_markdown)

# Variación interanual del IPC
best_total = first(select(results_total, [:resample_method, :b, :mse, :std_mse, :rmse, :me]), 10)
pretty_table(best_total, tf=tf_markdown)
