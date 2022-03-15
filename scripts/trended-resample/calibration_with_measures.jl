using DrWatson
@quickactivate :HEMI 
using StatsBase
using CSV
using DataFrames
using Plots
using ProgressMeter
using Optim

## Parallel workders
using Distributed
nprocs() < 5 && addprocs(4, exeflags="--project")
@everywhere using HEMI 

## Configuration of period to calibrate
# Change between :b00, :b10 and :b0010
PERIOD = :b0010
USE_OPTIMALS = false
const PARAM_INFLFN = InflationTotalCPI() 

# Calibration data used 
period1 = EvalPeriod(Date(2001,1), Date(2005,12), "b00_5y")
period2 = EvalPeriod(Date(2011,12), Date(2015,12), "b10_5y")

if PERIOD == :b00 
    evaldata = UniformCountryStructure(GTDATA[1]) # CPI 2000 base 
    mask1 = eval_periods(evaldata, period1)
    evalmask = mask1
elseif PERIOD == :b10 
    evaldata = UniformCountryStructure(GTDATA[2]) # CPI 2010 base 
    mask2 = eval_periods(evaldata, period2)
    evalmask = mask2
else
    # All available data 
    evaldata = GTDATA[Date(2021,12)]
    mask1 = eval_periods(evaldata, period1)
    mask2 = eval_periods(evaldata, period2)
    evalmask = mask1 .| mask2 
end

# Plots folder
plots_path = mkpath(plotsdir("trended-resample", "total-cpi-calibration", 
    "historical-calibration",
    "five-years"
))

# Load optimal mse combination
include(scriptsdir("mse-combination-2019", "optmse2019.jl"))
include(scriptsdir("mse-combination", "optmse2022.jl"))

## Experimental calibration procedure with several inflation measures

# Depending on the single period selected (:b00 or :b10), these functions select the appropriate exclusion specifications for the fixed exclusion methods
function food_energy_specs(period)
    if period == :b00 
        return [23:41..., 104, 159]
    elseif period == :b10 
        return [22:48..., 116, 184:186...]
    else
        return [23:41..., 104, 159], [22:48..., 116, 184:186...]
    end
end

function energy_specs(period)
    if period == :b00 
        return [104, 159]
    elseif period == :b10 
        return [116, 184:186...]
    else
        return [104, 159], [116, 184:186...]
    end
end

# Fixes exclusion specs for the InflationFixedExclusionCPI included in the combination ensemble combfn, using specs for period specified.
function cmb_specs(combfn, period)
    fns = [combfn.ensemble.functions...]
    f = [fn isa InflationFixedExclusionCPI for fn in fns]

    exc_specs = fns[f][].v_exc
    if period == :b00 
        specs = exc_specs[1]
    elseif period == :b10 
        specs = exc_specs[2]
    else
        specs = exc_specs
    end
    fxfn = InflationFixedExclusionCPI(specs)
    fns[.!f]..., fxfn
end

infl_measures = [
    InflationTotalCPI(), 
    InflationWeightedMean(), 
    optmse2019,
    optmse2022,
    cmb_specs(optmse2022, PERIOD)..., 
    # Other measures used in DIE-BG 
    InflationTrimmedMeanEq(8,92), 
    InflationTrimmedMeanEq(6,94),
    InflationDynamicExclusion(2,2),
    InflationFixedExclusionCPI(food_energy_specs(PERIOD)), # Food & energy 
    InflationFixedExclusionCPI(energy_specs(PERIOD)), # Energy exclusion 
    # Central banks measures
    InflationTrimmedMeanWeighted(8,92),
    InflationTrimmedMeanEq(24,69),
    InflationTrimmedMeanWeighted(24,69),
    InflationPercentileEq(50), # Fed Cleveland
    InflationPercentileWeighted(50) # Fed Cleveland & Bank of Canada
]

# f = [fn isa InflationFixedExclusionCPI for fn in infl_measures]
# infl_measures = infl_measures[.!f]

# Removing already calibrated components, i.e. previous optimal measures  obtained
f = BitVector(Bool[1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1])
if !USE_OPTIMALS
    infl_measures = infl_measures[f]
end

## Comparing median of MSEs for historical realizations comparing to the population parameter

p_range = 0:0.05:1

mse_medians = @showprogress pmap(p_range) do p
    # Get parametric inflation
    resamplefn = ResampleScrambleTrended(p)
    param = InflationParameter(PARAM_INFLFN, resamplefn, TrendIdentity())
    tray_infl_param = param(evaldata)
    
    # Get the MSE against all historic inflation measures
    mses = map(infl_measures) do inflfn 
        # Compute the historic trajectory 
        tray_infl = inflfn(evaldata)
        # Compute the MSE against the parametric trajectory 
        mean(x -> x^2, tray_infl[evalmask] - tray_infl_param[evalmask])
    end

    @debug "Valores de MSE" mses
    # Get the median value of the MSEs 
    mse_median = median(mses)
end

## Plot the MSE medians for every p 

p1 = plot(p_range, mse_medians, 
    label = "Mediana del MSE de las series históricas", 
    ylabel = "Error cuadrático medio", 
    xlabel = "Probabilidad de selección del período t", 
    xticks = p_range, 
    xrotation = 45,
    linewidth = 2,
    size = (800,600)
)

imin = argmin(mse_medians)
scatter!(p1, [p_range[imin]], [mse_medians[imin]], 
    label = "MSE mínimo",
    color = :red 
)

filename = savename("historical_calibration", (period = PERIOD, optimals=USE_OPTIMALS), "png")
savefig(joinpath(plots_path, filename))



## Explore historical trajectories comparing to the inflation parameter with p 

p_range = 0:0.01:1

anim = @animate for p in p_range
    # Get parametric inflation
    resamplefn = ResampleScrambleTrended(p)
    param = InflationParameter(PARAM_INFLFN, resamplefn, TrendIdentity())
    tray_infl_param = param(evaldata)
    
    dates = infl_dates(evaldata)
    plot(dates, tray_infl_param, 
        label="Parametric trajectory p=$(round(p,digits=5))",
        linewidth = 2,
        ylims = (0, 12),
    )

    # Plot actual trajectory 
    plot!(InflationTotalCPI(), evaldata)

    # # Get the MSE against all historic inflation measures
    # mses = map(infl_measures) do inflfn 
    #     # Compute the historic trajectory 
    #     tray_infl = inflfn(evaldata)
    #     # Compute the MSE against the parametric trajectory 
    #     mean(x -> x^2, tray_infl[evalmask] - tray_infl_param[evalmask])
    # end

    # @debug "Valores de MSE" mses
    # # Get the median value of the MSEs 
    # mse_median = median(mses)
end

animfile = savename("param_evolution", (period = PERIOD, optimals=USE_OPTIMALS), "mp4")
mp4(anim, joinpath(plots_path, animfile), fps=15)