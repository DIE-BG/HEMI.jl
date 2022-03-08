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
USE_OPTIMALS = true
const PARAM_INFLFN = InflationTotalCPI() 

# Calibration data used 
if PERIOD == :b00 
    evaldata = GTDATA[Date(2010,12)] # CPI 2000 base 
elseif PERIOD == :b10 
    evaldata = UniformCountryStructure(GTDATA[2]) # CPI 2010 base 
else
    evaldata = GTDATA[Date(2021,12)]
end

# Plots folder
plots_path = mkpath(plotsdir("trended-resample", "total-cpi-rebase-calibration", "historical_calibration"))

# Load optimal mse combination
include(scriptsdir("mse-combination-2019", "optmse2019.jl"))
include(scriptsdir("mse-combination", "optmse2022.jl"))

# df = CSV.read(scriptsdir("trended-resample", "infl_suby.csv"), DataFrame)

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

infl_measures = [
    InflationTotalCPI(), 
    InflationWeightedMean(), 
    optmse2019,
    optmse2022, 
    optmse2022.ensemble.functions...,
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

# Removing already calibrated components, i.e. previous optimal measures  obtained
f = BitVector(Bool[1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1])
if !USE_OPTIMALS
    infl_measures = infl_measures[f]
end

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
        mean(x -> x^2, tray_infl - tray_infl_param)
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