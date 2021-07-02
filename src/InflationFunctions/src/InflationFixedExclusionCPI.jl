# InflationFixedExclusionCPI.jl - Función de inflación de exculsión fija de gastos básicos

# 1. Definir un tipo
"""
    InflationFixedExclusionCPI <: InflationFunction
Función de inflación para computar la inflación de exclusión fija de gastos básicos.
"""
Base.@kwdef struct InflationFixedExclusionCPI <: InflationFunction
    # Tupla con vectores de gastos básicos a exlcuir en cada base 
    # (deberá tener la misma cantidad de vectores que bases en el CountryStructure)
    v_exc::NTuple{2,Vector{Int64}} 

end

# 2. Extender el método de nombre 
measure_name(::InflationFixedExclusionCPI) = "Inflación de Exclusión Fija de Gastos Básicos"

"""
    (inflfn::InflationFixedExclusionCPI)(base::UniformCountryStructure, v_exc)
Define cómo opera InflationFixedExclusionCPI sobre un objeto de tipo CountryStructure, 
con listas de exclusión para las bases 2000 y 2010.
PROBLEMAS: los objetos base_ipc, w_exc, cpi_exc y varm_cpi_exc ¿debieran ser tuplas?, ¿Debó crearlas antes?
"""
function (inflfn::InflationFixedExclusionCPI)(cs::UniformCountryStructure, v_exc)
    # Iteración sobre la cantidad de bases en cs 
    for i in 1:length(cs.base)
    # Capitalizar los índices de precios a partir del objeto cs.VarCPIBase[i]
    base_ipc[i] = capitalize(cs.base[i].v, cs.base[i].baseindex)
    # Copia de la lista original de pesos desde cs.base[i]
    w_exc[i] = copy(cs.base[i].w)
    # Asignación de peso cero a los gastos básicos de la lista de exclusión (v_exc[i]) 
    # (j itera sobre los elementos de la lista de exclusión)
        for j in inflfn.v_exc[i] w_exc[i][j] = 0.0 end
    # Renormalización de pesos
    w_exc[i] = w_exc[i] / sum(w_exc[i])
    # Obtener Ipc con exclusión 
    cpi_exc[i] = sum(base_ipc[i].*w_exc[i]', dims=2)
    # Obtener variación intermensual
    varm_cpi_exc[i] =  varinterm(cpi_exc[i])
    end
 varm_cpi_exc 
end
## PARA DEFINIR COMO OPERA LA FUNCIÓN DE INFLACIÓN SOBRE COUNTRYSTRUCTURE 
# OJO AQUI

# Aplicar cada lista de exclusión con su base correspondiente en el CountryStructure
# function (inflfn::InflationFixedExclusionCPI)(cs::CountryStructure, ::CPIVarInterm) 
#     # Acá se llama a inflfn(base), en donde base es de tipo VarCPIBase. Esta
#     # es la función que debe definirse para cualquier medida de inflación.
#     vm = mapfoldl(inflfn, vcat, cs.base)
#     vm
# end