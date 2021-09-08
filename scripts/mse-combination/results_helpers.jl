## Graficar el mejor escenario en test 
function plot_trajectories(results, savepath="", filename="")

    # Ordenar resultados por test
    sorted_results = sort(results, :test)
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
    sorted_results = sort(results, :test)
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