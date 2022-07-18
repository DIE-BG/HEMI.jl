using DrWatson
@quickactivate :HEMI

using DataFrames
using Chain
using Plots
using LaTeXStrings

## Load Distributed package to use parallel computing capabilities 
using Distributed
nprocs() < 5 && addprocs(4, exeflags="--project")
@everywhere using HEMI 

## Path 
savepath = datadir("results", "paper-assessment-trimmed-means")
plots_savepath = mkpath(plotsdir("paper", "trimmed-means"))

unweighted_savepath = datadir(savepath, "unweighted")
weighted_savepath = datadir(savepath, "weighted")

## TIMA settings 

# Resampling technique, parametric inflation formula and trend function 
paramfn = InflationTotalRebaseCPI(36, 2)
resamplefn = ResampleScrambleVarMonths()
trendfn = TrendRandomWalk()

# CPI data
data = GTDATA[Date(2020, 12)]

## Evaluate a range of trimmed-means

# Configuration for unweighted trimmed-mean core measures
ulower_trims = 10:60
uupper_trims = 80:100
unweighted_fns = [InflationTrimmedMeanEq(x, y) for x in ulower_trims for y in uupper_trims]

assessment_config = dict_list(Dict(
    :inflfn => unweighted_fns, 
    :resamplefn => resamplefn, 
    :trendfn => trendfn,
    :paramfn => paramfn, 
    :traindate => Date(2018, 12),
    :nsim => 10_000,
)) 

# Run the simulation
run_batch(data, assessment_config, unweighted_savepath; savetrajectories=false)

# Configuration for weighted percentile-based core measures
wlower_trims = 0:40
wupper_trims = 80:100
weighted_fns = [InflationTrimmedMeanWeighted(x, y) for x in wlower_trims for y in wupper_trims]

assessment_config = dict_list(Dict(
    :inflfn => weighted_fns, 
    :resamplefn => resamplefn, 
    :trendfn => trendfn,
    :paramfn => paramfn, 
    :traindate => Date(2018, 12),
    :nsim => 10_000,
)) 

# Run the simulation
run_batch(data, assessment_config, weighted_savepath; savetrajectories=false)


## Collect unweighted results of assessment
df_results = collect_results(joinpath(unweighted_savepath))

@chain df_results begin
    select(:measure, :mse_bias, :mse_var, :mse_cov, :mse, :mse_std_error)
end


## Create a heatmap of the unweighted MSE metric with the results 

unweighted_mse_map = @chain df_results begin
    select(
        :params => ByRow(t -> t[1]) => :p1,
        :params => ByRow(t -> t[2]) => :p2,
        :mse
    )
    sort([:p1, :p2])
end

# Invert and reshape values for the heatmap
mse_vals = 1 ./ reshape(unweighted_mse_map.mse, length(uupper_trims), length(ulower_trims))

unweighted_p = heatmap(ulower_trims, uupper_trims, mse_vals,
    colorbar_title="Reciprocal MSE metric", 
    xlabel="Left-trim percentile " * L"p_1",
    ylabel="Right-trim percentile " * L"p_2",
    # color = reverse(cgrad(:viridis)),
    color = :viridis,
    # aspectratio=:equal,
    size=(800,400),
    legendfontsize=10,
    labelfontsize=11,
    leftmargin=4*Plots.mm,
    bottommargin=3*Plots.mm,
)

i_min = argmin(unweighted_mse_map.mse)
scatter!(unweighted_p, [unweighted_mse_map.p1[i_min]], [unweighted_mse_map.p2[i_min]],
    label="MSE minimizer trims",
    color=:red, 
)

savefig(joinpath(plots_savepath, "unweighted_trimmed_means_mse_map.pdf"))



## Collect weighted results of assessment
df_results = collect_results(joinpath(weighted_savepath))

@chain df_results begin
    select(:measure, :mse_bias, :mse_var, :mse_cov, :mse, :mse_std_error)
end


## Create a heatmap of the weighted MSE metric with the results 

weighted_mse_map = @chain df_results begin
    select(
        :params => ByRow(t -> t[1]) => :p1,
        :params => ByRow(t -> t[2]) => :p2,
        :mse
    )
    sort([:p1, :p2])
end

# Invert and reshape values for the heatmap
mse_vals = 1 ./ reshape(weighted_mse_map.mse, length(wupper_trims), length(wlower_trims))

weighted_p = heatmap(wlower_trims, wupper_trims, mse_vals,
    colorbar_title="Reciprocal MSE metric", 
    xlabel="Left-trim weighted percentile " * L"p_1",
    ylabel="Right-trim weighted percentile " * L"p_2",
    # color = reverse(cgrad(:viridis)),
    color = :viridis,
    # aspectratio=:equal,
    size=(800,400),
    legendfontsize=10,
    labelfontsize=11,
    leftmargin=4*Plots.mm,
    bottommargin=3*Plots.mm,
)

i_min = argmin(weighted_mse_map.mse)
scatter!(weighted_p, [weighted_mse_map.p1[i_min]], [weighted_mse_map.p2[i_min]],
    label="MSE minimizer trims",
    color=:red, 
)

savefig(joinpath(plots_savepath, "weighted_trimmed_means_mse_map.pdf"))


## Create a plot of both MSE heatmaps

plot(
    unweighted_p, 
    weighted_p, 
    size=(800, 600),
    layout=(2,1),
    title=["Unweighted trimmed-means" "Weighted trimmed-means"], 
    legendposition=:bottomleft,
    titlefontsize=11,
    xlabelfontsize=10,
    ylabelfontsize=10,
)

savefig(joinpath(plots_savepath, "trimmed_means_mse_map.pdf"))