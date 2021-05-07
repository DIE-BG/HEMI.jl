# percentiles_eq.jl - Definición de percentiles equiponderados

## Percentil equiponderado

Base.@kwdef struct Percentil{K <: AbstractFloat} <: InflationFunction
    name::String = "Percentil equiponderado"
    params::K
end

Percentil(k) = Percentil(params = k)
Percentil(k::Int) = Percentil(params=convert(Float32, k) / 100)

measure_name(inflfn::Percentil) = inflfn.name * " " * string(inflfn.params * 100)

# Las funciones sobre VarCPIBase resumen en variaciones intermensuales
function (inflfn::Percentil)(base::VarCPIBase{T}) where T 
    # Percentil k de la distribución de variaciones intermensuales
    k = inflfn.params

    # Obtener el percentil k de la distribución intermensual 
    rows = size(base.v, 1)
    k_interm = Vector{T}(undef, rows)
    Threads.@threads for r in 1:rows
        row = @view base.v[r, :]
        k_interm[r] = quantile(row, k)
    end
    
    # # Obtener el percentil k de la distribución intermensual 
    # vt = permutedims(base.v)
    # rows, cols = size(vt)
    # k_interm = Vector{T}(undef, cols)
    # Threads.@threads for c in 1:cols
    #     col = @view vt[:, c]
    #     sort!(col)
    #     K_idx = Int(ceil(k * rows))
    #     k_interm[c] = col[K_idx]
    # end

    k_interm
end