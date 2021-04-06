using DrWatson
@quickactivate "HEMI"

using Dates, CPIDataBase
using DataFrames

## Cargar datos de la base 2000 y 2010 del IPC 
using Dates, CSV, DataFrames
using CPIDataBase

# Base 2000
gt_base00 = CSV.read(datadir("guatemala", "Guatemala_IPC_2000.csv"), 
    DataFrame, normalizenames=true)
gt00gb = CSV.read(datadir("guatemala", "Guatemala_GB_2000.csv"), 
    DataFrame, types=[String, String, Float64])

gt00 = VarCPIBase(gt_base00, gt00gb)

# Base 2010
gt_base10 = CSV.read(datadir("guatemala", "Guatemala_IPC_2010.csv"), 
    DataFrame, normalizenames=true)
gt10gb = CSV.read(datadir("guatemala", "Guatemala_GB_2010.csv"), 
    DataFrame, types=[String, String, Float64])

gt10 = VarCPIBase(gt_base10, gt10gb)

## Guardar datos para su carga posterior
using JLD2

@save datadir("guatemala", "gtdata.jld2") gt00 gt10