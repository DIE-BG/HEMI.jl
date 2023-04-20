using DrWatson
@quickactivate "HEMI"
using HEMI

GTDATA_EVAL = GTDATA

savedir = datadir("results","CSV")

include(scriptsdir("generate_optim_combination","2021","optmse2021.jl"))
include(scriptsdir("generate_optim_combination","2021","optabsme2021.jl"))
include(scriptsdir("generate_optim_combination","2021","optcorr2021.jl"))

include(scriptsdir("generate_optim_combination","2022","optmse2022.jl"))
include(scriptsdir("generate_optim_combination","2022","optabsme2022.jl"))
include(scriptsdir("generate_optim_combination","2022","optcorr2022.jl"))

include(scriptsdir("generate_optim_combination","2023","optmse2023.jl"))
include(scriptsdir("generate_optim_combination","2023","optabsme2023.jl"))
include(scriptsdir("generate_optim_combination","2023","optcorr2023.jl"))

D = DataFrame()

D[!,"Fecha"]           = Dates.format.(collect(infl_dates(GTDATA_EVAL)),dateformat"01/mm/yyyy")
D[!,"Inflación Total"] = InflationTotalCPI()(GTDATA_EVAL)
D[!,"Subyacente Óptima MSE 2022"] = optmse2022(GTDATA_EVAL, Date(2022,11))
D[!,"Subyacente Óptima ABSME 2022"] = optabsme2022(GTDATA_EVAL, Date(2022,11))
D[!,"Subyacente Óptima CORR 2022"] = optcorr2022(GTDATA_EVAL, Date(2022,11))
D[!,"Subyacente Óptima MSE 2023"] = optmse2023(GTDATA_EVAL)
D[!,"Subyacente Óptima ABSME 2023"] = optabsme2023(GTDATA_EVAL)
D[!,"Subyacente Óptima CORR 2023"] = optcorr2023(GTDATA_EVAL)
D[!,"MAI Óptima MSE 2023"] = optmai2023(GTDATA_EVAL)
D[!,"MAI Óptima ABSME 2023"] = optmai2023_absme(GTDATA_EVAL)
D[!,"MAI Óptima CORR 2023"] = optmai2023_corr(GTDATA_EVAL)

for x in optmse2023.ensemble.functions
    D[!,measure_name(x)] = x(GTDATA_EVAL)
end

for x in optabsme2023.ensemble.functions
    D[!,measure_name(x)] = x(GTDATA_EVAL)
end

for x in optcorr2023.ensemble.functions
    D[!,measure_name(x)] = x(GTDATA_EVAL)
end

for x in optmai2023.ensemble.functions
    D[!,measure_name(x)] = x(GTDATA_EVAL)
end

for x in optmai2023_absme.ensemble.functions
    D[!,measure_name(x)] = x(GTDATA_EVAL)
end

for x in optmai2023_corr.ensemble.functions
    D[!,measure_name(x)] = x(GTDATA_EVAL)
end

D[!,"MSE inferior"] = let
    b00 = length(GT_EVAL_B00.startdate:Month(1):GT_EVAL_B00.finaldate)
    T   = length(GT_EVAL_T0010.startdate:Month(1):GT_EVAL_T0010.finaldate)
    b10 = length(Date(2011, 12):Month(1):infl_dates(GTDATA_EVAL)[end])
    inf1   = fill(optmse2023_ci.inf_limit[1],b00)
    inf2   = fill(optmse2023_ci.inf_limit[2],T)
    inf3   = fill(optmse2023_ci.inf_limit[3],b10)
    low    = vcat(inf1,inf2,inf3)
    out    = optmse2023(GTDATA_EVAL)+low
    out
end

