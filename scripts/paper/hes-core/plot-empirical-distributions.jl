using DrWatson 
@quickactivate :HEMI 

using InflationFunctions: ObservationsDistr, WeightsDistr
using Plots
using LaTeXStrings
using Printf

## Output folder 
plots_savepath = mkpath(plotsdir("paper", "hes-note"))

## Sample consumer-price data used
FINAL_DATE = Date(2020, 12)
cpidata = GTDATA[FINAL_DATE]

# Date mask used for the fₜ and gₜ distributions plot from the CPI 2010 dataset
DISTR_DATE = Date(2020, 12)
cpidata00 = cpidata[1]
cpidata10 = cpidata[2]
period_mask = cpidata10.dates .== DISTR_DATE

## Get the Vε space 
Veps = InflationFunctions.V

## Get the historical monthly price changes
periods00 = length(cpidata00.dates)
periods10 = length(cpidata10.dates)
Vdata = vcat(cpidata00.v[:], cpidata10.v[1:periods10, :][:])
Wdata = vcat(repeat(cpidata00.w', periods00)[:], repeat(cpidata10.w', periods10)[:])

## Build the long-term distribution plots 
fL = ObservationsDistr(Vdata, Veps)
gL = WeightsDistr(Vdata, Wdata, Veps)

## Build distribution plots for the selected period in DISTR_DATE
v_month = vec(cpidata10.v[period_mask, :])
w_month = cpidata10.w
ft = ObservationsDistr(v_month, Veps) 
gt = WeightsDistr(v_month, w_month, Veps) 


## Plot long-term distributions
fL_plot = plot(fL, 
    seriestype=:bar,
    label=L"f_{L}",
    linealpha=0,
    legendposition=:topright, 
)

gL_plot = plot(gL, 
    seriestype=:bar,
    label=L"g_{L}",
    linealpha=0,
    legendposition=:topright, 
)

## Plot distributions fₜ and gₜ for DISTR_DATE

ft_plot = plot(ft, 
    seriestype=:bar,
    label=L"f_{t}",
    linealpha=0,
    legendposition=:topright, 
)

gt_plot = plot(gt, 
    seriestype=:bar,
    label=L"g_{t}",
    linealpha=0,
    legendposition=:topright, 
)

## Cumulative distribution plots

FL_plot = plot(cumsum(fL), 
    label=L"F_{L}",
    linewidth=2,
    legendposition=:bottomright, 
    ylabel="Cumulative density",
    xlabel="Monthly price changes", 
)
plot!(FL_plot, cumsum(ft), label=L"F_{t}", linewidth=2)

GL_plot = plot(cumsum(gL), 
    label=L"G_{L}",
    linewidth=2,
    legendposition=:bottomright, 
)
plot!(GL_plot, cumsum(gt), label=L"G_{t}", linewidth=2)


## Create a combined plot of weighted and unweighted distributions

# Settings to armonize plots
xlims_f = (-2, 2)
ylims_f = (0, 0.14)
yticks_f = (0:0.02:0.14, Printf.format.(Ref(Printf.Format("%0.0f")), (0:0.02:0.14) .* 100))
yticks_cum = (0:0.2:1, Printf.format.(Ref(Printf.Format("%0.0f")), (0:0.2:1) .* 100)) 

unweighted_p = plot(ft_plot, fL_plot, FL_plot,
    layout=(@layout [grid(1,2); a{0.5h}]),
    size=(800,500), 
    ylabel="% of distribution",
    xlabel="Monthly price changes", 
    ylims=[ylims_f ylims_f (0,1)],
    xlims=[xlims_f xlims_f (-5,5)],
    yticks=[yticks_f yticks_f yticks_cum],
    titlefontsize=11,
    legendfontsize=9,
    xlabelfontsize=8,
    ylabelfontsize=8,
    leftmargin=2Plots.mm, 
)

weighted_p = plot(gt_plot, gL_plot, GL_plot, 
    layout=(@layout [grid(1,2); a{0.5h}]),
    size=(800,500), 
    ylabel="% of distribution",
    xlabel="Monthly price changes", 
    ylims=[ylims_f ylims_f (0,1)],
    xlims=[xlims_f xlims_f (-5,5)],
    yticks=[yticks_f yticks_f yticks_cum],
    titlefontsize=11,
    legendfontsize=9,
    xlabelfontsize=8,
    ylabelfontsize=8,
    leftmargin=2Plots.mm, 
)

savefig(unweighted_p, joinpath(plots_savepath, "unweighted_distr.pdf"))
savefig(weighted_p, joinpath(plots_savepath, "weighted_distr.pdf"))


## Comparison between fL and gL 

FLGL_plot = plot(cumsum(fL),
    label=L"F_{L}",
    linewidth=2,
    legendposition=:bottomright, 
)
plot!(FLGL_plot, cumsum(gL), 
    label=L"G_{L}",
    linewidth=2,
)

comp_FLGL_p = plot(fL_plot, gL_plot, FLGL_plot,
    layout=(@layout [grid(1,2); a{0.5h}]),
    size=(800,500), 
    ylabel="% of distribution",
    xlabel="Monthly price changes", 
    ylims=[ylims_f ylims_f (0,1)],
    xlims=[xlims_f xlims_f (-2.5, 2.5)],
    yticks=[yticks_f yticks_f yticks_cum],
    titlefontsize=11,
    legendfontsize=9,
    xlabelfontsize=8,
    ylabelfontsize=8,
    leftmargin=2Plots.mm, 
)

savefig(comp_FLGL_p, joinpath(plots_savepath, "longterm_distr.pdf"))
