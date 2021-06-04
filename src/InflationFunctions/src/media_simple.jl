# media_simple.jl - Función de inflación de media media_simple

# 1. Definir un tipo
Base.@kwdef struct MediaSimple <: InflationFunction
    name::String = "Media simple"
end

# 2. Definir cómo opera MediaSimple sobre un objeto de tipo VarCPIBase
function (inflfn::MediaSimple)(base::VarCPIBase)
    mean(base.v, dims=2)
end