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

    ## Variación interanual IPC con cambio de base sintético 
    export TotalRebaseCPI
    include("total_cpi_rebase.jl")

    ## Desarrollo 

    include("dev/totalcpi_methods.jl")

end
