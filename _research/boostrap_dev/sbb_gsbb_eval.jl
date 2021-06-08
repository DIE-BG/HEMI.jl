# sbb_gsbb_eval.jl - Script de comparación de evaluación con los métodos de
# remuestreo de Stationary Block Bootstrap y Generalized Stational Block
# Bootstrap. 

# Se genera un lote de simulaciones para comparar ambos métodos de
# remuestreo utilizando como estimadores muestrales de inflación las medidas de:
# variación interanual del IPC y los percentiles 60 al 80 de la distribución
# transversal de variaciones intermensuales. 

using DrWatson
@quickactivate :HEMI

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
function evalsim(data_eval, infl_method, resample_method, k=70, b=12; Ksim = 125_000, plotspath = nothing)
    # Configurar la función de inflación 
    if infl_method == "total"
        inflfn = TotalCPI() 
    elseif infl_method == "percentil"
        inflfn = Percentil(k)
    end

    # Configurar el método de remuestreo y la trayectoria paramétrica
    if resample_method == "sbb"
        resamplefn = ResampleSBB(b)
        paramfn = resample_sbb
    elseif resample_method == "gsbb"
        resamplefn = ResampleGSBB() 
        paramfn = param_gsbb_mod
    end 

    # Obtener la trayectoria paramétrica de inflación 
    data_param = paramfn(data_eval)
    totalrebasefn = TotalRebaseCPI()
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
            label = measure_name(totalfn), 
            title = "Distribución de error cuadtrático medio (MSE)",
            xlabel = "MSE del período completo de simulación")


        params = @strdict infl_method resample_method k b Ksim
        savefig(joinpath(plotspath, savename("mse_dist", params)))
    end

    # Métricas de evaluación 
    std_mse = std(mse_dist)
    std_sim_error = std_mse / sqrt(Ksim)
    mse = mean( (tray_infl .- tray_infl_pob) .^ 2) 
    rmse = mean( sqrt.((tray_infl .- tray_infl_pob) .^ 2))
    me = mean((tray_infl .- tray_infl_pob))
    @info "Métricas de evaluación:" mse std_mse std_sim_error rmse me

    # Devolver estos valores
    mse_dist, mse, std_mse, std_sim_error, rmse, me
end


# results = evalsim(gtdata_eval, "total", "sbb", 64, 36, Ksim = 10000)

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

# ...

using DataFrames

# Obtener los resultados del directorio de simulaciones 
df = collect_results(savepath)
