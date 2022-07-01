using DrWatson
@quickactivate :HEMI

using DataFrames
using Chain
using Plots
using LaTeXStrings

## Load Distributed package to use parallel computing capabilities 
using Distributed
nprocs() < 5 && addprocs(4; exeflags="--project")
@everywhere using HEMI

## Path 
savepath = datadir("results", "paper-assessment-fixed-exclusion")
plots_savepath = mkpath(plotsdir("paper", "fixed-exclusion"))

savepath_b00 = datadir(savepath, "b00")
savepath_b10 = datadir(savepath, "b10")

## TIMA settings 

# Resampling technique, parametric inflation formula and trend function 
paramfn = InflationTotalRebaseCPI(36, 2)
resamplefn = ResampleScrambleVarMonths()
trendfn = TrendRandomWalk()

# CPI data
data = GTDATA[Date(2020, 12)]
traindate = Date(2018, 12)

## Evaluate a range of excluded items for the CPI 2000 dataset

volatility_00 = @chain data begin
    getindex(1)         # Get the CPI 2000 dataset monthly price changes
    getproperty(:v)
    capitalize          # Recompute the price indexes
    varinteran          # Compute 12-month price changes
    std(; dims=1)        # Compute standard deviation of each series
    vec
end

# Sort CPI items by their volatility
volatility_df = DataFrame(; i=1:length(volatility_00), volatility=volatility_00)
sort!(volatility_df, :volatility; rev=true)

# Evaluate the first 100 sets of exclusion sets
idxsbyvol_00 = volatility_df.i
exc_00_specs = [idxsbyvol_00[1:i] for i in 1:100]
inflfns_00 = InflationFixedExclusionCPI.(exc_00_specs)

assessment_config = dict_list(
    Dict(
        :inflfn => inflfns_00,
        :resamplefn => resamplefn,
        :trendfn => trendfn,
        :paramfn => paramfn,
        :traindate => Date(2018, 12),
        :nsim => 10_000,
        :evalperiods => EvalPeriod(Date(2001, 12), Date(2010, 12), "gt_b00"),
    ),
)

# Run the simulation
data_00 = UniformCountryStructure(data[1])
run_batch(data_00, assessment_config, savepath_b00; savetrajectories=false)

# Get the exclusion set that minimizes the MSE
results_00 = collect_results(savepath_b00)
sort!(results_00, :gt_b00_mse)

# Optimal exclusion vector for the CPI 2000 dataset
opt_exc_specs_00 = results_00.params[1][1]

## Evaluate a range of excluded items for the CPI 2010 dataset

volatility_10 = @chain data begin
    getindex(traindate) # Use data only to the training period of Dec-18
    getindex(2)         # Get the CPI 2000 dataset monthly price changes
    getproperty(:v)
    capitalize          # Recompute the price indexes
    varinteran          # Compute 12-month price changes
    std(; dims=1)       # Compute standard deviation of each series
    vec
end

# Sort CPI items by their volatility
volatility_df = DataFrame(; i=1:length(volatility_10), volatility=volatility_10)
sort!(volatility_df, :volatility; rev=true)

# Evaluate the first 100 sets of exclusion sets
idxsbyvol_10 = volatility_df.i
exc_10_specs = [idxsbyvol_10[1:i] for i in 1:100]
inflfns_10 = InflationFixedExclusionCPI.(Ref(opt_exc_specs_00), exc_10_specs)

assessment_config = dict_list(
    Dict(
        :inflfn => inflfns_10,
        :resamplefn => resamplefn,
        :trendfn => trendfn,
        :paramfn => paramfn,
        :traindate => Date(2018, 12),
        :nsim => 10_000,
        :evalperiods => EvalPeriod(Date(2011, 12), traindate, "gt_b10_opt"),
    ),
)

# Run the simulation
# run_batch(data, assessment_config, savepath_b10; savetrajectories=false)

# Get the exclusion set that minimizes the MSE
results_10 = collect_results(savepath_b10)
sort!(results_10, :gt_b10_opt_mse)

# Optimal exclusion vector for the CPI 2000 dataset
opt_exc_specs_10 = results_10.params[1][1]

## Plot optimal fixed-exclusion core inflation measure

optfxfn = InflationFixedExclusionCPI(opt_exc_specs_00, opt_exc_specs_10)
plot(InflationTotalCPI(), data)
plot!(optfxfn, data)

## Plot volatility and MSE bars in CPI 2000 and 2010 datasets

# Maximum number of exclusions for the plots
MAXN = 100

# Color for the optimal bar 
colors_b00 = [i == length(opt_exc_specs_00) ? :red : 1 for i in 1:MAXN]
colors_b10 = [i == length(opt_exc_specs_10) ? :red : 1 for i in 1:MAXN]

# CPI 2000 plots
p_num_b00 = bar(
    sort(volatility_00; rev=true)[1:MAXN];
    label="Volatility of item in the CPI 2000 dataset",
    # xlabel="Number of excluded CPI items",
    ylabel="Standard deviation",
    ylims=(0,45),
    linealpha=0,
    color=colors_b00,
)

annotate!([(14, 18, (L"14", 8, :bottom))])

# Compute MSE from evaluation results
b00_mse = @chain results_00 begin
    select(:params => ByRow(length ∘ first) => :num_exclusions, :gt_b00_mse)
    sort(:num_exclusions)
    getproperty(:gt_b00_mse)
end

p_mse_b00 = bar(
    b00_mse[1:MAXN];
    linealpha=0,
    ylims=(0,10),
    # label="MSE of fixed-exclusion core measures",
    label="MSE (Dec-01 to Dec-10)",
    xlabel="Number of excluded CPI items",
    ylabel="Mean squared error metric",
    color=colors_b00,
)

annotate!([(2, 10, (L"\uparrow 122.09", 8, :left)), (14, 1, (L"14", 8, :bottom))])

# CPI 2010 plots
p_num_b10 = bar(
    sort(volatility_10; rev=true)[1:MAXN];
    label="Volatility of item in the CPI 2010 dataset",
    # xlabel="Number of excluded CPI items",
    # ylabel="Standard deviation",
    ylims=(0,45),
    linealpha=0,
    color=colors_b10,
)

annotate!([(14, 15, (L"14", 8, :bottom))])

# Compute MSE from evaluation results
b10_mse = @chain results_10 begin
    select(:params => ByRow(length ∘ (t -> t[2])) => :num_exclusions, :gt_b10_opt_mse)
    sort(:num_exclusions)
    getproperty(:gt_b10_opt_mse)
end

p_mse_b10 = bar(
    b10_mse[1:MAXN];
    ylims=(0,10),
    label="MSE (Dec-11 to Dec-18)",
    xlabel="Number of excluded CPI items",
    # ylabel="Mean squared error metric",
    linealpha=0,
    color=colors_b10,
)

annotate!([(14, 1, (L"14", 8, :bottom))])

# Combine plot with results from both CPI datasets
plot(
    p_num_b00,
    p_num_b10,
    p_mse_b00,
    p_mse_b10;
    layout=(2, 2),
    size=(800, 500),
    legendfontsize=8,
    labelfontsize=9,
    leftmargin=4 * Plots.mm,
    bottommargin=3 * Plots.mm,
)

savefig(joinpath(plots_savepath, "fixed_exclusion_mse_bars.pdf"))