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
    fulldatafile = datadir("guatemala", "gtdata.jld2")
    datafile = datadir("guatemala", "gtdata32.jld2")
    
    ## Estructuras de datos de Guatemala
    export gt00, gt10, gtdata
       
    function __init__()
        # Cargar los datos 
        load_data()
        @info "Exportando datos en variables `gt00`, `gt10`, `gtdata`"
    end
    
    """
        load_data(; full_precision = false)

    Carga los datos del archivo principal de datos `HEMI.datafile`. Si los datos
    no están presentes, se cargan datos de prueba del archivo incluido por
    defecto, `HEMI.testdatafile`.
    - La opción `full_precision` permite cargar datos con precisión de 64 bits.
    - Archivo principal: `HEMI.datafile = datadir("guatemala",
      "gtdata32.jld2")`.
    - Archivo principal (64 bits): `HEMI.datafile = datadir("guatemala",
      "gtdata.jld2")`.
    """
    function load_data(; full_precision::Bool = false) 
        global fulldatafile, datafile, testdatafile 
        maindatafile = full_precision ? fulldatafile : datafile 
        if !isfile(maindatafile) 
            maindatafile = testdatafile
            @warn "Archivo principal de datos no encontrado. Ejecutar el script de actualización de datos `load_data.jl` y ejecutar `HEMI.load_data(). Cargando datos de prueba...`"
        end 

        @info "Cargando datos de Guatemala..."
        global gt00, gt10 = load(maindatafile, "gt00", "gt10")
        global gtdata = UniformCountryStructure(gt00, gt10)

        # Exportar datos del módulo 
        @info "Archivo de datos cargado" data=maindatafile gtdata
    end

end