# simple_mean.jl - Función de inflación de media media_simple

# 1. Definir un tipo
"""
    InflationSimpleMean <: InflationFunction
Función de inflación para computar la media simple.
"""
struct InflationSimpleMean <: InflationFunction
end

# 2. Extender el método de nombre 
measure_name(::InflationSimpleMean) = "Media simple interanual"

"""
    (inflfn::InflationSimpleMean)(base::VarCPIBase)
Define cómo opera InflationSimpleMean sobre un objeto de tipo VarCPIBase.
"""
function (inflfn::InflationSimpleMean)(base::VarCPIBase)
    mean(base.v, dims=2)
end