# Receta para graficar función de inflación con datos 

@recipe function plot(inflfn::InflationFunction, data::CountryStructure)
    
    # Computar trayectoria de inflación 
    traj_infl = inflfn(data)

    # Etiquetas para EnsembleFunction
    _label = inflfn isa EnsembleFunction ? 
        reshape(measure_name(inflfn), 1, :) : measure_name(inflfn)
    
    label --> _label
    legend --> :topright

    infl_dates(data), traj_infl
end