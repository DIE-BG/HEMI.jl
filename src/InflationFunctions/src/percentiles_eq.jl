# percentiles_eq.jl - Definición de percentiles equiponderados

## Percentil equiponderado

# k representa el cuantil equiponderado (entre 0 y 1)
Base.@kwdef struct InflationPercentileEq <: InflationFunction
    k::Float32
end

# Métodos para crear funciones de inflación a partir de enteros y flotantes
InflationPercentileEq(k::Int) = InflationPercentileEq(k = Float32(k) / 100)
function InflationPercentileEq(q::T) where {T <: AbstractFloat} 
    q < 1.0 && InflationPercentileEq(convert(Float32, q))
    InflationPercentileEq(convert(Float32, q) / 100)
end

measure_name(inflfn::InflationPercentileEq) = "Percentil equiponderado " * string(round(100inflfn.k, digits=2))

# Las funciones sobre VarCPIBase resumen en variaciones intermensuales
function (inflfn::InflationPercentileEq)(base::VarCPIBase{T}) where T 
    # InflationPercentileEq k de la distribución de variaciones intermensuales
    k = inflfn.k

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