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

    # Datos de prueba del proyecto 
    testdatafile = datadir("guatemala", "gtdata32_test.jld2")
    # Archivo de datos principales 
    datafile = datadir("guatemala", "gtdata32.jld2")
    
    ## Estructuras de datos de Guatemala
    export gt00, gt10, gtdata
       
    function __init__()
        # Cargar los datos 
        load_data(datafile, testdatafile)
        @info "Exportando datos en variables `gt00`, `gt10`, `gtdata`"
    end
    
    function load_data(maindatafile=datafile, testdatafile=testdatafile) 
        if !isfile(maindatafile) 
            maindatafile = testdatafile
            @warn "Correr el script de actualización de datos `load_data.jl` y ejecutar `HEMI.load_data()`"
        end 

        @info "Cargando datos de Guatemala..."
        global gt00, gt10 = load(maindatafile, "gt00", "gt10")
        global gtdata = UniformCountryStructure(gt00, gt10)

        # Exportar datos del módulo 
        @info "Archivo de datos cargado" data=maindatafile gtdata
    end

end