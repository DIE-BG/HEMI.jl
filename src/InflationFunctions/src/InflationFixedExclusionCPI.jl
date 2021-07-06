# InflationFixedExclusionCPI.jl - Función de inflación de exculsión fija de gastos básicos

## Utilización
"""
    (inflfn::InflationFixedExclusionCPI)(base::VarCPIBase{T}) where T 
Define cómo opera InflationFixedExclusionCPI sobre un objeto de tipo VarCPIBase, 
con listas de exclusión para las bases 2000 y 2010.
"""
# 1. Definir un tipo
"""
    InflationFixedExclusionCPI <: InflationFunction
Función de inflación para computar la inflación de exclusión fija de gastos básicos.
"""
Base.@kwdef struct InflationFixedExclusionCPI <: InflationFunction
    # Tupla con vectores de gastos básicos a exlcuir en cada base (tantos vectores como bases)
    v_exc::Tuple{Vector{Int64}, Vector{Int64}}
end

# 2. Extender el método de nombre 
measure_name(::InflationFixedExclusionCPI) = "Exclusión Fija de Gastos Básicos"


function (inflfn::InflationFixedExclusionCPI)(base::VarCPIBase{T}) where T 
    # Elección del vector a utilizar, basado en la cantidad de gastos básicos en la base (dim 2)
    if size(base.v)[2] == 218 exc = inflfn.v_exc[1] else exc = inflfn.v_exc[2] end   
    # Capitalizar los índices de precios a partir del objeto base::VarCPIBase
    base_ipc= capitalize(base.v, base.baseindex)
    # Copia de la lista original de pesos desde cs.base[i]
    w_exc = copy(base.w)
    # Asignación de peso cero a los gastos básicos de la lista de exclusión (v_exc[i]) 
    # (j itera sobre los elementos de la lista de exclusión)
        for j in exc w_exc[j] = 0.0 end
    # Renormalización de pesos
    w_exc = w_exc / sum(w_exc)
    # Obtener Ipc con exclusión 
    cpi_exc = sum(base_ipc.*w_exc', dims=2)
    # Obtener variación intermensual
    varm_cpi_exc =  varinterm(cpi_exc)
end

##  PARA DEFINIR COMO OPERA LA FUNCIÓN DE INFLACIÓN SOBRE COUNTRYSTRUCTURE 

# Aplicar cada lista de exclusión con su base correspondiente en el CountryStructure
function (inflfn::InflationFixedExclusionCPI)(cs::CountryStructure, ::CPIVarInterm) 
     # Acá se llama a inflfn(base), en donde base es de tipo VarCPIBase. Esta
     # es la función que debe definirse para cualquier medida de inflación.
     vm = mapfoldl(inflfn, vcat, cs.base)
     vm
end