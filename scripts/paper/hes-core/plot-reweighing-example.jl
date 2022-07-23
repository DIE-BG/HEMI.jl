using DrWatson 
@quickactivate :HEMI 

using InflationFunctions: ObservationsDistr, WeightsDistr
using StatsBase
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
Vdata = vcat(cpidata00.v[:], cpidata10.v[1:120, :][:])
Wdata = vcat(repeat(cpidata00.w', 120)[:], repeat(cpidata10.w', 120)[:])

## Build the long-term distribution plots 
fL = ObservationsDistr(Vdata, Veps)
gL = WeightsDistr(Vdata, Wdata, Veps)

## Build distribution plots for the selected period in DISTR_DATE
v_month = vec(cpidata10.v[period_mask, :])
w_month = cpidata10.w
ft = ObservationsDistr(v_month, Veps) 
gt = WeightsDistr(v_month, w_month, Veps) 


## Renormalization procedure example

# We renormalize using these quantiles of the monthly price change distribution fₜ

Q_ = [0.20, 0.95]

FL = cumsum(fL)
Ft = cumsum(ft)

# Historical weights for segments
q1, q2 = quantile(v_month, aweights(w_month), Q_)
fleft = FL(q1) / Ft(q1)
fcenter = (FL(q2) - FL(q1)) / (Ft(q2) - Ft(q1))
fright = (1-FL(q2)) / (1-Ft(q2))

@info "Factors:" Q_[1] Q_[2] (q1, q2) fleft fcenter fright

# A trimmed-mean procedure would perform 
# fleft = 0
# fright = 0

# Renormalize weights according to long-run distribution cumulative density
w = copy(w_month)
v = copy(v_month)
w[v .< q1] *= fleft
w[v .>= q1 .&& v .<= q2] *= fcenter
w[v .> q2] *= fright
w = 100 * w / sum(w)

# plot(gt, label="gt")
# vline!([q1, q2], label="Key quantiles", legendposition=:topright)

modgt = WeightsDistr(v_month, w, Veps)
plot!(modgt, label="Modified gt")

Gt = cumsum(gt)
modGt = cumsum(modgt)

# plot(Gt, label="Gt")
# plot!(modGt, label="Gt (mod)")

## Variables needed for plotting
s = q1 .<= sort(v_month) .<= q2
c = [ss ? 1 : 2 for ss in s]
idx = sortperm(v_month)

## Plot original weights and the normalized weights

# Monthly price changes and modified weights
plot( 
    bar(sort(v_month), label="Price changes", linewidth=0), 
    bar(w_month[idx], label="Original weights", linewidth=0), 
    bar(w[idx], label="Modified weights", linewidth=0), 
    layout=(3,1), 
    size=(800,800),
)
vline!([findfirst(s), findlast(s)], label="Key quantiles")


## Weight ratios plot
plot( 
    bar(sort(v_month), label="Price changes", linewidth=0), 
    bar(w[idx] ./ w_month[idx], label="Weight ratios", linewidth=0, legendposition=:bottomright), 
    layout=(2,1), 
    size=(800,800),
)
vline!([findfirst(s), findlast(s)], label="Key quantiles")