using DrWatson
@quickactivate "HEMI"

include(scriptsdir("load_data.jl"))
using HEMI

data_savepath = mkpath(datadir("results", "no_trans", "data"))

# LISTA DE GASTOS BASICOS NO TRANSABLES
no_trans_2000 = [
    59,60,88,95,101:106...,140,151:153...,158,160,161,
    163,164,166,167,172,179:183...,185,186,188:196...,
    200,202,216:218...
]

no_trans_2010 = [
    100,107,108,110,112:114...,155,156,170:177...,
    187:198...,200:205...,223:229...,231:233...,
    236:252...,273:279...
]

no_trans_2023 = [
    111, 179, 189:194... , 239, 271:297..., 311:329..., 337:344..., 354:357..., 
    370:405..., 420:425..., 433:437...

]

# CREAMOS LAS BASES DE DATOS
NOT_FGT00 = FullCPIBase(
    FGT00.ipc[:, no_trans_2000],
    FGT00.v[:, no_trans_2000],
    100 * FGT00.w[no_trans_2000] / sum(FGT00.w[no_trans_2000]), 
    FGT00.dates, 
    FGT00.baseindex,
    FGT00.codes[no_trans_2000],
    FGT00.names[no_trans_2000]
)

NOT_FGT10 = FullCPIBase(
    FGT10.ipc[:, no_trans_2010],
    FGT10.v[:, no_trans_2010],
    100 * FGT10.w[no_trans_2010] / sum(FGT10.w[no_trans_2010]), 
    FGT10.dates, 
    FGT10.baseindex,
    FGT10.codes[no_trans_2010],
    FGT10.names[no_trans_2010]
)

NOT_FGT23 = FullCPIBase(
    FGT23.ipc[:, no_trans_2023],
    FGT23.v[:, no_trans_2023],
    100 * FGT23.w[no_trans_2023] / sum(FGT23.w[no_trans_2023]), 
    FGT23.dates, 
    FGT23.baseindex,
    FGT23.codes[no_trans_2023],
    FGT23.names[no_trans_2023]
)

NOT_GT00 = VarCPIBase(NOT_FGT00)
NOT_GT10 = VarCPIBase(NOT_FGT10)
NOT_GT23 = VarCPIBase(NOT_FGT23)

# CREAMOS UN UniformCountryStructure CON AMBAS BASES DE DATOS
NOT_GTDATA   = UniformCountryStructure(NOT_GT00,NOT_GT10)
NOT_GTDATA23 = UniformCountryStructure(NOT_GT00,NOT_GT10,NOT_GT23)
# GUARDAMOS
jldsave(joinpath(data_savepath, "NOT_data.jld2");
    NOT_FGT00,
    NOT_FGT10, 
    NOT_GTDATA
)

jldsave(joinpath(data_savepath, "NOT_data23.jld2");
    NOT_FGT00,
    NOT_FGT10,
    NOT_FGT23, 
    NOT_GTDATA23
)