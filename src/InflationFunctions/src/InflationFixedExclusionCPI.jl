# InflationFixedExclusionCPI.jl - Función de inflación de exculsión fija de gastos básicos

# 1. Definir un tipo
"""
    InflationFixedExclusionCPI <: InflationFunction
Función de inflación para computar la inflación de exclusión fija de gastos básicos.
"""
Base.@kwdef struct InflationFixedExclusionCPI <: InflationFunction
    # Dos vectores, uno por base
    f_exc::Vector{Int64} # Vector con Gastos básicos a excluir (que tipo, vector de posiciones o vector de códigos de gb???)
end

# 2. Extender el método de nombre 
measure_name(::InflationFixedExclusionCPI) = "Inflación de Exclusión Fija de Gastos Básicos"

"""
    (inflfn::InflationFixedExclusionCPI)(base::VarCPIBase)
Define cómo opera InflationFixedExclusionCPI sobre un objeto de tipo VarCPIBase.
"""
function (inflfn::InflationFixedExclusionCPI)(base::VarCPIBase, f_exc)
    # Capitalizar los índices de precios a partir del objeto VarCPIBase
    base_ipc = capitalize(base.v, base.baseindex)
    # Asignación de peso cero a los gastos básicos de la lista de exclusión (f_exc)
    w_exc = copy(base.w)
    for i in inflfn.f_exc w_exc[i] = 0 end
    # Renormalización de pesos
    w_exc = w_exc / sum(w_exc)
    # Obtener Ipc 
        # Obtener el IPC del mes de manera normal (y ¿aplicar función de inflación total?). cpi_exc = cpi_mat * w_exc
        #sum(gt10.v, dims=2)
        ## DEVOLVER VARIACIONES INTERMENSUALES E INDICES CONCATENADOS PARA AMBAS BASES

end 

## PARA DEFINIR COMO OPERA LA FUNCIÓN DE INFLACIÓN SOBRE COUNTRYSTRUCTURE 
# OJO AQUI
function (inflfn::InflationFixedExclusionCPI)(cs::CountryStructure, ::CPIVarInterm) 
    # Acá se llama a inflfn(base), en donde base es de tipo VarCPIBase. Esta
    # es la función que debe definirse para cualquier medida de inflación.
    vm = mapfoldl(inflfn, vcat, cs.base)
    vm
end