# varinterm.jl - basic operations to compute price change arrays

"""
    varinterm!(v, idx, base_index::Real = 100)

Fill `v` vector of price changes of `idx` vector using `base_index` as starting point.
"""
function varinterm!(v::AbstractVector, idx::AbstractVector, base_index::Real = 100)
    l = length(v)
    for i in l:-1:2
        @inbounds v[i] = 100 * (idx[i] / idx[i-1] - 1)
    end
    v[1] = 100 * (idx[1] / base_index - 1)
end


"""
    varinterm(idx::AbstractVector, base_index::Real = 100)

Function to get a vector of price changes from a price index vector starting with `base_index`.
"""
function varinterm(idx::AbstractVector, base_index::Real = 100)
    v = similar(idx)
    varinterm!(v, idx, base_index)
    v
end


"""
    varinterm(cpimat::AbstractMatrix, base_index::Real = 100)

Function to get a matrix of price changes from a price index matrix starting with `base_index`.
"""
function varinterm(cpimat::AbstractMatrix, base_index::Real = 100)
    c = size(cpimat, 2)
    vmat = similar(cpimat)
    for j in 1:c
        vcol = @view vmat[:, j]
        idxcol = @view cpimat[:, j]
        varinterm!(vcol, idxcol, base_index)
    end
    vmat
end

"""
    varinterm(cpimat::AbstractMatrix, base_index::AbstractVector)

Function to get a matrix of price changes from a price index matrix starting with **vector** `base_index`.
"""
function varinterm(cpimat::AbstractMatrix, base_index::AbstractVector)
    c = size(cpimat, 2)
    vmat = similar(cpimat)
    for j in 1:c
        vcol = @view vmat[:, j]
        idxcol = @view cpimat[:, j]
        varinterm!(vcol, idxcol, base_index[j])
    end
    vmat
end

"""
    varinterm!(cpimat::AbstractMatrix, base_index::Real = 100)

Function to get a matrix of price changes from a price index matrix starting with `base_index`.
"""
function varinterm!(cpimat::AbstractMatrix, base_index::Real = 100)
    c = size(cpimat, 2)
    for j in 1:c
        idxcol = @view cpimat[:, j]
        varinterm!(idxcol, idxcol, base_index)
    end
end


"""
    varinterm(base::IndexCPIBase)

This returns a new instance (copy) of type `VarCPIBase` from an `IndexCPIBase`.
"""
function varinterm(base::IndexCPIBase)
    VarCPIBase(base)
end