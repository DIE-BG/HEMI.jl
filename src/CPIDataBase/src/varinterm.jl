# varinterm.jl - basic operations to compute price change arrays

"""
    varinterm!(v, idx, base_index)

Fill `v` vector of price changes of `idx` vector using `base_index` as starting point.
"""
function varinterm!(v::AbstractVector, idx::AbstractVector, base_index)
    l = length(v)
    v[1] = 100 * (idx[1] / base_index - 1)
    for i in 2:l
        @inbounds v[i] = 100 * (idx[i] / idx[i-1] - 1)
    end
end


"""
    varinterm(idx::AbstractVector, base_index = 100)

Function to get a vector of price changes from a price index vector starting with `base_index`.
"""
function varinterm(idx::AbstractVector, base_index = 100)
    v = similar(idx)
    varinterm!(v, idx, base_index)
    v
end


"""
    varinterm(cpimat::AbstractMatrix, base_index::AbstractFloat = 100.0)

Function to get a matrix of price changes from a price index matrix starting with `base_index`.
"""
function varinterm(cpimat::AbstractMatrix, base_index::AbstractFloat = 100.0)
    c = size(cpimat, 2)
    vmat = similar(cpimat)
    for j in 1:c
        vcol = @view vmat[:, j]
        idxcol = @view cpimat[:, j]
        varinterm!(vcol, idxcol, base_index)
    end
    vmat
end

# function varinterm(cpimat::AbstractMatrix, base_index::AbstractFloat = 100.0)
#     r, c = size(cpimat)
#     vmat = similar(cpimat)
#     for i in 1:r, j in 1:c
#         if i == 1
#             @inbounds vmat[i, j] = 100 * (cpimat[i, j] / base_index - 1)
#         else
#             @inbounds vmat[i, j] = 100 * (cpimat[i, j] / cpimat[i-1, j] - 1)
#         end
#     end
#     vmat
# end


function varinterm_back!(v::AbstractVector, idx::AbstractVector, base_index)
    l = length(v)
    for i in l:-1:2
        @inbounds v[i] = 100 * (idx[i] / idx[i-1] - 1)
    end
    v[1] = 100 * (idx[1] / base_index - 1)
end


"""
    varinterm!(cpimat::AbstractMatrix, base_index::AbstractFloat = 100.0)

Function to get a matrix of price changes from a price index matrix starting with `base_index`.
"""
function varinterm!(cpimat::AbstractMatrix, base_index::AbstractFloat = 100.0)
    c = size(cpimat, 2)
    for j in 1:c
        idxcol = @view cpimat[:, j]
        varinterm_back!(idxcol, idxcol, base_index)
    end
end


"""
    varinterm(base::IndexCPIBase)

This returns a new instance (copy) of type `VarCPIBase` from an `IndexCPIBase`.
"""
function varinterm(base::IndexCPIBase)
    VarCPIBase(base)
end