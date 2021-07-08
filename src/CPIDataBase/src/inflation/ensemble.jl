# ensemble.jl - Ensemble measures to compute more than one measure at a time

"""
    EnsembleInflationFunction <: InflationFunction

Tipo abstracto para conformar conjuntos de medidas de inflación
"""
abstract type EnsembleInflationFunction <: InflationFunction end

## EnsembleFunction

"""
    EnsembleFunction{N} <: EnsembleInflationFunction
Función de inflación para computar un conjunto de `N` de medidas de inflación.
"""
struct EnsembleFunction{N} <: EnsembleInflationFunction
    functions::NTuple{N, F where {F <: InflationFunction}} 
end

# Constructor a partir de funciones de inflación
EnsembleFunction(functions::Vararg{InflationFunction}) = EnsembleFunction(functions)

# Número de medidas del conjunto
num_measures(ensfn::EnsembleInflationFunction) = sum(num_measures(inflfn) for inflfn in ensfn.functions)

# Nombres de las medidas del conjunto 
function measure_name(ensfn::EnsembleInflationFunction) 
    reduce(vcat, [measure_name(inflfn) for inflfn in ensfn.functions])
end

# Método para obtener las trayectorias de inflación del conjunto
# Se computan para cada medida y se concatenan horizontalmente
function (ensfn::EnsembleFunction)(base::VarCPIBase{T}) where T
    mapreduce(inflfn -> inflfn(base), hcat, ensfn.functions)::Matrix{T}
end





## CombinationFunction

# Tipo para representar combinaciones lineales de conjuntos de medidas
"""
    CombinationFunction{N, W} <: EnsembleInflationFunction
Función de inflación para computar un promedio ponderado de un conjunto de `N`
de medidas de inflación con tipo del vector de ponderaciones `W`.
"""
struct CombinationFunction{N, W} <: EnsembleInflationFunction  
    ensemble::EnsembleFunction{N}
    weights::W

    function CombinationFunction(ensemble::EnsembleFunction{N}, weights::W) where {N, W}
        num_measures(ensemble) == length(weights) || throw(ArgumentError("número de ponderadores debe coincidir con número de medidas"))
        new{N, W}(ensemble, weights)
    end
end

CombinationFunction(args...) = 
    CombinationFunction(EnsembleFunction(args[1:end-1]), args[end])

# Número de medidas
function num_measures(combfn::CombinationFunction; get_components = false) 
    get_components && return num_measures(combfn.ensemble)
    1
end 

# Ponderaciones
"""
    weights(combfn::CombinationFunction)
Devuelve el vector de ponderaciones de una [`CombinationFunction`](@ref).
"""
weights(combfn::CombinationFunction) = getfield(combfn, :weights)

# Nombres de medidas
measure_name(combfn::CombinationFunction) = measure_name(combfn.ensemble)

# Aplicación sobre VarCPIBase del ensemble 
(ensfn::CombinationFunction)(base::VarCPIBase) = ensfn.ensemble(base)

# Aplicación especifica sobre CountryStructure: devuelve la combinación lineal
# en variaciones interanuales
function (combfn::CombinationFunction)(cst::CountryStructure)
    # Get ensemble and compute trajectories
    tray_infl = combfn.ensemble(cst)
    # Return weighted sum
    tray_infl * combfn.weights
end
