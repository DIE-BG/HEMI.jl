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
savepath = datadir("results", "paper-assessment-percentiles")
plots_savepath = mkpath(plotsdir("paper", "percentile"))

unweighted_savepath = datadir(savepath, "unweighted")
weighted_savepath = datadir(savepath, "weighted")

## TIMA settings 

# Resampling technique, parametric inflation formula and trend function 
paramfn = InflationTotalRebaseCPI(36, 2)
resamplefn = ResampleScrambleVarMonths()
trendfn = TrendRandomWalk()

# CPI data
data = GTDATA[Date(2020, 12)]

## Evaluate a range of percentiles

K = 50:80

# Configuration for unweighted percentile-based core measures
assessment_config = dict_list(Dict(
    :inflfn => InflationPercentileEq.(K), 
    :resamplefn => resamplefn, 
    :trendfn => trendfn,
    :paramfn => paramfn, 
    :traindate => Date(2020, 12),
    :nsim => 10_000,
)) 

# Run the simulation
run_batch(data, assessment_config, unweighted_savepath)

# Configuration for weighted percentile-based core measures
assessment_config = dict_list(Dict(
    :inflfn => InflationPercentileWeighted.(K), 
    :resamplefn => resamplefn, 
    :trendfn => trendfn,
    :paramfn => paramfn, 
    :traindate => Date(2020, 12),
    :nsim => 10_000,
)) 

# Run the simulation
run_batch(data, assessment_config, weighted_savepath)


## Plot a MSE curve for unweighted percentile-based core measures
df_results = collect_results(joinpath(unweighted_savepath))

@chain df_results begin
    select(:measure, :mse_bias, :mse_var, :mse_cov, :mse, :mse_std_error)
end

unweighted_mse_curve = df_results.mse

unweighted_p = scatter(K, unweighted_mse_curve, 
    label="MSE of (unweighted) percentile-based core measures",
    xlabel=L"n" * "-th percentile", 
    ylabel="Mean squared error evaluation metric",
    xticks=first(K):5:last(K),
    yticks=0:2:18,
    markersize=6,
    legendfontsize=10,
    labelfontsize=11,
)

savefig(joinpath(plots_savepath, "unweighted_perc_mse_curve.pdf"))


## Plot a MSE curve for unweighted percentile-based core measures
df_results = collect_results(joinpath(weighted_savepath))

@chain df_results begin
    select(:measure, :mse_bias, :mse_var, :mse_cov, :mse, :mse_std_error)
end

weighted_mse_curve = df_results.mse

weighted_p = scatter(K, weighted_mse_curve, 
    label="MSE of weighted percentile-based core measures",
    xlabel=L"n" * "-th percentile", 
    # ylabel="Mean squared error evaluation metric",
    xticks=first(K):5:last(K),
    yticks=0:2:18,
    markersize=6,
    legendfontsize=10,
    labelfontsize=11,
)

savefig(joinpath(plots_savepath, "weighted_perc_mse_curve.pdf"))

## Weighted and unweighted percentile-based core measures

plot(
    unweighted_p, weighted_p, 
    layout=(1,2),
    size=(1000,400),
)

scatter(K, [unweighted_mse_curve, weighted_mse_curve],
    label=["MSE of unweighted percentile-based core measures" "MSE of weighted percentile-based core measures"],
    xlabel=L"n" * "-th percentile of the distribution of monthly price changes", 
    ylabel="Mean squared error evaluation metric",
    xticks=first(K):5:last(K),
    yticks=0:2:18,
    markersize=8,
    size=(800,400),
    legendfontsize=10,
    labelfontsize=11,
    leftmargin=3*Plots.mm,
    bottommargin=3*Plots.mm,
)

savefig(joinpath(plots_savepath, "percentiles_mse_curve.pdf"))