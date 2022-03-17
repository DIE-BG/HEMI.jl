using DrWatson
@quickactivate :HEMI 
using JLD2

## Funciones de optimización
include(scriptsdir("core-no-trans", "optimfns.jl"))

## Directorios de resultados
data_savepath = mkpath(datadir("results", "core-no-trans", "data"))

## Set up data
no_trans_2010 = [100,107,108,110,112:114...,155,156,170:177...,187:198...,200:205...,223:229...,231:233...,236:252...,273:279...]

NOT_FGT10 = FullCPIBase(
    FGT10.ipc[:, no_trans_2010],
    FGT10.v[:, no_trans_2010],
    100 * FGT10.w[no_trans_2010] / sum(FGT10.w[no_trans_2010]), 
    FGT10.dates, 
    FGT10.baseindex,
    FGT10.codes[no_trans_2010],
    FGT10.names[no_trans_2010]
)

NOT_GT10 = VarCPIBase(NOT_FGT10)
NOT_GTDATA = UniformCountryStructure(NOT_GT10)

jldsave(joinpath(data_savepath, "NOT_data.jld2");
    NOT_FGT10, 
    NOT_GTDATA
)

# Inflación de no transables
inflfn = InflationTotalCPI()
inflfn(NOT_GTDATA)

