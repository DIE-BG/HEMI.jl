# percentiles_eq.jl - Definición de percentiles equiponderados

## Percentil equiponderado

Base.@kwdef struct Percentil{K} <: InflationFunction
    name::String = "Percentil equiponderado"
    params::K
end

Percentil(k::Real) = Percentil(; params=convert(Float32, k))

measure_name(inflfn::Percentil) = inflfn.name * " " * string(inflfn.params)

# Las funciones sobre VarCPIBase resumen en variaciones intermensuales
function (inflfn::Percentil)(base::VarCPIBase) 
    k = inflfn.params
    k_interm = map(r -> quantile(r, k), eachrow(base.v))
end