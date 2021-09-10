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
        # Datos de prueba del proyecto 
        testdata = datadir("guatemala", "gtdata32_test.jld2")
        # Archivo de datos principales 
        datafile = datadir("guatemala", "gtdata32.jld2")

        if !isfile(datafile) 
            datafile = testdata
            @warn "Correr el script de actualización de datos `load_data.jl` y ejecutar `HEMI.__init__()`"
        end 
        
        @info "Cargando datos de Guatemala..."
        global gt00, gt10 = load(datafile, "gt00", "gt10")
        global gtdata = UniformCountryStructure(gt00, gt10)

        # Exportar datos del módulo 
        @info "Archivo de datos cargado" data=datafile gtdata
            
    end
    
end