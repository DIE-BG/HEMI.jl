module InflationFunctions

# import CPIDataBase: InflationFunction
# import CPIDataBase: EnsembleFunction, CombinationFunction

using CPIDataBase
using Statistics

# Métodos a extender 
import CPIDataBase: measure_name

export Percentil

# Percentiles equiponderados
include("percentiles_eq.jl")

end
