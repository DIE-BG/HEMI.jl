# Inflación de Percentiles Ponderados

# InflationPercentileWeighted.jl - Definición de percentiles ponderados


## Percentil ponderado

# k representa el cuantil ponderado (entre 0 y 1)
"""
    InflationPercentileWeighted <: InflationFunction

Función de inflación para computar el percentil ponderado k.

## Ejemplos 

```julia-repl
julia> percfn = InflationPercentileWeighted(70)
```
"""
Base.@kwdef struct InflationPercentileWeighted <: InflationFunction
    k::Float32
end

# Métodos para crear funciones de inflación a partir de enteros y flotantes
InflationPercentileWeighted(k::Int) = InflationPercentileWeighted(k = Float32(k) / 100)
function InflationPercentileWeighted(q::T) where {T <: AbstractFloat} 
    q < 1.0 && return InflationPercentileWeighted(convert(Float32, q))
    InflationPercentileWeighted(convert(Float32, q) / 100)
end

measure_name(inflfn::InflationPercentileWeighted) = "Percentil ponderado " * string(round(100inflfn.k, digits=2))

# Las funciones sobre VarCPIBase resumen en variaciones intermensuales
function (inflfn::InflationPercentileWeighted)(base::VarCPIBase{T}) where T 
    # InflationPercentileWeighted k de la distribución de variaciones intermensuales
    k = inflfn.k

    # Obtener el percentil k de la distribución intermensual 
    rows = size(base.v, 1)
    w = StatsBase.aweights(base.w)

    k_interm = Vector{T}(undef, rows)
    Threads.@threads for r in 1:rows
        row = @view base.v[r, :]
        k_interm[r] = StatsBase.quantile(row, w, k)
        
    end
    
    k_interm
end