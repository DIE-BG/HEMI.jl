# ResampleTrended.jl - Funciones para computar la metodología de
# remuestreo por meses de ocurrencia, con pesos probabilísticos para recrear la
# tendencia de los datos. El parámetro p es individual por cada base de un 
# CountryStructure

struct ResampleTrended{T<:AbstractFloat} <: ResampleFunction
    p::Vector{T}
end

method_name(fn::ResampleTrended) = "Bootstrap IID ponderado por meses de ocurrencia, bases individuales"
method_tag(fn::ResampleTrended) = "RSTI"
get_param_function(fn::ResampleTrended) = cs -> param_rst(cs, fn.p)

# Overload this method to operate the resample function by base
function (resamplefn::ResampleTrended)(cs::CountryStructure, rng = Random.GLOBAL_RNG)
    # Obtener bases remuestreadas
    ps = (resamplefn.p...,)
    base_boot = map((b, p) -> resamplefn(b, p, rng), cs.base, ps)
    # Devolver nuevo CountryStructurej
    typeof(cs)(base_boot)
end

function (resamplefn::ResampleTrended)(base::VarCPIBase, p, rng = Random.GLOBAL_RNG)
    v_boot = resamplefn(base.v, p, rng)
    VarCPIBase(v_boot, base.w, base.dates, base.baseindex)
end

# Definition to operate over arbitrary matrix
function (resamplefn::ResampleTrended)(vmat::AbstractMatrix, p, rng = Random.GLOBAL_RNG)
    periods, ngoods = size(vmat)
    indexes = Vector{Int}(undef, periods)
    
    # Create and return the resampled series
    resampled_vmat = similar(vmat)
    # Procedure of weighted resampling is applied for every good or service in
    # the vmat matrix
    for j in 1:ngoods
        trended_inds!(indexes, p, rng)
        resampled_vmat[:, j] .= vmat[indexes, j]
    end
    resampled_vmat
end

##  ----------------------------------------------------------------------------
#   Auxiliary functions to define the parametric dataset
#   ----------------------------------------------------------------------------

function param_rst(cs::CountryStructure, p::Vector{<:AbstractFloat})
    # Resample each CPI dataset in the CountryStructure
    ps = (p...,)
    pob_base = map((b,p) -> param_rst(b, p), cs.base, ps)
    getunionalltype(cs)(pob_base)
end