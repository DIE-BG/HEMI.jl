# operations.jl - basic operations with types

# capitalization
function capitalize(v; base_index = 100)
    l = length(v)
    idx = zeros(eltype(v), l + 1)
    idx[1] = base_index
    for i in 1:l
        idx[i+1] = idx[i] * (1 + v[i]/100)
    end
    idx
end

#"This adds the base index"
function capitalize_addbase(vmat::Matrix{T}; base_index = 100) where T
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

#"This does not add the base index"
function capitalize(vmat::Matrix; base_index = 100)
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



## Other slower implementations
#=
function capitalize(vmat::Matrix; base_index = 100) 
    reduce(hcat, map(col -> capitalize(col; base_index = base_index), eachcol(vmat)))
end

# this vectorized version is slower
function capitalize2(vmat::Matrix; base_index = 100)
    r, c = size(vmat)
    idxmat = zeros(eltype(vmat), r+1, c)
    idxmat[1, :] .= base_index
    for i in 1:r
        vrow = @view vmat[i, :]
        @. idxmat[i+1, :] = idxmat[i, :] * (1 + vrow/100)
    end
    idxmat
end


function capitalize4(vmat::Matrix; base_index = 100)
    idxmat = base_index' .* cumprod(1 .+ (vmat/100); dims = 1)
end

function capitalize5(vmat::Matrix{T}, base_index = 100*ones(T, size(vmat, 2))) where T
    r, c = size(vmat)
    idxmat = similar(vmat)
    idxmat[1, :] .= base_index
    for i in 1:r
        prev = i == 1 ? base_index : @view idxmat[i-1, :]
        @views @. idxmat[i, :] = prev * (1 + vmat[i, :]/100)
    end
    idxmat
end
=#

## Version in place

function capitalize!(vmat::Matrix{T}; base_index = 100) where T
    r = size(vmat, 1)
    # idxmat = similar(vmat)
    @views @. vmat[1, :] = base_index * (1 + vmat[1, :]/100)
    for i in 2:r
        @views @. vmat[i, :] = vmat[i-1, :] * (1 + vmat[i, :]/100)
    end
end

# julia> v00 = copy(gt00.v)
# julia> @btime (t = CPIDataBase.capitalize!($v00));
# 25.000 μs (2 allocations: 3.97 KiB)

## On containers

function capitalize(base::VarCPIBase)
    capitalize(base.v)
end