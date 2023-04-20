using DrWatson
@quickactivate "HEMI"
using HEMI

GTDATA_EVAL = GTDATA

savedir = datadir("results","CSV","resultados_excel")

include(scriptsdir("generate_optim_combination","2023","optmse2023.jl"))
include(scriptsdir("generate_optim_combination","2023","optabsme2023.jl"))
include(scriptsdir("generate_optim_combination","2023","optcorr2023.jl"))


## Fechas ------------------------------------------------------------------

dates     = infl_dates(GTDATA_EVAL) |> x->Dates.format.(x,"01/mm/yyyy")
idx_dates = (infl_dates(GTDATA_EVAL)[1] - Month(11): Month(1) : infl_dates(GTDATA_EVAL)[end]) |> x->Dates.format.(x,"01/mm/yyyy")

## DATAFRAMES 2023 ---------------------------------------------------------------------

dates_ci = infl_dates(GTDATA_EVAL)
inf_limit = Vector{Union{Missing, Float32}}(undef, length(dates_ci))
sup_limit = Vector{Union{Missing, Float32}}(undef, length(dates_ci))
opt_obs = optmse2023(GTDATA_EVAL)


for t in 1:length(dates)
    for r in eachrow(optmse2023_ci)
        period = r.evalperiod
        if period.startdate <= dates_ci[t] <= period.finaldate
            inf_limit[t] = opt_obs[t] + r.inf_limit
            sup_limit[t] = opt_obs[t] + r.sup_limit
        end
    end
end

MSE_confidence_intervals = DataFrame(
    "Fecha" => dates,
    "OPT_MSE" => opt_obs,
    "LIM_INF" => inf_limit,
    "LIM_SUP" => sup_limit
)


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

#MSE_optimization_index_components
opt_components = components(optmse2023)
mai_components = components(optmai2023)
df1 = DataFrame(optmse2023.ensemble(GTDATA_EVAL, CPIIndex()), opt_components.measure)
df2 = DataFrame(optmai2023.ensemble(GTDATA_EVAL, CPIIndex()), mai_components.measure)
MSE_optimization_index_components = hcat(df1, df2)
insertcols!(MSE_optimization_index_components, 1, "Fecha" => idx_dates)

#ABSME_optimization_index_components
opt_components = components(optabsme2023)
mai_components = components(optmai2023_absme)
df1 = DataFrame(optabsme2023.ensemble(GTDATA_EVAL, CPIIndex()), opt_components.measure)
df2 = DataFrame(optmai2023_absme.ensemble(GTDATA_EVAL, CPIIndex()), mai_components.measure)
ABSME_optimization_index_components = hcat(df1, df2)
insertcols!(ABSME_optimization_index_components, 1, "Fecha" => idx_dates)

#CORR_optimization_index_components
opt_components = components(optcorr2023)  
mai_components = components(optmai2023_corr)
df1 = DataFrame(optcorr2023.ensemble(GTDATA_EVAL, CPIIndex()), opt_components.measure)
df2 = DataFrame(optmai2023_corr.ensemble(GTDATA_EVAL, CPIIndex()), mai_components.measure)
CORR_optimization_index_components = hcat(df1, df2)
insertcols!(CORR_optimization_index_components, 1, "Fecha" => idx_dates)

#MSE_optimization_interannual_components
opt_components = components(optmse2023)
mai_components = components(optmai2023)
df1 = DataFrame(optmse2023.ensemble(GTDATA_EVAL), opt_components.measure)
df2 = DataFrame(optmai2023.ensemble(GTDATA_EVAL), mai_components.measure)
MSE_optimization_interannual_components = hcat(df1, df2)
insertcols!(MSE_optimization_interannual_components, 1, "Fecha" => dates)

#ABSME_optimization_interannual_components
opt_components = components(optabsme2023)
mai_components = components(optmai2023_absme)
df1 = DataFrame(optabsme2023.ensemble(GTDATA_EVAL), opt_components.measure)
df2 = DataFrame(optmai2023_absme.ensemble(GTDATA_EVAL), mai_components.measure)
ABSME_optimization_interannual_components = hcat(df1, df2)
insertcols!(ABSME_optimization_interannual_components, 1, "Fecha" => dates)

#CORR_optimization_interannual_components
opt_components = components(optcorr2023)  #Para orden correcto
mai_components = components(optmai2023_corr)
df1 = DataFrame(optcorr2023.ensemble(GTDATA_EVAL), opt_components.measure)
df2 = DataFrame(optmai2023_corr.ensemble(GTDATA_EVAL), mai_components.measure)
CORR_optimization_interannual_components = hcat(df1, df2)
insertcols!(CORR_optimization_interannual_components, 1, "Fecha" => dates)

## CSVs mensuales ----------------------------------------------------------------

mkpath(savedir)
using CSV


save_csv(joinpath(savedir, "MSE_confidence_intervals.csv"), MSE_confidence_intervals)

save_csv(joinpath(savedir, "MSE_optimization.csv"), MSE_optimization)
save_csv(joinpath(savedir, "ABSME_optimization.csv"), ABSME_optimization)
save_csv(joinpath(savedir, "CORR_optimization.csv"), CORR_optimization)

save_csv(joinpath(savedir, "MSE_optimization_index_components.csv"), MSE_optimization_index_components)
save_csv(joinpath(savedir, "ABSME_optimization_index_components.csv"), ABSME_optimization_index_components)
save_csv(joinpath(savedir, "CORR_optimization_index_components.csv"), CORR_optimization_index_components)

save_csv(joinpath(savedir, "MSE_optimization_interannual_components.csv"), MSE_optimization_interannual_components)
save_csv(joinpath(savedir, "ABSME_optimization_interannual_components.csv"), ABSME_optimization_interannual_components)
save_csv(joinpath(savedir, "CORR_optimization_interannual_components.csv"), CORR_optimization_interannual_components)
