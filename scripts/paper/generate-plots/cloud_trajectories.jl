using DrWatson
@quickactivate :HEMI

using DataFrames
using Chain
using PrettyTables
using Plots

## Path 
plots_savepath = mkpath(plotsdir("paper", "clouds"))
csv_output = datadir("results", "paper-assessment", "clouds")

## TIMA settings 

# Resampling technique, parametric inflation formula and trend function 
paramfn = InflationTotalRebaseCPI(60)
resamplefn = ResampleScrambleVarMonths()
trendfn = TrendRandomWalk()

# CPI data
data = GTDATA[Date(2020, 12)]
dates = infl_dates(data)

# Population trend inflation series
param = InflationParameter(paramfn, resamplefn, trendfn)
trend_infl = param(data)

## Load simulated inflation trajectories
savepath = datadir("results", "paper-assessment", "tray_infl")
df_results = collect_results(savepath)

## Load helper functions
include("plot-helpers.jl")

## Plot trajectory cloud

periods = [
    EvalPeriod(Date(2001, 12), Date(2010, 12), "gt_b00"),
    EvalPeriod(Date(2011, 01), Date(2020, 12), "gt_b10"),
    CompletePeriod(),
]

# CPI Headline inflation cloudplots

headline_cpi_traj = get_realizations(df_results, "Total")
headline_cpi_00 = cloudplot(headline_cpi_traj, trend_infl, dates, "Headline CPI inflation", periods[1]; ylims=(-50, 100))
headline_cpi_10 = cloudplot(headline_cpi_traj, trend_infl, dates, "Headline CPI inflation", periods[2]; ylims=(-50, 100))
headline_cpi_0010 = cloudplot(headline_cpi_traj, trend_infl, dates, "Headline CPI inflation", periods[3]; ylims=(-50, 100))

savecloudplot(headline_cpi_00, "Total", periods[1], plots_savepath)
savecloudplot(headline_cpi_10, "Total", periods[2], plots_savepath)
savecloudplot(headline_cpi_0010, "Total", periods[3], plots_savepath)

# Weighted Trimmed-mean inflation measure

wtm2595_traj = get_realizations(df_results, "MTEq-(25.0,95.0)")

wtm2595_00 = cloudplot(wtm2595_traj, trend_infl, dates, "Weighted trimmed-mean (25%,95%)", periods[1])
wtm2595_10 = cloudplot(wtm2595_traj, trend_infl, dates, "Weighted trimmed-mean (25%,95%)", periods[2])
wtm2595_0010 = cloudplot(wtm2595_traj, trend_infl, dates, "Weighted trimmed-mean (25%,95%)", periods[3]; ylims=(0,14))

savecloudplot(wtm2595_00, "WTM2595", periods[1], plots_savepath)
savecloudplot(wtm2595_10, "WTM2595", periods[2], plots_savepath)
savecloudplot(wtm2595_0010, "WTM2595", periods[3], plots_savepath)

## 70th percentile inflation measure

wp70_traj = get_realizations(df_results, "PerW-70.0")
wp70_00 = cloudplot(wp70_traj, trend_infl, dates, "70th Weighted Percentile", periods[1])
wp70_10 = cloudplot(wp70_traj, trend_infl, dates, "70th Weighted Percentile", periods[2])
wp70_0010 = cloudplot(wp70_traj, trend_infl, dates, "70th Weighted Percentile", periods[3])

savecloudplot(wp70_00, "WT70", periods[1], plots_savepath)
savecloudplot(wp70_10, "WT70", periods[2], plots_savepath)
savecloudplot(wp70_0010, "WT70", periods[3], plots_savepath)

## Core CPI (fixed exclusion) inflation measure

fxex_traj = get_realizations(df_results, "FxEx")
fxex_0010 = cloudplot(other_traj, trend_infl, dates, "Other", periods[3]; ylims=(0,14))

## Anonymous plot for presentation
est1_0010 = cloudplot(fxex_traj, trend_infl, dates, "Inflation Estimator 1", periods[3]; ylims=(0,14))
est2_0010 = cloudplot(wp70_traj, trend_infl, dates, "Inflation Estimator 2", periods[3]; ylims=(0,14))
savecloudplot(est1_0010, "InflEst1", periods[3], plots_savepath)
savecloudplot(est2_0010, "InflEst2", periods[3], plots_savepath)

## Export data

exportcloud(headline_cpi_traj, trend_infl, dates, "Total", csv_output)
exportcloud(wp70_traj, trend_infl, dates, "WT70", csv_output)
exportcloud(wtm2595_traj, trend_infl, dates, "WTM2595", csv_output)