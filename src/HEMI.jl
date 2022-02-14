"""
    HEMI

Módulo envolvente que carga los paquetes y datos utilizados en todo el proyecto.
"""
module HEMI

    using Reexport
    using DrWatson

    ## Reexportar paquetes más utilizados 
    @reexport using Dates, CPIDataBase
    @reexport using CPIDataGT
    @reexport using Statistics
    @reexport using JLD2 

    # Reexportar funciones de inflación y de evaluación 
    @reexport using InflationFunctions
    @reexport using InflationEvalTools

end