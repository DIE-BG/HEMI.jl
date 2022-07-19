using DrWatson
@quickactivate :HEMI

using DataFrames
using Chain
using PrettyTables
using CSV
using Plots

## Load Distributed package to use parallel computing capabilities 
using Distributed
nprocs() < 5 && addprocs(4, exeflags="--project")
@everywhere using HEMI 

## Path 
plots_savepath = mkpath(plotsdir("paper", "percentile-plots"))

## TIMA settings 

# Here we use synthetic base changes every 36 months, because this is the population trend 
# inflation time series used in the optimization of the Optimal Linear MSE Combination 2022

# Resampling technique, parametric inflation formula and trend function 
paramfn = InflationTotalRebaseCPI(36, 2)
resamplefn = ResampleScrambleVarMonths()
trendfn = TrendRandomWalk()

# CPI data
data = GTDATA[Date(2020, 12)]
dates = infl_dates(data)
date_ticks = first(dates):Month(24):last(dates)
date_str = Dates.format.(date_ticks, dateformat"Y-m")

# Population trend inflation series
param = InflationParameter(paramfn, resamplefn, trendfn)
trend_infl = param(data)


## Function to evaluate a range of percentiles

K = 50:80
perkfn = InflationPercentileEq

function percentile_curve(perkfn, k_range, resamplefn, trendfn, csdata, trend_infl, B)
    percentile_mse_vals = map(k_range) do k 
        inflfn = perkfn(k)
        mse = eval_mse_online(
            inflfn,     # The percentile inflation function 
            resamplefn, # The resample function  
            trendfn,    # The artificial trend function 
            csdata,     # The CountryStructure object with the CPI data
            trend_infl; # The population trend time series 
            K=B,        # The number of simulations  
        )
        return mse
    end
    return percentile_mse_vals
end

unweighted_curve = percentile_curve(
    InflationPercentileEq, 
    K, 
    resamplefn, 
    trendfn, 
    data, 
    trend_infl, 
    10_000,
)

scatter(K, unweighted_curve, 
    label="MSE of (unweighted) percentile-based core measures",
    xlabel="n-th percentile", 
    xticks=first(K):5:last(K),
    markersize=6,
)
