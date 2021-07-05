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
function (inflfn::InflationFixedExclusionCPI)(cs::UniformCountryStructure)#, v_exc::NTuple{2,Vector{Int64}})
    varm_cpi_exc00 = []
    varm_cpi_exc10 = []
    # Iteración sobre la cantidad de bases en cs 
    for i in 1:length(cs.base)
    # Capitalizar los índices de precios a partir del objeto cs.VarCPIBase[i]
    base_ipc= capitalize(cs.base[i].v, cs.base[i].baseindex)
    # Copia de la lista original de pesos desde cs.base[i]
    w_exc = copy(cs.base[i].w)
    # Asignación de peso cero a los gastos básicos de la lista de exclusión (v_exc[i]) 
    # (j itera sobre los elementos de la lista de exclusión)
        for j in inflfn.v_exc[i] w_exc[j] = 0.0 end
    # Renormalización de pesos
    w_exc = w_exc / sum(w_exc)
    # Obtener Ipc con exclusión 
    cpi_exc = sum(base_ipc.*w_exc', dims=2)
    # Obtener variación intermensual
    varm_cpi_exc =  varinterm(cpi_exc)
    # Guardar elementos
        if i == 1
            varm_cpi_exc00 = varm_cpi_exc 
        else
            varm_cpi_exc10 = varm_cpi_exc 
        end
    end
    vcat(varm_cpi_exc00, varm_cpi_exc10)
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