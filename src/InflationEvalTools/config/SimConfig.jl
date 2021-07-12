using DrWatson: Dates
using DrWatson
@quickactivate :HEMI 

using InflationEvalTools
using InflationEvalTools: ResampleFunction

## Crear el tipo y extender definiciones 

# Tipo para representar los parámetros necesarios para generar la simulación
Base.@kwdef struct SimConfig
    inflfn::F
    resamplefn::R
    trendfn::TrendFunction
    nsim::Int
    final_date::DATETYPE   
end

# Configuraciones necesarias para mostrar nombres de funciones en savename
Base.string(inflfn::InflationFunction) = measure_tag(inflfn)
Base.string(inflfn::ResampleFunction) = method_name(inflfn)

# Extender definición de tipos permitidos para simulación
DrWatson.default_allowed(::SimConfig) = (Real, String, Symbol, TimeType, Function)
DrWatson.default_prefix(::SimConfig) = "HEMI"