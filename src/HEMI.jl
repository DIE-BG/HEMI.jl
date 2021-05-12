module HEMI

    using Reexport
    using DrWatson

    ## Reexportar paquetes
    @reexport using Dates, CPIDataBase
    @reexport using Statistics, StatsBase
    @reexport using JLD2 
    @reexport using Plots

    ## Carga de datos 
    @info "Cargando datos de Guatemala" _module=Main
    @load datadir("guatemala", "gtdata32.jld2") gt00 gt10
    gtdata = UniformCountryStructure(gt00, gt10)

    @show gtdata
    export gt00, gt10, gtdata

end