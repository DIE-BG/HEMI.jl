using DrWatson
@quickactivate :HEMI

using DataFrames
using Chain
using Plots

## Load Distributed package to use parallel computing capabilities 
using Distributed
nprocs() < 5 && addprocs(4, exeflags="--project")
@everywhere using HEMI 

## Path 
savepath = datadir("results", "paper-assessment-dynamic-exclusion")
plots_savepath = mkpath(plotsdir("paper", "dynamic-exclusion"))

## TIMA settings 

# Resampling technique, parametric inflation formula and trend function 
paramfn = InflationTotalRebaseCPI(36, 2)
resamplefn = ResampleScrambleVarMonths()
trendfn = TrendRandomWalk()

# CPI data
data = GTDATA[Date(2020, 12)]

## Evaluate a range of factors for the dynamic-exclusion method

# Configuration for the factors of dynamic-exclusion core measure
lower_trims = 0:0.1:2
upper_trims = 0:0.1:2
inflfns = [InflationDynamicExclusion(x, y) for x in lower_trims for y in upper_trims]

assessment_config = dict_list(Dict(
    :inflfn => inflfns, 
    :resamplefn => resamplefn, 
    :trendfn => trendfn,
    :paramfn => paramfn, 
    :traindate => Date(2018, 12),
    :nsim => 10_000,
)) 

# Run the simulation
run_batch(data, assessment_config, savepath; savetrajectories=false)


## Collect results of assessment
df_results = collect_results(joinpath(savepath))

@chain df_results begin
    select(:measure, :mse_bias, :mse_var, :mse_cov, :mse, :mse_std_error)
end


## Create a heatmap of the MSE metric with the results 

factors_mse_map = @chain df_results begin
    select(
        :params => ByRow(t -> t[1]) => :p1,
        :params => ByRow(t -> t[2]) => :p2,
        :mse => ByRow(m -> isnan(m) ? missing : m) => :mse,
    )
    sort([:p1, :p2])
end

# Invert and reshape values for the heatmap
mse_vals = 1 ./ reshape(factors_mse_map.mse, length(upper_trims), length(lower_trims))

heatmap(lower_trims, upper_trims, mse_vals,
    colorbar_title="Reciprocal MSE metric", 
    xlabel="Left-trim factor " * L"\lambda_{1}",
    ylabel="Right-trim factor " * L"\lambda_{2}",
    # color = reverse(cgrad(:viridis)),
    color = :viridis,
    # aspectratio=:equal,
    size=(800,400),
    legendfontsize=10,
    labelfontsize=11,
    leftmargin=4*Plots.mm,
    bottommargin=3*Plots.mm,
)

i_min = argmin(skipmissing(factors_mse_map.mse))
scatter!([factors_mse_map.p1[i_min]], [factors_mse_map.p2[i_min]],
    label="MSE minimizer factors",
    color=:red, 
)

savefig(joinpath(plots_savepath, "dynamic_exclusion_mse_map.pdf"))


