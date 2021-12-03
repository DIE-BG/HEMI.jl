

## Graficar el mejor escenario en test 
function plot_trajectories(results, savepath="", filename=""; 
    extension=(Plots.backend_name() == :gr ? "svg" : "html"))

    # Ordenar resultados por test
    sorted_results = DataFrames.sort(results, :test)

    dates = Date(2001, 12):Year(1):Date(2020, 12)

    p = plot(InflationTotalCPI(), gtdata, alpha = 0.7,
        xticks = (dates, Dates.format.(dates, dateformat"u-yy")),
        xrotation = 45
    )
    plot!(p, optmse2019, gtdata, linewidth = 2, color = :black)
    
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
    hline!(p, [3], alpha=0.5, color = :gray, label=false)

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

# Ajusta ponderaciones en la base 2010 (hasta diciembre de 2020) y obtiene las
# métricas a partir del período especificado a partir de eval_date_start,
# utilizando las trayectorias de inflación en testdata. Las trayectorias son
# generadas con el ensemble de testconfig 
function get_metrics_2020(results::DataFrame, testconfig, testdata; 
    eval_date_start = Date(2001,12), weights_date_start = Date(2011, 12), metricskwargs...)
    
    # Trayectorias y parámetro de evaluación 
    tray_infl = testdata["infl_20"]
    tray_param = testdata["param_20"]
    dates = testdata["dates_20"]

    # Filtro de fechas para evaluación 
    evalmask = dates .>= eval_date_start
    # Filtro de fechas para ajuste de ponderadores 
    weightsmask = dates .>= weights_date_start
    
    # Funciones de inflación en la configuración 
    datafns = [testconfig.inflfn.functions...]

    # Obtener DataFrame de métricas para cada fila 
    result_metrics = mapreduce(vcat, eachrow(results)) do r
        @info "Métricas de evaluación" r
        inflfn = r.combfn
        w = inflfn.weights
        combfns = [inflfn.ensemble.functions...]

        # Obtener de las trayectorias en testdata, las mismas funciones de
        # inflación que las obtenidas en la función de combinación presente en
        # los resultados
        @debug "Medidas de la óptima" wdf=DataFrame(measure = measure_name.(combfns), weight = w)

        hasconst = any(fn isa InflationConstant for fn in combfns)
        hasfx = any(fn isa InflationFixedExclusionCPI for fn in combfns)

        if hasfx 
            mask = [true for _ in datafns]
        else
            mask = [!(fn isa InflationFixedExclusionCPI) for fn in datafns]
        end

        if hasconst
            tray_infl_final = @views add_ones(tray_infl[:, mask, :])
            finalfns = [InflationConstant(); datafns[mask]]
        else
            tray_infl_final = tray_infl[:, mask, :]
            finalfns = datafns[mask]
        end

        @debug "Funciones" datafns combfns finalfns 
        @assert all(measure_name.(finalfns) .== measure_name.(combfns))
        
        # Ajustar las ponderaciones utilizando las trayectorias hasta el período
        # especificado en weights_date_start
        if r.method == "ls"
            weightsfunction = combination_weights
        elseif r.method == "ridge"
            @info "Lambda en combinación Ridge" r.lambda
            weightsfunction = (t, p) -> ridge_combination_weights(t, p, r.lambda)
        elseif r.method == "share"
            weightsfunction = share_combination_weights
        else 
            @error "Función de combinación no encontrada"
        end

        # Obtener ponderadores óptimos
        wopt = @views weightsfunction(tray_infl_final[weightsmask, :, :], tray_param[weightsmask])
        @debug "Ponderaciones con weightsmask" wdf=DataFrame(measure = measure_name.(combfns), weight = wopt)

        # Obtener la función de combinación 
        combfn = InflationCombination(
            inflfn.ensemble, 
            wopt, 
            measure_name(inflfn)
        )

        # Obtener métricas en el período seleccionado con eval_date_start
        metrics = @views DataFrame(
            combination_metrics(tray_infl_final[evalmask, :, :], tray_param[evalmask], wopt; metricskwargs...))
        metrics[!, :method] .= r.method
        metrics[!, :scenario] .= r.scenario 
        metrics[!, :inflfn20] .= combfn
        metrics
    end

    result_metrics
end


function plot_trajectories_2020(results, savepath="", filename=""; 
    extension=(Plots.backend_name() == :gr ? "svg" : "html"))

    # Ordenar resultados por escenario (E de último)
    sorted_results = DataFrames.sort(results, :scenario)

    dates = Date(2001, 12):Year(1):Date(2020, 12)

    p = plot(InflationTotalCPI(), gtdata, alpha = 0.7,
        xticks = (dates, Dates.format.(dates, dateformat"u-yy")),
        xrotation = 45
    )
    plot!(p, optmse2019, gtdata, linewidth = 2, color = :black)
    
    for r in eachrow(sorted_results)
        if r.scenario == "E"
            # Estilo para escenario E
            plot!(p, r.inflfn20, gtdata, linewidth=2, color=:blue)
        elseif r.scenario == "C" || r.scenario == "D"
            plot!(p, r.inflfn20, gtdata, alpha=0.7, ls=:dash)
        elseif r.scenario == "B"
            plot!(p, r.inflfn20, gtdata, linewidth=1.5, color=:red)
        else
            # Estilo de las trayectorias resultantes
            plot!(p, r.inflfn20, gtdata)
        end
    end
    hline!(p, [3], alpha=0.5, color = :gray, label=false)

    # Guardar la gráfica 
    if savepath != "" && filename != "" 
        savefig(p, joinpath(savepath, filename*"."*extension))
    end

    p
end


# Función para obtener componentes y ponderaciones de combinaciones lineales
# ajustadas hasta diciembre de 2020. Esta función toma el DataFrame de metrics
# (en donde se guarda la función en inflfn20) y obtiene las componentes y
# ponderaciones del escenario indicado
function get_components_2020(metricsdf, method, scenario)
    result = filter(r -> r.method == method && r.scenario == scenario, metricsdf)
    inflfn = result.inflfn20[1]

    inflfn, components(inflfn)
end