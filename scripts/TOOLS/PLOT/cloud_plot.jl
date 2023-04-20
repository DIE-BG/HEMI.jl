using Plots
using StatsBase

function cloud_plot(
    tray_infl::Array{Float32, 3},
    tray_infl_pob, 
    gtdata_eval = nothing; 
    savename = nothing,
    title = ["" for x in 1:size(tray_infl)[2]],
    sample_size = 500,
    plot_size = (900,600),
    ylims = (0.0, 14.0),
    show_median = false,
    show_percentiles = false,
    cmu_font = false,
    show_legend = true
    )

    for i in 1:size(tray_infl)[2]
        TITLE = title[i] #titulo

        PARAM = tray_infl_pob #parametro

        X = isnothing(gtdata_eval) ? nothing : infl_dates(gtdata_eval) # eje X

        TRAYS = tray_infl[:,i,:]

        TRAY_INFL = [ TRAYS[:,i] for i in 1:size(TRAYS)[2]] # vector de vectores
        TRAY_VEC = sample(TRAY_INFL, sample_size) # muestra 
        TRAY_PROM = mean(TRAYS,dims=2)[:,1] # promedio de trayectorias

        show_median ? TRAY_MED = median(TRAYS,dims=2)[:,1] : nothing
        show_percentiles ? TRAY_25 = [percentile(x[:],25) for x in eachslice(TRAYS,dims=1)] : nothing
        show_percentiles ? TRAY_75 = [percentile(x[:],75) for x in eachslice(TRAYS,dims=1)] : nothing

        cmu_font ? font_family = "Computer Modern" : font_family = "sans-serif"
        
        #GRAFICAMOS
        p=plot(
            X,
            TRAY_VEC;
            legend = true,
            label = false,
            c="grey12",
            linewidth = 0.125,
            title = TITLE,
            size = plot_size,
            ylims = ylims,
            fontfamily = font_family
        )

        p=plot!(
            X,PARAM;
            legend = true,
            label= show_legend ? "Parámetro" : nothing,
            c="blue3",
            linewidth = 3.5
        )

        p=plot!(
            X,TRAY_PROM;
            legend = true,
            label= show_legend ? "Promedio" : nothing,
            c="red",
            linewidth = 3.5
        )

        if show_median
            p=plot!(
                X,TRAY_MED;
                legend = true,
                label= show_legend ? "Mediana" : nothing,
                c="green",
                linewidth = 2.0
            )
        end

        if show_percentiles
            p=plot!(
                X,TRAY_25;
                legend = true,
                label = show_legend ? "Percentil 25" : nothing,
                c="green",
                linewidth = 2.0,
                linestyle=:dash
            )

            p=plot!(
                X,TRAY_75;
                legend = true,
                label = show_legend ? "Percentil 75" : nothing,
                c="green",
                linewidth = 2.0,
                linestyle=:dash
            )
        end
        display(p)
        if !isnothing(savename)
            savefig(savename[i])
        end
    end

end

#En el caso que solo sea un set de trayectorias para una sola medida en forma de matriz
function cloud_plot(
    tray_infl::Array{Float32, 2},
    tray_infl_pob, 
    gtdata_eval = nothing; 
    savename = nothing,
    title = [""],
    sample_size = 500,
    plot_size = (900,600),
    ylims = (0.0, 14.0),
    show_median = false,
    show_percentiles = false,
    cmu_font = false,
    show_legend = true
    )

    # Para ajustar las dimensiones del array 
    array_dims = size(tray_infl)
    tray_infl = reshape(tray_infl, (array_dims[1], 1, array_dims[2]))
    cloud_plot(
        tray_infl::Array{Float32, 3}, tray_infl_pob, gtdata_eval; savename=[savename], title = [title], sample_size, plot_size, ylims,
        show_median, show_percentiles, cmu_font, show_legend
    )
end