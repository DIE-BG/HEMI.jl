"""
    CPIDataBase

Librería base para tipos y funcionalidad básica para manejo de datos del IPC a
nivel desagregado de gastos básicos
"""
module CPIDataBase

    using Dates
    using DataFrames

    # Exportar tipos
    export IndexCPIBase, VarCPIBase, FullCPIBase
    export CountryStructure, UniformCountryStructure, MixedCountryStructure

    # Exportar funciones
    export capitalize, varinterm, varinteran, 
        capitalize!, varinterm!, varinteran!, 
        periods, infl_periods, infl_dates,
        getunionalltype

    # Exportar tipos para implementar nuevas funciones de inflación
    export InflationFunction, EnsembleInflationFunction
    export EnsembleFunction, CombinationFunction
    export InflationEnsemble, InflationCombination # alias de los 2 anteriores
    export components # componentes de una InflationCombination
    export num_measures, weights, measure_name, measure_tag, params

    # Exportar tipos necesarios para especificar tipos de los resultados 
    export CPIIndex, CPIVarInterm

    # Función básica de inflación 
    export InflationTotalCPI

    # Definición de tipos para bases del IPC
    include("CPIBase.jl")
    include("CountryStructure.jl")

    # Operaciones básicas
    include("utils/capitalize.jl")
    include("utils/varinterm.jl")
    include("utils/varinteran.jl")

    # Estructura básica para medidas de inflación 
    include("inflation/InflationFunction.jl")
    include("inflation/EnsembleFunction.jl")
    include("inflation/CombinationFunction.jl")

    # Medida de inflación básica 
    include("inflation/InflationTotalCPI.jl")

    # Funciones de utilidad
    export getdates
    include("utils/utils.jl")

    
    # Submódulo con funciones relacionadas con los tipos de este paquete para
    # realizar pruebas en paquetes que extiendan la funcionalidad. Este módulo
    # no se exporta por defecto, requiere carga explícita (e.g using
    # CPIDataBase.TestHelpers)
    module TestHelpers
        using Dates, ..CPIDataBase    
        
        export getrandomweights, getbasedates, 
            getzerobase, getzerocountryst

        include("test/test_helpers.jl")
    end

end # module
