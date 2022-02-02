# Inflación de Percentiles Equiponderados

# InflationPercentileEq.jl - Definición de percentiles equiponderados

"""
    InflationPercentileEq <: InflationFunction
Función de inflación para computar el percentil equiponderado `k`.

## Utilización

    function (inflfn::InflationPercentileEq)(base::VarCPIBase{T}) where T 

Define cómo opera `InflationPercentileEq` sobre un objeto de tipo VarCPIBase.

    function (inflfn::InflationPercentileEq)(cs::CountryStructure) 

Define cómo opera `InflationPercentileEq` sobre un objeto de tipo CountryStructure.

### Ejemplo
Cálculo del percentil 70 de la distribución de variaciones intermensuales ponderadas

```julia-repl
julia> percEqfn = InflationPercentileEq(70)
(::InflationPercentileEq) (generic function with 5 methods)
julia>percEqfn(gtdata) #gtdata es de tipo UniformCountryStructure
231-element Vector{Float32}:
9.812069
10.271847
10.382021
10.323441
10.427952 
⋮
1.9042492
1.9850135
1.9871473
2.0293117
2.1856546
```
"""
Base.@kwdef struct InflationPercentileEq <: InflationFunction
    k::Float32
end

# Métodos para crear funciones de inflación a partir de enteros y flotantes
"""
    InflationPercentileEq(k::Int) = InflationPercentileEq(k = Float32(k) / 100)
    InflationPercentileEq(q::T) where {T <: AbstractFloat} 
Permite utilizar valores de `k` que no necesariamente son de tipo de punto flotante, como por ejemplo: enteros, fracciones, Float32 y Float64.

# Ejemplo
Se usa 0.70 en lugar de 70

```julia-repl
julia> percEqfn = InflationPercentileEq(0.70)
(::InflationPercentileEq) (generic function with 5 methods)

julia>percEqfn(gtdata) 
231-element Vector{Float32}:
9.812069
10.271847
10.382021
10.323441
10.427952
⋮
1.9042492
1.9850135
1.9871473
2.0293117
2.1856546
```
Se obtienen los mismos resultados.
"""
InflationPercentileEq(k::Int) = InflationPercentileEq(k = Float32(k) / 100)
function InflationPercentileEq(q::T) where {T <: AbstractFloat} 
    q < 1.0 && return InflationPercentileEq(convert(Float32, q))
    InflationPercentileEq(convert(Float32, q) / 100)
end

"""
    measure_name(inflfn::InflationPercentileEq)

Indica qué medida se utiliza para una instancia de una función de inflación.

# Ejemplo
```julia-repl
julia> percEqfn = InflationPercentileEq(0.70)
julia> measure_name(percEqfn)
"Percentil equiponderado 70.0"
```
"""
measure_name(inflfn::InflationPercentileEq) = "Percentil equiponderado " * string(round(100inflfn.k, digits=2))


# Parámetro de la función de inflación
params(inflfn::InflationPercentileEq) = (inflfn.k, )

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
    
    k_interm
end

function InflationPercentileEq(vec::Vector{<:Real})
    x = vec[1]
    return InflationPercentileEq(x)
end
