# Medidas de conjunto (ensemble) y combinación lineal 

"""
    EnsembleInflationFunction <: InflationFunction <: InflationFunction

Tipo abstracto para conformar conjuntos de medidas de inflación
"""
abstract type EnsembleInflationFunction <: InflationFunction end

## EnsembleFunction

"""
    EnsembleFunction{N} <: EnsembleInflationFunction

    EnsembleFunction(inflfn1, inflfn2 [, ...])

Función de inflación para computar un conjunto de `N` de medidas de inflación simultáneamente utilizando las funciones `inflfn1, inflfn2, ...`.
"""
struct EnsembleFunction{N} <: EnsembleInflationFunction
    functions::NTuple{N, F where {F <: InflationFunction}} 
end

""" 
    InflationEnsemble <: EnsembleInflationFunction <: InflationFunction

Alias para [`EnsembleFunction`](@ref).
"""
const InflationEnsemble = EnsembleFunction


# Constructor a partir de funciones de inflación
EnsembleFunction(functions::Vararg{InflationFunction}) = EnsembleFunction(functions)

# Número de medidas del conjunto
num_measures(ensfn::EnsembleFunction) = sum(num_measures(inflfn) for inflfn in ensfn.functions)

# Nombres de las medidas del conjunto 
function measure_name(ensfn::EnsembleFunction) 
    reduce(vcat, [measure_name(inflfn) for inflfn in ensfn.functions])
end

# Método para obtener las trayectorias de inflación del conjunto
# Se computan para cada medida y se concatenan horizontalmente
function (ensfn::EnsembleFunction)(cs::CountryStructure, ::CPIVarInterm)
    mapreduce(inflfn -> inflfn(cs, CPIVarInterm()), hcat, ensfn.functions)::Matrix{eltype(cs)}
end

function (ensfn::EnsembleFunction)(cs::CountryStructure)
    mapreduce(inflfn -> inflfn(cs), hcat, ensfn.functions)::Matrix{eltype(cs)}
end

