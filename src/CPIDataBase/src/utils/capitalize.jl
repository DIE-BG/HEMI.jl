# capitalize.jl - basic operations to chain price change arrays

"""
    capitalize(v::AbstractVector, base_index::Real = 100)

Function to chain a vector of price changes with an index starting with `base_index`.
"""
function capitalize(v::AbstractVector, base_index::Real = 100)
    idx = similar(v)
    capitalize!(idx, v, base_index)
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
    capitalize(vmat::AbstractMatrix, base_index::Real = 100)

Function to chain a matrix of price changes with an index starting with `base_index`.
"""
function capitalize(vmat::AbstractMatrix, base_index::Real = 100)
    c = size(vmat, 2)
    idxmat = similar(vmat)
    for j in 1:c
        vcol = @view vmat[:, j]
        idxcol = @view idxmat[:, j]
        capitalize!(idxcol, vcol, base_index)
    end
    idxmat
end

"""
    capitalize(vmat::AbstractMatrix, base_index::AbstractVector)

Function to chain a matrix of price changes with an index vector starting with `base_index`. `base_index` needs to have the same number of elements as the columns of `vmat`.
"""
function capitalize(vmat::AbstractMatrix, base_index::AbstractVector)
    c = size(vmat, 2)
    idxmat = similar(vmat)
    for j in 1:c
        vcol = @view vmat[:, j]
        idxcol = @view idxmat[:, j]
        capitalize!(idxcol, vcol, base_index[j])
    end
    idxmat
end

## Version in place

"""
capitalize!(idx:: AbstractVector, v::AbstractVector, base_index::Real)

Function to chain a vector of price changes in vector `idx` with an index starting with `base_index`.
"""
function capitalize!(idx:: AbstractVector, v::AbstractVector, base_index::Real)
    l = length(v)
    idx[1] = base_index * (1 + v[1]/100)
    for i in 2:l
        @inbounds idx[i] = idx[i-1] * (1 + v[i]/100)
    end
end

capitalize!(v::AbstractVector, base_index::Real) = capitalize!(v, v, base_index)


"""
    capitalize!(vmat::AbstractMatrix, base_index = 100)

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
    start = first(dates) - Month(1)
    start:Month(1):last(dates)
end

"""
    capitalize(base::VarCPIBase)

This returns a new instance (copy) of type `IndexCPIBase` from a `VarCPIBase`.
"""
function capitalize(base::VarCPIBase)
    IndexCPIBase(base)
end