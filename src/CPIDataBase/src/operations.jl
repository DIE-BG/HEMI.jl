# operations.jl - basic operations with types

"""
    capitalize(v, base_index = 100)

Function to chain a vector of price changes with an index starting with `base_index`.
"""
function capitalize(v, base_index = 100)
    l = length(v)
    idx = similar(v)
    idx[1] = base_index * (1 + v[1]/100)
    for i in 2:l
        idx[i] = idx[i-1] * (1 + v[i]/100)
    end
    idx
end

"""
    capitalize_addbase(vmat::Matrix{T}, base_index = 100) where T

Function to chain a matrix of price changes with an index starting with `base_index`. This function adds the base index as the first row of the returned matrix.
"""
function capitalize_addbase(vmat::Matrix{T}, base_index = 100) where T
    r, c = size(vmat)
    idxmat = zeros(T, r+1, c)
    idxmat[1, :] .= base_index
    for i in 1:r
        @views @. idxmat[i+1, :] = idxmat[i, :] * (1 + vmat[i, :]/100)
    end
    idxmat
end

# julia> @btime (t = CPIDataBase.capitalize3($(gt00.v)));
# 32.900 μs (2 allocations: 206.20 KiB)
# julia> @btime (t = CPIDataBase.capitalize3($(gt00.v), base_index = $b));
# 32.200 μs (2 allocations: 206.20 KiB)

"""
    capitalize(vmat::Matrix, base_index = 100)

Function to chain a matrix of price changes with an index starting with `base_index`.
"""
function capitalize(vmat::Matrix, base_index = 100)
    r = size(vmat, 1)
    idxmat = similar(vmat)
    @views @. idxmat[1, :] = base_index * (1 + vmat[1, :]/100)
    for i in 2:r
        @views @. idxmat[i, :] = idxmat[i-1, :] * (1 + vmat[i, :]/100)
    end
    idxmat
end

# julia> @btime (t = CPIDataBase.capitalize31($(gt00.v)));
# 32.200 μs (4 allocations: 208.42 KiB)
# julia> @btime (t = CPIDataBase.capitalize31($(gt00.v), base_index = $b));
# 31.100 μs (2 allocations: 204.45 KiB)

## Version in place

"""
    capitalize!(vmat::Matrix{T}, base_index = 100) where T

Function to chain a matrix of price changes **in place** with an index starting with `base_index`.
"""
function capitalize!(vmat::Matrix{T}, base_index = 100) where T
    r = size(vmat, 1)
    @views @. vmat[1, :] = base_index * (1 + vmat[1, :]/100)
    for i in 2:r
        @views @. vmat[i, :] = vmat[i-1, :] * (1 + vmat[i, :]/100)
    end
end

# julia> v00 = copy(gt00.v)
# julia> @btime (t = CPIDataBase.capitalize!($v00));
# 25.000 μs (2 allocations: 3.97 KiB)

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