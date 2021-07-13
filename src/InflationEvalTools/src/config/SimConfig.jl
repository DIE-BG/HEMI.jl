#using DrWatson: Dates
using DrWatson

#using InflationEvalTools

## Crear el tipo y extender definiciones 
# abstract type SimConfig{} end
abstract type AbstractConfig{F, R, T} end

# Tipos para los vectores de fechas
# const DATETYPE = StepRange{Date, Month}

# Tipo para representar los parámetros necesarios para generar la simulación
# Hasta 2019
struct SimConfig{F , R , T} <:AbstractConfig{F, R, T} #Base.@kwdef 
    inflfn::F
    resamplefn::R
    trendfn::TrendFunction
    nsim::Int
    #final_date::DATETYPE   
end

#CrossEvalConfig

# Configuraciones necesarias para mostrar nombres de funciones en savename
# Base.string(inflfn::InflationFunction) = measure_tag(inflfn)
# Base.string(inflfn::ResampleFunction) = method_name(inflfn)

# # Extender definición de tipos permitidos para simulación
# DrWatson.default_allowed(::SimConfig) = (Real, String, Symbol, TimeType, Function)
# DrWatson.default_prefix(::SimConfig) = "HEMI"