module InflationEvalTools

using CPIDataBase
using Random
using ProgressMeter
using Distributed
using SharedArrays
using Reexport

## Funciones de generación de trayectorias
export gentrayinfl, pargentrayinfl

include("gentrayinfl.jl")
include("pargentrayinfl.jl")

## Módulo de remuestreo
include("Resample.jl")
@reexport using .Resample

## Funciones en desarrollo 
include("dev/dev_pargentrayinfl.jl")

## Módulo de desarrollo experimental
export Devel
module Devel
    # Development functions

end

end
