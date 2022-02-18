##  ----------------------------------------------------------------------------
#   Investigación y pruebas sobre método de remuestreo alternativo que incluye
#   la tendencia estocástica.
#   ----------------------------------------------------------------------------
using DrWatson
@quickactivate :HEMI 

using StatsBase
using Plots

function probs(i,j,s,p=0.5)
    i == j && return p
    return (1 - p)/(s - 1)
end

# Collection of probability weights for the different months
pm = [pweights([probs(i, j, 10, 0.8) for j in 1:10]) for i in 1:10]

r = sample(1:12:120, pm[10], 10000)
# histogram(r)




## Definición de la función de remuestreo 

import Random
import StatsBase: pweights, sample!

# function get_pweights(m::Int, n::Int)
#     possible = m:12:n
#     s = length(possible)
#     StatsBase.pweights([i == j ? p : (1-p)/(s-1) for i in 1:s])
# end

# function get_pweight_collection(n::Int, p::Float64)
#     [ for m in 1:12]
# end

function trended_inds!(indexes::Vector{Int}, p::Float64, rng = Random.GLOBAL_RNG)
    numobs = length(indexes)
    # Generate indexes from available observations from the same months
    for m in 1:12
        possible = m:12:numobs
        monthinds = @view indexes[possible]
        # Fill index vector with possible values for each month, sliding
        # probability window
        s = length(possible)
        for j in 1:s
            probs = StatsBase.pweights([i == j ? p : (1-p)/(s-1) for i in 1:s])
            monthinds[j] = StatsBase.sample(rng, possible, probs)
        end
    end
end

idx = zeros(Int, 120)
trended_inds!(idx, 0.5)
idx

# Testing desired statistical properties
K = 10000
reps = Vector{Int}(undef, K)
map(1:K) do i
    trended_inds!(idx, 0.5)
    reps[i] = idx[1]
end

histogram(reps)


# Complete these functions to obtain parametric data from this resampling methodology
# REVIEW and recheck this code...
function param_rst(vmat::AbstractMatrix, p:: Float64)
    numobs = size(vmat, 1)
    # Output matrix with parametric data
    paramvmat = similar(vmat)
    # For the observations from the same months
    for m in 1:12
        # Compute possible indices to take from
        possible = m:12:numobs
        paramdata = @view paramvmat[possible, :]
        monthdata = @view vmat[possible, :]
        s = length(possible)
        # For the same month from each year in the sample, compute parametric
        # data as the expected value of the discrete distribution, which slides
        # the p probability through the different years of the sample
        for j in 1:s
            probs = [i == j ? p : (1-p)/(s-1) for i in 1:s]
            paramdata[j, :] = probs' * monthdata
        end
    end
    paramvmat
end

function param_rst(base::VarCPIBase, p::Float64)
    # Compute parametric data for price changes matrix
    param_data = param_rst(base.v, p)

    # Return a new parametric VarCPIBase with expected price changes for each (period, good)
    VarCPIBase(param_data, base.w, base.dates, base.baseindex)
end
 
function param_rst(cs::CountryStructure, p)
    pob_base = map(b -> param_rst(b, p), cs.base)
    getunionalltype(cs)(pob_base)
end

# New type to represent this resample methodology

import InflationEvalTools: ResampleFunction, get_param_function, method_name, method_tag

struct ResampleScrambleTrended <: ResampleFunction
    p::Float64
end

method_name(fn::ResampleScrambleTrended) = "Bootstrap IID ponderado por meses de ocurrencia"
method_tag(fn::ResampleScrambleTrended) = "WST"
get_param_function(fn::ResampleScrambleTrended) = cs -> param_rst(cs, fn.p)

function (resamplefn::ResampleScrambleTrended)(vmat::AbstractMatrix, rng = Random.GLOBAL_RNG)
    periods, _ = size(vmat)
    indexes = Vector{Int}(undef, periods)
    trended_inds!(indexes, resamplefn.p, rng)

    vmat[indexes, :]
end


##
# resamplefn = ResampleScrambleVarMonths()
resamplefn = ResampleScrambleTrended(0.75)
# inflfn = InflationWeightedMean()
inflfn = InflationPercentileEq(72)
# inflfn = InflationTotalCPI()
# inflfn = InflationTotalRebaseCPI(36, 2)
K = 500
tray_infl = Matrix{Float32}(undef, infl_periods(gtdata), K)
plot()
for k in 1:K
    tray_infl[:, k] = gtdata |> resamplefn |> inflfn
    plot!(infl_dates(gtdata), tray_infl[:, k], label=false, color=:gray, alpha=0.2)
end
plot!(infl_dates(gtdata), gtdata |> inflfn, label = "Observed", lw=3, color=:black)
plot!(infl_dates(gtdata), get_param_function(resamplefn)(gtdata) |> inflfn, label = "Parametric", lw=2, color=:red)
plot!(infl_dates(gtdata), mean(tray_infl, dims=2), label="Average", lw=2, color=:blue)
ylims!(-1, 13)
