using DrWatson
@quickactivate "HEMI"
using HEMI

savedir = datadir("results","CSV")

include(scriptsdir("generate_optim_combination","2022","optmse2022.jl"))
include(scriptsdir("generate_optim_combination","2022","optabsme2022.jl"))
include(scriptsdir("generate_optim_combination","2022","optcorr2022.jl"))

include(scriptsdir("generate_optim_combination","2023","optmse2023.jl"))
include(scriptsdir("generate_optim_combination","2023","optabsme2023.jl"))
include(scriptsdir("generate_optim_combination","2023","optcorr2023.jl"))

D = DataFrame()

D[!,"Fecha"]           = Dates.format.(collect(infl_dates(GTDATA)),dateformat"01/mm/yyyy")
D[!,"Inflación Total"] = InflationTotalCPI()(GTDATA)
D[!,"Subyacente Óptima MSE 2022"] = optmse2022(GTDATA)
D[!,"Subyacente Óptima ABSME 2022"] = optabsme2022(GTDATA)
D[!,"Subyacente Óptima CORR 2022"] = optcorr2022(GTDATA)
D[!,"Subyacente Óptima MSE 2023"] = optmse2023(GTDATA)
D[!,"Subyacente Óptima ABSME 2023"] = optabsme2023(GTDATA)
D[!,"Subyacente Óptima CORR 2023"] = optcorr2023(GTDATA)
D[!,"MAI Óptima MSE 2023"] = optmai2023(GTDATA)
D[!,"MAI Óptima ABSME 2023"] = optmai2023_absme(GTDATA)
D[!,"MAI Óptima CORR 2023"] = optmai2023_corr(GTDATA)

for x in optmse2023.ensemble.functions
    D[!,measure_name(x)] = x(GTDATA)
end

for x in optabsme2023.ensemble.functions
    D[!,measure_name(x)] = x(GTDATA)
end

for x in optcorr2023.ensemble.functions
    D[!,measure_name(x)] = x(GTDATA)
end

for x in optmai2023.ensemble.functions
    D[!,measure_name(x)] = x(GTDATA)
end

for x in optmai2023_absme.ensemble.functions
    D[!,measure_name(x)] = x(GTDATA)
end

for x in optmai2023_corr.ensemble.functions
    D[!,measure_name(x)] = x(GTDATA)
end

D[!,"MSE inferior"] = let
    b00 = length(GT_EVAL_B00.startdate:Month(1):GT_EVAL_B00.finaldate)
    T   = length(GT_EVAL_T0010.startdate:Month(1):GT_EVAL_T0010.finaldate)
    b10 = length(Date(2011, 12):Month(1):infl_dates(GTDATA)[end])
    inf1   = fill(optmse2023_ci.inf_limit[1],b00)
    inf2   = fill(optmse2023_ci.inf_limit[2],T)
    inf3   = fill(optmse2023_ci.inf_limit[3],b10)
    low    = vcat(inf1,inf2,inf3)
    out    = optmse2023(GTDATA)+low
    out
end

D[!,"MSE superior"] = let
    b00 = length(GT_EVAL_B00.startdate:Month(1):GT_EVAL_B00.finaldate)
    T   = length(GT_EVAL_T0010.startdate:Month(1):GT_EVAL_T0010.finaldate)
    b10 = length(Date(2011, 12):Month(1):infl_dates(GTDATA)[end])
    sup1   = fill(optmse2023_ci.sup_limit[1],b00)
    sup2   = fill(optmse2023_ci.sup_limit[2],T)
    sup3   = fill(optmse2023_ci.sup_limit[3],b10)
    up    = vcat(sup1,sup2,sup3)
    out    = optmse2023(GTDATA)+up
    out
end

D[!,"ABSME inferior"] = let
    b00 = length(GT_EVAL_B00.startdate:Month(1):GT_EVAL_B00.finaldate)
    T   = length(GT_EVAL_T0010.startdate:Month(1):GT_EVAL_T0010.finaldate)
    b10 = length(Date(2011, 12):Month(1):infl_dates(GTDATA)[end])
    inf1   = fill(optabsme2023_ci.inf_limit[1],b00)
    inf2   = fill(optabsme2023_ci.inf_limit[2],T)
    inf3   = fill(optabsme2023_ci.inf_limit[3],b10)
    low    = vcat(inf1,inf2,inf3)
    out    = optabsme2023(GTDATA)+low
    out
end

D[!,"ABSME superior"] = let
    b00 = length(GT_EVAL_B00.startdate:Month(1):GT_EVAL_B00.finaldate)
    T   = length(GT_EVAL_T0010.startdate:Month(1):GT_EVAL_T0010.finaldate)
    b10 = length(Date(2011, 12):Month(1):infl_dates(GTDATA)[end])
    sup1   = fill(optabsme2023_ci.sup_limit[1],b00)
    sup2   = fill(optabsme2023_ci.sup_limit[2],T)
    sup3   = fill(optabsme2023_ci.sup_limit[3],b10)
    up    = vcat(sup1,sup2,sup3)
    out    = optabsme2023(GTDATA)+up
    out
end


mkpath(savedir)
using CSV
CSV.write(joinpath(savedir,"optims.csv"), D)
