"""
    HEMI

Módulo envolvente que carga los paquetes y datos utilizados en todo el proyecto.
"""
module HEMI

    using Reexport
    using DrWatson
    using StringEncodings
    @reexport using CSV
    @reexport using DataFrames

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
    fulldatafile = datadir("guatemala", "gtdata64.jld2")
    singledatafile = datadir("guatemala", "gtdata32.jld2")
    
    ## Estructuras de datos de Guatemala
    export FGT00, FGT10, GT00, GT10, GTDATA
    # Deprecated: use the uppercase variables
    export gt00, gt10, gtdata 
       
    function __init__()
        # Cargar los datos 
        @info "Exportando datos del IPC en variables `FGT00`, `FGT10`, `GT00`, `GT10`, `GTDATA`"
        load_data()
    end
    
    """
        load_data(; full_precision = false)

    Carga los datos del archivo principal de datos `HEMI.singledatafile`. Si los datos
    no están presentes, se cargan datos de prueba del archivo incluido por
    defecto, `HEMI.testdatafile`.
    - La opción `full_precision` permite cargar datos con precisión de 64 bits.
    - Archivo principal: `HEMI.singledatafile = datadir("guatemala",
      "gtdata32.jld2")`.
    - Archivo principal (64 bits): `HEMI.singledatafile = datadir("guatemala",
      "gtdata.jld2")`.
    """
    function load_data(; full_precision::Bool = false) 
        global fulldatafile, singledatafile, testdatafile 
        maindatafile = full_precision ? fulldatafile : singledatafile 
        if !isfile(maindatafile) 
            maindatafile = testdatafile
            @warn "Archivo principal de datos no encontrado. Ejecutar el script de actualización de datos `load_data.jl` y ejecutar `HEMI.load_data(). Cargando datos de prueba...`"
        end 

        @info "Cargando datos de Guatemala..."
        global FGT00, FGT10, GT00, GT10, GTDATA = load(maindatafile, "fgt00", "fgt10", "gt00", "gt10", "gtdata")

        # Deprecated
        global gt00 = GT00
        global gt10 = GT10
        global gtdata = GTDATA

        # Exportar datos del módulo 
        @info "Archivo de datos cargado" data=maindatafile GTDATA
    end

    # Función para guardar los resultados en un archivo CSV
    export save_csv
    function save_csv(file::AbstractString, df::DataFrame)
        encoding = enc"ISO-8859-1"
        @info "Saving file with $encoding" file
        open(file, encoding, "w") do io 
            CSV.write(io, df)
        end
    end

end