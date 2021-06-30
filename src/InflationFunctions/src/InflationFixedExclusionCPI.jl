# InflationFixedExclusionCPI.jl - Función de inflación de exculsión fija de gastos básicos

# 1. Definir un tipo
"""
    InflationFixedExclusionCPI <: InflationFunction
Función de inflación para computar la inflación de exclusión fija de gastos básicos.
"""
Base.@kwdef struct InflationFixedExclusionCPI <: InflationFunction
    f_exc::Vector{Float64} # Vector con Gastos básicos a excluir (que tipo, verctor de posiciones o vector de códigos de gb???)
end

# 2. Extender el método de nombre 
measure_name(::InflationFixedExclusionCPI) = "Inflación de Exclusión Fija de Gastos Básicos"

"""
    (inflfn::InflationFixedExclusionCPI)(base::FullCPIBase)
Define cómo opera InflationFixedExclusionCPI sobre un objeto de tipo FullCPIBase.
"""
function (inflfn::InflationFixedExclusionCPI)(base::FullCPIBase)
    # Obtener el filtro de los gastos básicos
        # un filtro tipo ismember para obtener un vector de ceros y unos.  f = ~ismember(1:length(w), f_exc) 
    # Ponderaciones Filtradas
        # Multiplicar FullCPIBase.w por el vector de ceros y unos filtrados para hacer cero los pesos a excluir w_exc = w.*f 
    # Renormalización
        # Renormalizar los pesos una vez excluidos los precios seleccionados en f_exc. w_exc = w_exc / sum(w_exc)
    # Obtener Ipc 
        # Obtener el IPC del mes de manera normal (y ¿aplicar función de inflación total?). cpi_exc = cpi_mat * w_exc


end 