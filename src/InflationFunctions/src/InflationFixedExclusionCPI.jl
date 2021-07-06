# ## InflationFixedExclusionCPI.jl - Función de inflación de exculsión fija de gastos básicos


"""
## 1. Definir un tipo
    InflationFixedExclusionCPI{N} <: InflationFunction
Función de inflación para computar la inflación de exclusión fija de gastos básicos para N bases.

## 2. Utilización
(inflfn::InflationFixedExclusionCPI)(base::VarCPIBase{T}, i::Int) where T
Define cómo opera InflationFixedExclusionCPI sobre un objeto de tipo VarCPIBase, 
con i listas de exclusión de gastos básicos (posiciones en el IPC) para las bases 2000 y 2010.

function (inflfn::InflationFixedExclusionCPI)(cs::CountryStructure, ::CPIVarInterm) 
    Define cómo opera InflationFixedExclusionCPI sobre un CountryStructure


    ##3. Ejemplos
Instanciamos la función y le damos dos listas de exclusión, una por cada base en el CountryStructure.
InfExc = InflationFixedExclusionCPI([25,30,54,88],[65,95,85])
InfExc(gt10, 2), cuando gt10 es un VarCPIBase para la base 2010 y su vector de exclusión es el segundo de la lista.
InfExc(gt00, 1), cuando gt00 es un VarCPIBase para la base 2000 y su vector de exclusión es el primero de la lista.
InfExc(gtdata), cuando gtdata es un CountryStructure.
"""

# Definir el tipo InflationFunction
Base.@kwdef struct InflationFixedExclusionCPI{N} <: InflationFunction
    # Tupla con vectores de gastos básicos a exlcuir en cada base (tantos vectores como bases)
    v_exc::NTuple{N,Vector{Int}}
end

# Ampliación para que reciba solo los vectores, no necesariamente como una tupla.
InflationFixedExclusionCPI(v_exc...) = InflationFixedExclusionCPI(v_exc)

# Extender el método de nombre 
measure_name(::InflationFixedExclusionCPI) = "Exclusión Fija de Gastos Básicos"


function (inflfn::InflationFixedExclusionCPI)(base::VarCPIBase{T}, i::Int) where T 
    # Elección del vector de exclusión a utlizar dependiendo de que base se está tomando 
    # 1 -> base 2000, 2-> base 2010 (se puede generalizar para más bases)  
    exc = inflfn.v_exc[i]
    # Capitalizar los índices de precios a partir del objeto base::VarCPIBase
    base_ipc= capitalize(base.v, base.baseindex)
    # creación de una copia de la lista original de pesos desde base.w
    w_exc = copy(base.w)
    # Asignación de peso cero a los gastos básicos de la lista de exclusión (exc = inflfn.v_exc[i]) 
    # (j itera sobre los elementos de la lista de exclusión)
        for j in exc w_exc[j] = 0 end
    # Renormalización de pesos
    w_exc = w_exc / sum(w_exc)
    # Obtener Ipc con exclusión 
    cpi_exc = base_ipc*w_exc
    # Obtener variación intermensual
    varm_cpi_exc =  varinterm(cpi_exc)
end

function (inflfn::InflationFixedExclusionCPI)(cs::CountryStructure, ::CPIVarInterm) 
    # Acá se llama a inflfn(base, i), en donde base es de tipo VarCPIBase e i es la posición del vector de exclusión. 
    # Esta es la función que debe definirse para cualquier medida de inflación.
    l = length(cs.base)
    vm = mapfoldl(i -> inflfn(cs.base[i],i), vcat, 1:l)
    vm
end