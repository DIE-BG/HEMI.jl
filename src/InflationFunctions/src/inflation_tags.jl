# Definición para etiquetas de medidas de inflación 

# Media simple 
measure_tag(::InflationSimpleMean) = "SM"

# Exclusión fija de gastos básicos 
measure_tag(inflfn::InflationFixedExclusionCPI) = "FxEx" * string(hash(inflfn.v_exc)) 
