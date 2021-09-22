## CombinationFunction - Función de combinación lineal de medidas de inflación

# Tipo para representar combinaciones lineales de conjuntos de medidas
"""
    CombinationFunction{N, W} <: EnsembleInflationFunction <: InflationFunction

    CombinationFunction(ensemble, weights [, name])
    CombinationFunction(inflfn1, inflfn2 [, ...], weights [, name])

Función de inflación para computar un promedio ponderado de un conjunto de `N`
de medidas de inflación con tipo del vector de ponderaciones `W`.
"""
struct CombinationFunction{N, W} <: EnsembleInflationFunction  
    ensemble::EnsembleFunction{N}
    weights::W
    name::Union{Nothing, String}

    function CombinationFunction(ensemble::EnsembleFunction{N}, weights::W, name) where {N, W}
        num_measures(ensemble) == length(weights) || throw(ArgumentError("número de ponderadores debe coincidir con número de medidas"))
        new{N, W}(ensemble, weights, name)
    end
end

""" 
    InflationCombination <: EnsembleInflationFunction <: InflationFunction

Alias para [`CombinationFunction`](@ref).
"""
const InflationCombination = CombinationFunction

# Utilidades para construir una CombinationFunction
CombinationFunction(ensemble, weights) = CombinationFunction(ensemble, weights, nothing)
function CombinationFunction(args...)
    if args[end] isa String 
        return CombinationFunction(EnsembleFunction(args[1:end-2]), args[end-1], args[end])
    end 
    CombinationFunction(EnsembleFunction(args[1:end-1]), args[end])
end

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
function measure_name(combfn::CombinationFunction; 
    return_array=false, 
    show_weights=false) 
    return_array && return measure_name(combfn.ensemble)
    isnothing(combfn.name) || return combfn.name 

    n = length(combfn.ensemble.functions)
    wstr = show_weights ? "\n"*string(round.(combfn.weights, digits=2)) : ""
    "Promedio ponderado de $n metodologías" * wstr
end

# Aplicación sobre (::CountryStructure, ::CPIVarInterm) ajusta los índices y
# variaciones intermensuales para estar acordes con el promedio de las variaciones
# interanuales 
function (combfn::CombinationFunction)(cs::CountryStructure, ::CPIVarInterm)
    cpi_index = combfn(cs, CPIIndex())
    varinterm!(cpi_index, cpi_index) # cpi_index -> v_interm
    cpi_index
    # varinterm(cpi_index)
end

function (combfn::CombinationFunction)(cs::CountryStructure, ::CPIIndex)
    # Obtener variaciones interanuales 
    v_yoy = combfn(cs)
    # Obtener variaciones intermensuales promedio para las primeras 11 observaciones
    v_interm = mapreduce(inflfn -> inflfn(cs, CPIVarInterm()), hcat, combfn.ensemble.functions)::Matrix{eltype(cs)}
    v_mean_interm = v_interm * combfn.weights

    T = periods(cs)
    cpi_index = zeros(eltype(cs), T+1)
    cpi_index[1] = 100
    # Completar las primeras 11 variaciones intermensuales 
    cpi_index[2:12] .= capitalize(v_mean_interm[1:11])
    # Capitalizar utilizando las variaciones interanuales 
    for t = 13:T+1
        cpi_index[t] = (v_yoy[t-12]/100 + 1) * cpi_index[t-12]
    end
    cpi_index[2:end]
end

# Aplicación sobre CountryStructure: devuelve la combinación lineal en
# variaciones interanuales
function (combfn::CombinationFunction)(cst::CountryStructure)
    # Get ensemble and compute trajectories
    tray_infl = combfn.ensemble(cst)
    # Return weighted sum
    tray_infl * combfn.weights
end



## Métodos de ayuda

"""
    components(inflfn::CombinationFunction)

Devuelve un `DataFrame` con las componentes de la función de combinación lineal
y las ponderaciones asociadas.
"""
function components(inflfn::CombinationFunction)
    components = DataFrame(
        measure = measure_name(inflfn, return_array=true),
        weights = inflfn.weights
    )
    components
end