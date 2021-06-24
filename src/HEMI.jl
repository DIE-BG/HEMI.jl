module HEMI

    using Reexport
    using DrWatson

    ## Reexportar paquetes más utilizados 
    @reexport using Dates, CPIDataBase
    @reexport using Statistics
    @reexport using JLD2 

    ## Carga de datos de Guatemala
    @info "Cargando datos de Guatemala" _module=Main
    @load datadir("guatemala", "gtdata32.jld2") gt00 gt10
    gtdata = UniformCountryStructure(gt00, gt10)

    @show gtdata
    export gt00, gt10, gtdata

end