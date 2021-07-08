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

    ## Carga de datos de Guatemala
    datafile = datadir("guatemala", "gtdata32.jld2")
    @show datafile
    if isfile(datafile)
        @info "Cargando datos de Guatemala" _module=Main
        @load datafile gt00 gt10
        gtdata = UniformCountryStructure(gt00, gt10)

        # Exportar datos del módulo 
        @show gtdata
        export gt00, gt10, gtdata
    else
        @warn "Correr el script de carga de datos antes de cargar paquete HEMI"
    end
end