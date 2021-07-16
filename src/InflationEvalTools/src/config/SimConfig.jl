# SimConfig.jl - Definición de tipos contenedores para parámetros de simulación
using DrWatson
import Base: show, summary

# Tipo Abstracto para contenedores de parámetros de Simulación
abstract type AbstractConfig{F <: InflationFunction, R <:ResampleFunction, T <:TrendFunction} end

# Tipo para representar los parámetros necesarios para generar la simulación de la forma que se hizo hasta 2020

Base.@kwdef struct SimConfig{F, R, T} <:AbstractConfig{F, R, T}
    # Función de Inflación
    inflfn::F
    # Función de remuestreo
    resamplefn::R
    # Función de Tendencia
    trendfn::T
    # Cantidad de Simulaciones
    nsim::Int  
end

# Tipo para representar los parámetros necesarios para generar la simulación con períodos de evaluación dentro de la muestra
Base.@kwdef struct CrossEvalConfig{F, R, T} <:AbstractConfig{F, R, T}
    # Función de Inflación
    inflfn::F
    # Función de remuestreo
    resamplefn::R
    # Función de Tendencia
    trendfn::T
    # Cantidad de simulaciones
    nsim::Int
    # Último mes de set de "entrenamiento"
    train_date::Date   
    # Tamaño del período de evaluación en meses 
    eval_size::Int 
end


# Configuraciones necesarias para mostrar nombres de funciones en savename
Base.string(inflfn::InflationFunction) = measure_name(inflfn)
Base.string(resamplefn::ResampleFunction) = method_tag(resamplefn)
Base.string(trendfn::TrendFunction) = method_tag(trendfn)

# Base.showaxis
function show(io::IO, config::AbstractConfig)

        println(io, "|─> ", sprint(show, string("Función de Inflación:"," ",measure_name(config.inflfn))))
        println(io, "|─> ", sprint(show, string("Función de Remuestreo:"," ",method_tag(config.resamplefn))))
        println(io, "|─> ", sprint(show, string("Función de Tendencia:"," ",method_tag(config.trendfn))))
        println(io, "|─> ", sprint(show, string("Cantidad de Simuaciones:", " ", config.nsim)))
        if typeof(config) == CrossEvalConfig{typeof(config.inflfn),typeof(config.resamplefn), typeof(config.trendfn)} 
            println(io, "|─> ", sprint(show, string("Fin Set de entrenamiento:", " ", config.train_date)))
            println(io, "|─> ", sprint(show, string("Meses de evaluación:", " ", config.eval_size)))
        end
end




# # Extender definición de tipos permitidos para simulación
DrWatson.default_allowed(::AbstractConfig) = (String, Symbol, TimeType, Function, Real) 
DrWatson.default_prefix(::AbstractConfig) = "HEMI"

## método para convertir de AbstractConfig a Diccionario 
# Esto lo hace la función struct2dict() de DrWatson

# function convert_dict(config::AbstractConfig)
   
#     if typeof(config) == SimConfig{typeof(config.inflfn),typeof(config.resamplefn), typeof(config.trendfn)}
#         # Convertir SimConfig a Diccionari
#         dict = Dict(:inflfn => config.inflfn, :resamplefn => config.resamplefn, :trendfn => config.trendfn, :nsim => config.nsim)     
    
#     elseif typeof(config) == CrossEvalConfig{typeof(config.inflfn),typeof(config.resamplefn), typeof(config.trendfn)} 
#         # Convertir CrossEvalConfig a Diccionario
#         dict = Dict(:inflfn => config.inflfn, :resamplefn => config.resamplefn, :trendfn => config.trendfn, 
#                     :nsim => config.nsim, :train_date => config.train_date, :eval_size => config.eval_size)    
    
#     end
#     dict
# end

