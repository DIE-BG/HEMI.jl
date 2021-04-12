# operations.jl - basic operations with types

"""
    capitalize(v::AbstractVector, base_index = 100)

Function to chain a vector of price changes with an index starting with `base_index`.
"""
function capitalize(v::AbstractVector, base_index = 100)
    l = length(v)
    idx = similar(v)
    idx[1] = base_index * (1 + v[1]/100)
    for i in 2:l
        idx[i] = idx[i-1] * (1 + v[i]/100)
    end
    idx
end

"""
    capitalize_addbase(vmat::AbstractMatrix, base_index = 100) 

Function to chain a matrix of price changes with an index starting with `base_index`. This function adds the base index as the first row of the returned matrix.
"""
function capitalize_addbase(vmat::AbstractMatrix, base_index = 100)
    r, c = size(vmat)
    idxmat = zeros(eltype(vmat), r+1, c)
    idxmat[1, :] .= base_index
    for i in 1:r
        @views @. idxmat[i+1, :] = idxmat[i, :] * (1 + vmat[i, :]/100)
    end
    idxmat
end

"""
    capitalize(vmat::AbstractMatrix, base_index::AbstractFloat = 100.0)

Function to chain a matrix of price changes with an index starting with `base_index`.
"""
function capitalize(vmat::AbstractMatrix, base_index::AbstractFloat = 100.0)
    r, c = size(vmat)
    idxmat = similar(vmat)
    for i in 1:r, j in 1:c
        if i == 1
            @inbounds idxmat[i, j] = base_index * (1 + vmat[i, j]/100)
        else
            @inbounds idxmat[i, j] = idxmat[i-1, j] * (1 + vmat[i, j]/100)
        end
    end
    idxmat
end

"""
    capitalize(vmat::AbstractMatrix, base_index::AbstractVector)

Function to chain a matrix of price changes with an index vector starting with `base_index`. `base_index` needs to have the same number of elements as the columns of `vmat`.
"""
function capitalize(vmat::AbstractMatrix, base_index::AbstractVector)
    r, c = size(vmat)
    idxmat = similar(vmat)
    for i in 1:r, j in 1:c
        if i == 1
            @inbounds idxmat[i, j] = base_index[j] * (1 + vmat[i, j]/100)
        else
            @inbounds idxmat[i, j] = idxmat[i-1, j] * (1 + vmat[i, j]/100)
        end
    end
    idxmat
end

## Version in place

"""
    capitalize!(vmat::AbstractMatrix, base_index = 100) where T

Function to chain a matrix of price changes **in place** with an index starting with `base_index`.
"""
function capitalize!(vmat::AbstractMatrix, base_index = 100)
    r = size(vmat, 1)
    @views @. vmat[1, :] = base_index * (1 + vmat[1, :]/100)
    for i in 2:r
        @views @. vmat[i, :] = vmat[i-1, :] * (1 + vmat[i, :]/100)
    end
end

## On containers

function _offset_back(dates)
    start = dates[begin] - Month(1)
    start:Month(1):dates[end]
end

"""
    capitalize(base::VarCPIBase)

This returns a new instance (copy) of type `IndexCPIBase` from a `VarCPIBase`.
"""
function capitalize(base::VarCPIBase)
    IndexCPIBase(base)
end