## Graficar el mejor escenario en test 
function plot_trajectories(results, savepath="", filename="")

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
        savefig(p, joinpath(savepath, filename))
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


function get_metrics(results::DataFrame, testconfig, testdata; 
    date_start = Date(2001,12), metricskwargs...)
    
    # Ordenar resultados y obtener la mejor medida en el test 
    sorted_results = DataFrames.sort(results, :test)
    @info "DataFrame de resultados: " sorted_results
    
    # Trayectorias y parámetro de evaluación 
    tray_infl = testdata["infl_20"]
    tray_param = testdata["param_20"]
    dates = testdata["dates_20"]

    # Filtro de fechas para evaluación 
    datemask = dates .>= date_start

    inflfn = sorted_results.combfn[1]
    w = inflfn.weights
    combfns = [inflfn.ensemble.functions...]

    @info "Medidas de la óptima" wdf=DataFrame(measure = measure_name.(combfns), weight = w)

    hasconst = any(fn isa InflationConstant for fn in combfns)
    hasfx = any(fn isa InflationFixedExclusionCPI for fn in combfns)

    datafns = [testconfig.inflfn.functions...]
    
    if hasfx 
        mask = (:)
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
    
    combination_metrics(tray_infl_final, tray_param[datemask], w; metricskwargs...)
end