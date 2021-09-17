## Graficar el mejor escenario en test 
function plot_trajectories(results, savepath="", filename=""; 
    extension=(Plots.backend_name() == :gr ? "svg" : "html"))

    # Ordenar resultados por test
    sorted_results = DataFrames.sort(results, :test)
    p = plot(InflationTotalCPI(), gtdata, alpha=0.5)
    f = true
    for r in eachrow(sorted_results)
        if f 
            # Estilo para la primera grafica, con MSE en test mas pequeño
            plot!(p, r.combfn, gtdata, linewidth=2, color=:blue)
            f = false 
        else
            # Estilo de las trayectorias resultantes
            plot!(p, r.combfn, gtdata, alpha=0.7)
        end
    end

    # Guardar la gráfica 
    if savepath != "" && filename != "" 
        savefig(p, joinpath(savepath, filename*"."*extension))
    end

    p
end

# Obtener ingredientes y ponderadores de la mejor medida 
function get_components(results::DataFrame, position::Int=1)
    sorted_results = DataFrames.sort(results, :test)
    bestfn = sorted_results.combfn[position]
    components = DataFrame(
        measure = measure_name(bestfn.ensemble), 
        weights = bestfn.weights
    )

    components
end

# Obtener ingredientes del escenario 
function get_components(results::DataFrame, scenario::String)
    fres = filter(r -> r.scenario == scenario, results)
    bestfn = fres.combfn[1]
    components = DataFrame(
        measure = measure_name(bestfn.ensemble), 
        weights = bestfn.weights
    )

    components
end

# Obtiene las métricas de evaluación en el período especificado a partir de
# date_start, utilizando las trayectorias de inflación en testdata. Las
# trayectorias son generadas con el ensemble de testconfig 
function get_metrics(results::DataFrame, testconfig, testdata; 
    date_start = Date(2001,12), metricskwargs...)
    
    # Trayectorias y parámetro de evaluación 
    tray_infl = testdata["infl_20"]
    tray_param = testdata["param_20"]
    dates = testdata["dates_20"]

    # Filtro de fechas para evaluación 
    datemask = dates .>= date_start
    # Funciones de inflación en la configuración 
    datafns = [testconfig.inflfn.functions...]

    # Obtener DataFrame de métricas para cada fila 
    result_metrics = mapreduce(vcat, eachrow(results)) do r
        @info "Métricas de evaluación" r
        inflfn = r.combfn
        w = inflfn.weights
        combfns = [inflfn.ensemble.functions...]

        @debug "Medidas de la óptima" wdf=DataFrame(measure = measure_name.(combfns), weight = w)

        hasconst = any(fn isa InflationConstant for fn in combfns)
        hasfx = any(fn isa InflationFixedExclusionCPI for fn in combfns)

        if hasfx 
            mask = [true for _ in datafns]
        else
            mask = [!(fn isa InflationFixedExclusionCPI) for fn in datafns]
        end

        if hasconst
            tray_infl_final = @views add_ones(tray_infl[datemask, mask, :])
            finalfns = [InflationConstant(); datafns[mask]]
        else
            tray_infl_final = tray_infl[datemask, mask, :]
            finalfns = datafns[mask]
        end

        @debug "Funciones" datafns combfns finalfns 
        @assert all(measure_name.(finalfns) .== measure_name.(combfns))
        
        metrics = DataFrame(combination_metrics(tray_infl_final, tray_param[datemask], w; metricskwargs...))
        metrics[!, :method] .= r.method
        metrics[!, :scenario] .= r.scenario 
        metrics
    end

    result_metrics
end