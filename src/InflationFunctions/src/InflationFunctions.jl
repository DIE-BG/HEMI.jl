"""
    InflationFunctions

Funciones para computar estimadores muestrales de inflación. 
"""
module InflationFunctions

    using CPIDataBase
    using Statistics

    ## Métodos a extender 
    import CPIDataBase: measure_name

    
    ## Percentiles equiponderados
    export Percentil
    include("percentiles_eq.jl")

    ## Desarrollo 

    include("dev/totalcpi_methods.jl")

end
