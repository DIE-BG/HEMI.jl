# ## InflationFixedExclusion.jl - Función de inflación de exclusión fija de gastos básicos sin utilizar fórmula de inflación IPC


"""
    InflationFixedExclusion{N} <: InflationFunction

Función de inflación para computar la inflación de exclusión fija de gastos
básicos para `N` bases del IPC. Esta versión no utiliza la fórmula del IPC, como
la función de inflación `InflationFixedExclusionCPI`.

## Utilización

    function (inflfn::InflationFixedExclusion)(base::VarCPIBase{T}, i::Int) where T 

Define cómo opera InflationFixedExclusion sobre un objeto de tipo `VarCPIBase`,
con `i` listas de exclusión de gastos básicos (posiciones en el IPC) para las
bases 2000 y 2010.

    function (inflfn::InflationFixedExclusion)(cs::CountryStructure, ::CPIVarInterm) 

Define cómo opera InflationFixedExclusion sobre un CountryStructure

## Ejemplos

Instanciamos la función y le damos dos listas de exclusión, una por cada base en
el CountryStructure. Se exclyen los gastos básicos con números de columnas
`[25,30,54,88]` del primer `VarCPIBase` y los gastos básicos `[65,95,85]` del
segundo `VarCPIBase`.
```julia-repl 
julia> InfExc = InflationFixedExclusion([25,30,54,88], [65,95,85]) 
(::InflationFixedExclusion{2}) (generic function with 6 methods)
```

"""
Base.@kwdef struct InflationFixedExclusion{N} <: InflationFunction
    # Tupla con vectores de gastos básicos a excluir en cada base (tantos vectores como bases)
    v_exc::NTuple{N,Vector{Int}}
end

# Ampliación para que reciba solo los vectores, no necesariamente como una tupla.
InflationFixedExclusion(v_exc...) = InflationFixedExclusion(v_exc)

# Extender el método de nombre y de tag
measure_name(inflfn::InflationFixedExclusion) = "Exclusión fija de gastos básicos " * string(map(length, inflfn.v_exc))

# Método para obtener parámetros
params(inflfn::InflationFixedExclusion) = inflfn.v_exc

# Cómputo del resumen intermensual utilizando la lista de exclusión i
function (inflfn::InflationFixedExclusion)(base::VarCPIBase{T}, i::Int) where T 
    # Elección del vector de exclusión a utlizar dependiendo de que base se está tomando 
    # 1 -> base 2000, 2-> base 2010 (se puede generalizar para más bases)  
    exc = inflfn.v_exc[i]
    # creación de una copia de la lista original de pesos desde base.w
    w_exc = copy(base.w)
    # Asignación de peso cero a los gastos básicos de la lista de exclusión (exc = inflfn.v_exc[i]) 
    w_exc[exc] .= 0
    # Renormalización de pesos
    w_exc = w_exc / sum(w_exc)
    # Obtener variación intermensual
    base.v * w_exc
end


# Redefinición del método para obtener variaciones intermensuales del CountryStructure
function (inflfn::InflationFixedExclusion)(cs::CountryStructure, ::CPIVarInterm) 
    # Acá se llama a inflfn(base, i), en donde base es de tipo VarCPIBase e i es la posición del vector de exclusión. 
    # Esta es la función que debe definirse para cualquier medida de inflación.
    l = length(cs.base)
    vm = mapfoldl(i -> inflfn(cs.base[i],i), vcat, 1:l)
    vm
end


