# percentiles_eq.jl - Definición de percentiles equiponderados

## Percentil equiponderado

Base.@kwdef struct Percentil{K <: AbstractFloat} <: InflationFunction
    name::String = "Percentil equiponderado"
    params::K
end

Percentil(k::Int) = Percentil(; params=k/100)

measure_name(inflfn::Percentil) = inflfn.name * " " * string(inflfn.params)

# Las funciones sobre VarCPIBase resumen en variaciones intermensuales
function (inflfn::Percentil)(base::VarCPIBase) 
    k = inflfn.params

    # Percentil k es el elemento número K_idx del vector de gastos básicos
    G = size(base.v, 2)
    K_idx = Int(ceil(k * G))
    
    k_interm = map(r -> sort(r)[K_idx], eachrow(base.v))
end