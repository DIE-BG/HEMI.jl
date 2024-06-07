using DrWatson
@quickactivate "HEMI"
using HEMI
using StatsBase
using DataFramesMeta

GTDATA_EVAL = GTDATA23

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

include(scriptsdir("generate_optim_combination","2024","2024_B","optmse2024_B.jl"))
include(scriptsdir("generate_optim_combination","2024","2024_B","optabsme2024_B.jl"))
include(scriptsdir("generate_optim_combination","2024","2024_B","optcorr2024_B.jl"))

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

D[!,"Subyacente Óptima MSE 2024 B"] = optmse2024_b(GTDATA_EVAL)
D[!,"Subyacente Óptima ABSME 2024 B"] = optabsme2024_b(GTDATA_EVAL)
D[!,"Subyacente Óptima CORR 2024 B"] = optcorr2024_b(GTDATA_EVAL)

D[!,"MSE 2024 B inferior"] = let
    dates_ci = infl_dates(GTDATA_EVAL)
    inf_limit = fill(Float32(0),length(dates_ci))
    for r in eachrow(optmse2024_ci)
        inf_limit += eval_periods( GTDATA_EVAL, r.evalperiod) .* r.inf_limit
    end
    out = inf_limit + D[:,"Subyacente Óptima MSE 2024 B"]
    out
end

D[!,"MSE 2024 B superior"] = let
    dates_ci = infl_dates(GTDATA_EVAL)
    sup_limit = fill(Float32(0),length(dates_ci))
    for r in eachrow(optmse2024_ci)
        sup_limit += eval_periods( GTDATA_EVAL, r.evalperiod) .* r.sup_limit
    end
    out = sup_limit + D[:,"Subyacente Óptima MSE 2024 B"]
    out
end

D[!,"ABSME 2024 B inferior"] = let
    dates_ci = infl_dates(GTDATA_EVAL)
    inf_limit = fill(optabsme2024_ci.inf_limit[1], length(dates_ci))
    out = inf_limit + D[:,"Subyacente Óptima ABSME 2024 B"]
    out
end

D[!,"ABSME 2024 B superior"] = let
    dates_ci = infl_dates(GTDATA_EVAL)
    inf_limit = fill(optabsme2024_ci.sup_limit[1], length(dates_ci))
    out = inf_limit + D[:,"Subyacente Óptima ABSME 2024 B"]
    out
end


mkpath(savedir)
using CSV
save_csv(joinpath(savedir,"optims.csv"), string.(D))

#=
## Fechas ------------------------------------------------------------------

dates     = infl_dates(GTDATA_EVAL) |> x->Dates.format.(x,"01/mm/yyyy")
idx_dates = (infl_dates(GTDATA_EVAL)[1] - Month(11): Month(1) : infl_dates(GTDATA_EVAL)[end]) |> x->Dates.format.(x,"01/mm/yyyy")

## DATAFRAMES 2024 -----------------------------------------------------------------------

dates_ci = infl_dates(GTDATA_EVAL)
inf_limit = Vector{Union{Missing, Float32}}(undef, length(dates_ci))
sup_limit = Vector{Union{Missing, Float32}}(undef, length(dates_ci))
opt_obs = optmse2024_b(GTDATA_EVAL)

for t in 1:length(dates_ci)
    inf_limit[t] = opt_obs[t] + optmse2024_ci.inf_limit[1]
    sup_limit[t] = opt_obs[t] + optmse2024_ci.sup_limit[1]
end

MSE_confidence_intervals = DataFrame(
    "Fecha" => dates_ci,
    "OPT_MSE" => opt_obs,
    "LIM_INF" => inf_limit,
    "LIM_SUP" => sup_limit
)

# MSE_optimization
MSE_optimization = DataFrame(
    "Fecha"  => idx_dates23,
    "Índice" => optmse2024_b(GTDATA_EVAL, CPIIndex()),
    "Variaciones Intermensuales MSE 2024" => optmse2024_b(GTDATA_EVAL, CPIVarInterm()),
    "Combinación Lineal Óptima MSE 2024 B" =>  vcat(fill("", 11), optmse2024_b(GTDATA_EVAL))
)

# ABSME_optimization
ABSME_optimization = DataFrame(
    "Fecha"  => idx_dates23,
    "Índice" => optabsme2024_b(GTDATA_EVAL, CPIIndex()),
    "Variaciones Intermensuales" => optabsme2024_b(GTDATA_EVAL, CPIVarInterm()),
    "Combinación Lineal Óptima ABSME 2024 B" =>  vcat(fill("", 11), optabsme2024_b(GTDATA_EVAL))
)

# CORR_optimization
CORR_optimization = DataFrame(
    "Fecha"  => idx_dates23,
    "Índice" => optcorr2024_b(GTDATA_EVAL, CPIIndex()),
    "Variaciones Intermensuales" => optcorr2024_b(GTDATA_EVAL, CPIVarInterm()),
    "Combinación Lineal Óptima CORR 2024 B" =>  vcat(fill("", 11), optcorr2024_b(GTDATA_EVAL))
)

save_csv(joinpath(savedir, "MSE_optimization_2024_B.csv"), string.(MSE_optimization))
save_csv(joinpath(savedir, "ABSME_optimization_2024_B.csv"), string.(ABSME_optimization))
save_csv(joinpath(savedir, "CORR_optimization_2024_B.csv"), string.(CORR_optimization))
save_csv(joinpath(savedir, "MSE_confidence_intervals_2024_B.csv"), string.(MSE_confidence_intervals))
=#