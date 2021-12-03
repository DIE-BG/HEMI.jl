# varinteran.jl - operaciones básicas para computar variaciones interanuales de
# ìndices de precios 

"""
    varinteran(idx::AbstractVector, base_index::Real = 100) -> Vector{<:AbstractFloat}
    varinteran(cpimat::AbstractMatrix, base_index::Real = 100) -> Matrix{<:AbstractFloat}
    varinteran(cpimat::AbstractMatrix, base_index::AbstractVector) -> Matrix{<:AbstractFloat}

Obtiene variaciones interanuales del vector `idx` o de la matriz `cpimat`
utilizando como índice base el número o vector `base_index`. 

- Si `base_index` es un vector, se obtienen las variaciones interanuales
  utilizando diferentes índices base para cada columna de `cpimat`. El vector
  `base_index` debe tener la misma cantidad de columnas que `cpimat`.
"""
function varinteran end 


"""
    varinteran!(v::AbstractVector, idx::AbstractVector, base_index::Real = 100) -> Vector{<:AbstractFloat}

Computa las variaciones interanuales del vector `idx` utilizando como índice
base `base_index`. Si se provee `v`, los resultados son guardados en este
vector, en vez del mismo `idx`.

- El vector `v` tiene 11 observaciones menos que `idx`.
"""
function varinteran!(v::AbstractVector, idx::AbstractVector, base_index::Real = 100)
    l = length(v)
    for i in l:-1:2
        @inbounds v[i] = 100 * (idx[i+11] / idx[i-12+11] - 1)
    end
    v[1] = 100 * (idx[12] / base_index - 1)
end

# Implementación sobre AbstractVector
function varinteran(idx::AbstractVector, base_index::Real = 100)
    r = length(idx)
    v = zeros(eltype(idx), r-11)
    varinteran!(v, idx, base_index)
    v
end

# Implementación sobre AbstractMatrix
function varinteran(cpimat::AbstractMatrix, base_index::Real = 100)
    r, c = size(cpimat)
    vmat = zeros(eltype(cpimat), r-11, c)
    for j in 1:c
        vcol = @view vmat[:, j]
        idxcol = @view cpimat[:, j]
        varinteran!(vcol, idxcol, base_index)
    end
    vmat
end

# Implementación que utiliza diferentes índices base 
function varinteran(cpimat::AbstractMatrix, base_index::AbstractVector)
    r, c = size(cpimat)
    vmat = zeros(eltype(cpimat), r-11, c)
    for j in 1:c
        vcol = @view vmat[:, j]
        idxcol = @view cpimat[:, j]
        varinteran!(vcol, idxcol, base_index[j])
    end
    vmat
end