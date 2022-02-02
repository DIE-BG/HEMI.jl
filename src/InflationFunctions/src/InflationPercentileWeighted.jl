# Inflación de Percentiles Ponderados

# InflationPercentileWeighted.jl - Definición de percentiles ponderados

"""
    InflationPercentileWeighted <: InflationFunction
Función de inflación para computar el percentil ponderado k.

## Utilización

    function (inflfn::InflationPercentileWeighted)(base::VarCPIBase{T}) where T 

Define cómo opera `InflationPercentileWeighted` sobre un objeto de tipo VarCPIBase.

    function (inflfn::InflationPercentileWeighted)(cs::CountryStructure) 

### Ejemplo
Cálculo del percentil 70 de la distribución de variaciones intermensuales ponderadas

```julia-repl
julia> percfn = InflationPercentileWeighted(70)
(::InflationPercentileWeighted) (generic function with 5 methods)
julia>percfn(gtdata) #gtdata es de tipo UniformCountryStructure
231-element Vector{Float32}:
 11.189365
 11.571873
 11.738467
 11.552155
 11.763763
  ⋮
  1.8916845
  2.074194
  2.0474315
  2.1219969
  2.2268414
```
"""
Base.@kwdef struct InflationPercentileWeighted <: InflationFunction
    k::Float32
end

# Métodos para crear funciones de inflación a partir de enteros y flotantes
"""
    InflationPercentileWeighted(k::Int) = InflationPercentileWeighted(k = Float32(k) / 100)
    InflationPercentileWeighted(q::T) where {T <: AbstractFloat} 
Permite utilizar valores de `k` que no necesariamente son de tipo de punto flotante, como por ejemplo: enteros, fracciones, Float32 y Float64.

# Ejemplo
Se usa 0.70 en lugar de 70

```julia-repl
julia> percfn = InflationPercentileWeighted(0.70)
(::InflationPercentileWeighted) (generic function with 5 methods)

julia>percfn(gtdata) 
231-element Vector{Float32}:
 11.189365
 11.571873
 11.738467
 11.552155
 11.763763
  ⋮
  1.8916845
  2.074194
  2.0474315
  2.1219969
  2.2268414
```
Se obtienen los mismos resultados
"""
InflationPercentileWeighted(k::Int) = InflationPercentileWeighted(k = Float32(k) / 100)
function InflationPercentileWeighted(q::T) where {T <: AbstractFloat} 
    q < 1.0 && return InflationPercentileWeighted(convert(Float32, q))
    InflationPercentileWeighted(convert(Float32, q) / 100)
end

"""
    measure_name(inflfn::InflationPercentileWeighted)

Indica qué medida se utiliza para una instancia de una función de inflación.

# Ejemplo
```julia-repl
julia> percfn = InflationPercentileWeighted(0.70)
julia> measure_name(percfn)
"Percentil ponderado 70.0"
```
"""
measure_name(inflfn::InflationPercentileWeighted) = "Percentil ponderado " * string(round(100inflfn.k, digits=2))

# Parámetro de la función de inflación
params(inflfn::InflationPercentileWeighted) = (inflfn.k, )

# Las funciones sobre VarCPIBase se resumen en variaciones intermensuales
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

function InflationPercentileWeighted(vec::Vector{<:Real})
    x = vec[1]
    return InflationPercentileWeighted(x)
end