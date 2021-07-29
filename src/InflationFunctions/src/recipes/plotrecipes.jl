# Receta para graficar función de inflación con datos 

@recipe function plot(inflfn::InflationFunction, data::CountryStructure)
    
    # Computar trayectoria de inflación 
    traj_infl = inflfn(data)

    label --> measure_name(inflfn)
    legend --> :topright

    infl_dates(data), traj_infl
end