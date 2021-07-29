"""
    HEMI

Módulo envolvente que carga los paquetes y datos utilizados en todo el proyecto.
"""
module HEMI

    using Reexport
    using DrWatson

    ## Reexportar paquetes más utilizados 
    @reexport using Dates, CPIDataBase
    @reexport using Statistics
    @reexport using JLD2 

    # Reexportar funciones de inflación y de evaluación 
    @reexport using InflationFunctions
    @reexport using InflationEvalTools

    ## Carga de datos de Guatemala
    export gt00, gt10, gtdata
    
    function __init__()
        datafile = datadir("guatemala", "gtdata32.jld2")
        @info "Ruta del archivo de datos" datafile
        
        # Si el archivo está presente, cargarlo 
        if isfile(datafile)
            # @info "Cargando datos de Guatemala"
            global gt00, gt10 = load(datafile, "gt00", "gt10")
            global gtdata = UniformCountryStructure(gt00, gt10)

            # Exportar datos del módulo 
            @info "Archivo de datos cargado" gtdata
        else
            @warn "Correr el script de carga de datos `load_data.jl` y ejecutar `HEMI.__init__()`"
        end
    end
    
end