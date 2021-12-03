# Definición para etiquetas de medidas de inflación 

# Media simple 
measure_tag(::InflationSimpleMean) = "SM"

# Media Ponderada
measure_tag(::InflationWeightedMean) = "WM"

# Exclusión fija de gastos básicos 
measure_tag(inflfn::InflationFixedExclusionCPI) = "FxEx-" * string(map(length, inflfn.v_exc))
measure_tag(inflfn::InflationFixedExclusion) = "FxEx-" * string(map(length, inflfn.v_exc))

# Percentiles Equiponderados
measure_tag(inflfn::InflationPercentileEq) = "PerEq-" * string(round(100inflfn.k, digits=2))

# Percentiles Ponderados
measure_tag(inflfn::InflationPercentileWeighted) = "PerW-" * string(round(100inflfn.k, digits=2))

# Media Truncada Equponderada  
function measure_tag(inflfn::InflationTrimmedMeanEq)
    l1 = string(round(inflfn.l1, digits=2))
    l2 = string(round(inflfn.l2, digits=2))
    "MTEq-(" * l1 * "," * l2 * ")"
end

# Media Truncada Ponderada  
function measure_tag(inflfn::InflationTrimmedMeanWeighted)
    l1 = string(round(inflfn.l1, digits=2))
    l2 = string(round(inflfn.l2, digits=2))
    "MTW-(" * l1 * "," * l2 * ")"
end

# Exclusión Dinámica
function CPIDataBase.measure_tag(inflfn::InflationDynamicExclusion)
    round_lower_factor, round_upper_factor = string.(
        round.(
            [inflfn.lower_factor, inflfn.upper_factor], digits = 2
        )
    )
    "DynEx($(round_lower_factor),$(round_upper_factor))"
end

# Función de inflación total con cambio de base sintético.  (TotalRebaseCPI)
measure_tag(inflfn::InflationTotalRebaseCPI) = "TRB-($(inflfn.period),$(inflfn.maxchanges))"

# MAI 
measure_tag(inflfn::InflationCoreMai) = "MAI" * string(inflfn.method)

# Wrapper de medias móviles y suavizamiento exponencial 
measure_tag(mafn::InflationMovingAverage) = "MA$(mafn.periods)_" * measure_tag(mafn.inflfn)
measure_tag(esfn::InflationExpSmoothing) = "ES$(round(esfn.alpha, digits=4))_" * measure_tag(esfn.inflfn)

# Inflación constante 
measure_tag(inflfn::InflationConstant) = "C" * string(round(inflfn.c, digits=2))
