# ResampleScrambleTrended.jl - Funciones para computar la metodología de
# remuestreo por meses de ocurrencia, con pesos probabilísticos para recrear la
# tendencia de los datos

struct ResampleScrambleTrended <: ResampleFunction
    p::Float64
end

method_name(fn::ResampleScrambleTrended) = "Bootstrap IID ponderado por meses de ocurrencia"
method_tag(fn::ResampleScrambleTrended) = "RST"
get_param_function(fn::ResampleScrambleTrended) = cs -> param_rst(cs, fn.p)

# Definition to operate over arbitrary matrix
function (resamplefn::ResampleScrambleTrended)(vmat::AbstractMatrix, rng = Random.GLOBAL_RNG)
    periods, ngoods = size(vmat)
    indexes = Vector{Int}(undef, periods)
    
    # Create and return the resampled series
    resampled_vmat = similar(vmat)
    # Procedure of weighted resampling is applied for every good or service in
    # the vmat matrix
    for j in 1:ngoods
        trended_inds!(indexes, resamplefn.p, rng)
        resampled_vmat[:, j] .= vmat[indexes, j]
    end
    resampled_vmat
end

##  ----------------------------------------------------------------------------
#   Auxiliary definitions for this resample methodology
#   ----------------------------------------------------------------------------

# Function to fill resample indexes with probability p of selecting the actual
# observation
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


##  ----------------------------------------------------------------------------
#   Auxiliary functions to define the parametric dataset
#   ----------------------------------------------------------------------------

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

    # Return a new parametric VarCPIBase with expected price changes for each
    # (period, good)
    VarCPIBase(param_data, base.w, base.dates, base.baseindex)
end

function param_rst(cs::CountryStructure, p)
    # Resample each CPI dataset in the CountryStructure
    pob_base = map(b -> param_rst(b, p), cs.base)
    getunionalltype(cs)(pob_base)
end