D[!,"MSE superior"] = let
    b00 = length(GT_EVAL_B00.startdate:Month(1):GT_EVAL_B00.finaldate)
    T   = length(GT_EVAL_T0010.startdate:Month(1):GT_EVAL_T0010.finaldate)
    b10 = length(Date(2011, 12):Month(1):infl_dates(GTDATA_EVAL)[end])
    sup1   = fill(optmse2023_ci.sup_limit[1],b00)
    sup2   = fill(optmse2023_ci.sup_limit[2],T)
    sup3   = fill(optmse2023_ci.sup_limit[3],b10)
    up    = vcat(sup1,sup2,sup3)
    out    = optmse2023(GTDATA_EVAL)+up
    out
end

D[!,"ABSME inferior"] = let
    b00 = length(GT_EVAL_B00.startdate:Month(1):GT_EVAL_B00.finaldate)
    T   = length(GT_EVAL_T0010.startdate:Month(1):GT_EVAL_T0010.finaldate)
    b10 = length(Date(2011, 12):Month(1):infl_dates(GTDATA_EVAL)[end])
    inf1   = fill(optabsme2023_ci.inf_limit[1],b00)
    inf2   = fill(optabsme2023_ci.inf_limit[2],T)
    inf3   = fill(optabsme2023_ci.inf_limit[3],b10)
    low    = vcat(inf1,inf2,inf3)
    out    = optabsme2023(GTDATA_EVAL)+low
    out
end

D[!,"ABSME superior"] = let
    b00 = length(GT_EVAL_B00.startdate:Month(1):GT_EVAL_B00.finaldate)
    T   = length(GT_EVAL_T0010.startdate:Month(1):GT_EVAL_T0010.finaldate)
    b10 = length(Date(2011, 12):Month(1):infl_dates(GTDATA_EVAL)[end])
    sup1   = fill(optabsme2023_ci.sup_limit[1],b00)
    sup2   = fill(optabsme2023_ci.sup_limit[2],T)
    sup3   = fill(optabsme2023_ci.sup_limit[3],b10)
    up    = vcat(sup1,sup2,sup3)
    out    = optabsme2023(GTDATA_EVAL)+up
    out
end

D[!,"Subyacente Óptima MSE 2021"] = optmse2021(GTDATA_EVAL, Date(2021,11))
D[!,"Subyacente Óptima ABSME 2021"] = optabsme2021(GTDATA_EVAL, Date(2021,11))
D[!,"Subyacente Óptima CORR 2021"] = optcorr2021(GTDATA_EVAL, Date(2021,11))


mkpath(savedir)
using CSV
CSV.write(joinpath(savedir,"optims.csv"), D)


## Fechas ------------------------------------------------------------------

dates     = infl_dates(GTDATA_EVAL) |> x->Dates.format.(x,"01/mm/yyyy")
idx_dates = (infl_dates(GTDATA_EVAL)[1] - Month(11): Month(1) : infl_dates(GTDATA_EVAL)[end]) |> x->Dates.format.(x,"01/mm/yyyy")

## DATAFRAMES 2023 ---------------------------------------------------------------------

# MSE_optimization
MSE_optimization = DataFrame(
    "Fecha"  => idx_dates,
    "Índice" => optmse2023(GTDATA_EVAL, CPIIndex()),
    "Combinación lineal óptima MSE" =>  vcat(fill(NaN, 11), optmse2023(GTDATA_EVAL))
)

# ABSME_optimization
ABSME_optimization = DataFrame(
    "Fecha"  => idx_dates,
    "Índice" => optabsme2023(GTDATA_EVAL, CPIIndex()),
    "Combinación lineal óptima ABSME" =>  vcat(fill(NaN, 11), optabsme2023(GTDATA_EVAL))
)

# CORR_optimization
CORR_optimization = DataFrame(
    "Fecha"  => idx_dates,
    "Índice" => optcorr2023(GTDATA_EVAL, CPIIndex()),
    "Combinación lineal óptima CORR" =>  vcat(fill(NaN, 11), optcorr2023(GTDATA_EVAL))
)

CSV.write(joinpath(savedir,"MSE_optimization.csv"), MSE_optimization)
CSV.write(joinpath(savedir,"ABSME_optimization.csv"), ABSME_optimization)
CSV.write(joinpath(savedir,"CORR_optimization.csv"), CORR_optimization)