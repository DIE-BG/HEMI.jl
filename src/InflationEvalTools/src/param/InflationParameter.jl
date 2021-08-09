## Definiciones para obtener un parámetro de inflación 

"""
Tipo abstracto para representar los parámetros de inflación 
"""
abstract type AbstractInflationParameter{F <: InflationFunction, R <: ResampleFunction, T<: TrendFunction} end 

"""
Tipo concreto para representar un parámetro de inflación computado con la
función de inflación `inflfn`, el método de remuestreo `resamplefn` y función
de tendencia `trendfn`.

Ver también: [`ParamTotalCPIRebase`](@ref), [`ParamTotalCPI`](@ref), [`ParamWeightedMean`](@ref)
"""
Base.@kwdef struct InflationParameter{F, R, T} <: AbstractInflationParameter{F, R, T}
    inflfn::F = InflationTotalRebaseCPI()
    resamplefn::R = ResampleSBB(36)
    trendfn::T = TrendRandomWalk()
end

# Método para obtener la trayectoria paramétrica a partir de un CountryStructure
function (param::AbstractInflationParameter)(cs::CountryStructure)
    # Obtener la función para obtener los datos paramétricos (promedio) del método de remuestreo
    paramfn = get_param_function(param.resamplefn)
    # Computar un CountryStructure con datos paramétricos (promedio) 
    param_data = paramfn(cs)
    # Aplicamos la tendencia
    trended_data = param.trendfn(param_data)    
    # Aplicar la función de inflación para obtener la trayectoria paramétrica
    traj_infl_param = param.inflfn(trended_data)

    # Devolver la trayectoria de inflación paramétrica
    traj_infl_param
end

# Redefinir un método Base.show para InflationParameter
function Base.show(io::IO, param::AbstractInflationParameter)
    println(io, typeof(param))
    println(io, "|─> InflationFunction : " * measure_name(param.inflfn) )
    println(io, "|─> ResampleFunction  : " * method_name(param.resamplefn) )
    println(io, "|─> TrendFunction     : " * method_name(param.trendfn) )
end

method_tag(param::InflationParameter) = string("InflParam: [",nameof(param.inflfn),", ",nameof(param.resamplefn),", ",nameof(param.trendfn),"]")

"""
    DEFAULT_RESAMPLE_FN

Define la funcón de remuestreo a utilizar por defecto en el ejercicio de simulación.
"""
const DEFAULT_RESAMPLE_FN = ResampleSBB(36)


"""
    DEFAULT_TREND_FN

Define la funcón de tendencia a utilizar por defecto en el ejercicio de simulación.
"""
const DEFAULT_TREND_FN    = TrendRandomWalk()


"""
    ParamTotalCPIRebase()

Función de ayuda para obtener la configuración del parámetro de inflación dado
por la función de inflación del IPC con cambio de base sintético, y el método de
remuestreo y función de tendencia por defecto.
"""
ParamTotalCPIRebase() = 
    InflationParameter(InflationTotalRebaseCPI(60), DEFAULT_RESAMPLE_FN, DEFAULT_TREND_FN)

# Función para obtener el parámetro con otra función de remuestreo y otra función de tendencia.
ParamTotalCPIRebase(resamplefn::ResampleFunction, trendfn::TrendFunction) = 
    InflationParameter(InflationTotalRebaseCPI(60), resamplefn, trendfn)

"""
    ParamTotalCPI()

Función de ayuda para obtener la configuración del parámetro de inflación dado
por la función de inflación del IPC, y el método de remuestreo y función de
tendencia por defecto.
"""
ParamTotalCPI() = InflationParameter(InflationTotalCPI(), DEFAULT_RESAMPLE_FN, DEFAULT_TREND_FN)

# Función para obtener el parámetro con otra función de remuestreo y otra función de tendencia.
ParamTotalCPI(resamplefn::ResampleFunction, trendfn::TrendFunction) = 
    InflationParameter(InflationTotalCPI(), resamplefn, trendfn)


"""
    ParamTotalCPILegacyRebase()

Función de ayuda para obtener la configuración del parámetro de inflación dado
por la función de inflación del IPC con cambio de base sintético, y el método de
remuestreo y función de tendencia por defecto.
"""
ParamTotalCPILegacyRebase() = 
    InflationParameter(InflationTotalRebaseCPI(36, 2), ResampleScrambleVarMonths(), DEFAULT_TREND_FN)

# Función para obtener el parámetro con otra función de remuestreo y otra función de tendencia.
ParamTotalCPILegacyRebase(resamplefn::ResampleFunction, trendfn::TrendFunction) = 
    InflationParameter(InflationTotalRebaseCPI(36, 2), resamplefn, trendfn)

    
"""
    ParamWeightedMean()

Función de ayuda para obtener la configuración del parámetro de inflación dado
por la media ponderada interanual y el método de remuestreo por defecto.
"""
ParamWeightedMean() = InflationParameter(InflationWeightedMean(), DEFAULT_RESAMPLE_FN, DEFAULT_TREND_FN)

# Función para obtener el parámetro con otra función de remuestreo y otra
# función de tendencia.
ParamWeightedMean(resamplefn::ResampleFunction, trendfn::TrendFunction) = 
    InflationParameter(InflationWeightedMean(), resamplefn, trendfn)
