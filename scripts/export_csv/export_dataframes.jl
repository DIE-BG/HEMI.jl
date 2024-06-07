using DrWatson
@quickactivate "HEMI"
using HEMI

GTDATA_EVAL = GTDATA

savedir = datadir("results","CSV","resultados_excel")

include(scriptsdir("generate_optim_combination","2023","optmse2023.jl"))
include(scriptsdir("generate_optim_combination","2023","optabsme2023.jl"))
include(scriptsdir("generate_optim_combination","2023","optcorr2023.jl"))

include(scriptsdir("generate_optim_combination","2024","2024_B","optmse2024_B.jl"))
include(scriptsdir("generate_optim_combination","2024","2024_B","optabsme2024_B.jl"))
include(scriptsdir("generate_optim_combination","2024","2024_B","optcorr2024_B.jl"))

## Fechas ------------------------------------------------------------------

dates     = infl_dates(GTDATA_EVAL) |> x->Dates.format.(x,"01/mm/yyyy")
idx_dates = (infl_dates(GTDATA_EVAL)[1] - Month(11): Month(1) : infl_dates(GTDATA_EVAL)[end]) |> x->Dates.format.(x,"01/mm/yyyy")
idx_dates23 = (infl_dates(GTDATA23)[1] - Month(11): Month(1) : infl_dates(GTDATA23)[end]) |> x->Dates.format.(x,"01/mm/yyyy")

## DATAFRAMES 2024 -----------------------------------------------------------------------

dates_ci = infl_dates(GTDATA23)
inf_limit = fill(Float32(0),length(dates_ci))
sup_limit = fill(Float32(0),length(dates_ci))
opt_obs = optmse2024_b(GTDATA23)


for r in eachrow(optmse2024_ci)
    global inf_limit += eval_periods( GTDATA23, r.evalperiod) .* r.inf_limit
    global sup_limit += eval_periods( GTDATA23, r.evalperiod) .* r.sup_limit
end

inf_limit += opt_obs
sup_limit += opt_obs



MSE_confidence_intervals = DataFrame(
    "Fecha" => dates_ci,
    "OPT_MSE" => opt_obs,
    "LIM_INF" => inf_limit,
    "LIM_SUP" => sup_limit
)

# MSE_optimization
MSE_optimization = DataFrame(
    "Fecha"  => idx_dates23,
    "Índice" => optmse2024_b(GTDATA23, CPIIndex()),
    "Variaciones Intermensuales MSE 2024" => optmse2024_b(GTDATA23, CPIVarInterm()),
    "Combinación Lineal Óptima MSE 2024 B" =>  vcat(fill("", 11), optmse2024_b(GTDATA23))
)

# ABSME_optimization
ABSME_optimization = DataFrame(
    "Fecha"  => idx_dates23,
    "Índice" => optabsme2024_b(GTDATA23, CPIIndex()),
    "Variaciones Intermensuales" => optabsme2024_b(GTDATA23, CPIVarInterm()),
    "Combinación Lineal Óptima ABSME 2024 B" =>  vcat(fill("", 11), optabsme2024_b(GTDATA23))
)

# CORR_optimization
CORR_optimization = DataFrame(
    "Fecha"  => idx_dates23,
    "Índice" => optcorr2024_b(GTDATA23, CPIIndex()),
    "Variaciones Intermensuales" => optcorr2024_b(GTDATA23, CPIVarInterm()),
    "Combinación Lineal Óptima CORR 2024 B" =>  vcat(fill("", 11), optcorr2024_b(GTDATA23))
)

save_csv(joinpath(savedir, "MSE_optimization_2024_B.csv"), string.(MSE_optimization))
save_csv(joinpath(savedir, "ABSME_optimization_2024_B.csv"), string.(ABSME_optimization))
save_csv(joinpath(savedir, "CORR_optimization_2024_B.csv"), string.(CORR_optimization))
save_csv(joinpath(savedir, "MSE_confidence_intervals_2024_B.csv"), string.(MSE_confidence_intervals))

##################################################################################################################
## MEDIA SIMPLE Y MEDIA POND
##################################################################################################################
using StatsBase
using DataFrames
using DataFramesMeta


savedir = datadir("results","CSV","resultados_excel")


gtdata = GTDATA23

# Moments
stats = mapreduce(vcat, gtdata.base) do base
    w = aweights(base.w) 
    mapreduce(vcat, eachrow(base.v)) do vdistr 
        # Simple and weighted mean
        sm = mean(vdistr)
        wm = sum(vdistr .* base.w) / 100 

        [sm wm]
    end
end 

smfn = InflationSimpleMean() 
wmfn = InflationWeightedMean() 

transition_periods = [
    collect(Date(2011,1):Month(1):Date(2011,11))...,
    collect(Date(2024,1):Month(1):Date(2024,11))...,
]

dates = gtdata.base[1].dates[1]:Month(1):gtdata.base[end].dates[end]
transition_mask = in.(dates, Ref(transition_periods))

simple_mean_df = DataFrame(
    date = dates,
    sm_interm_v = stats[:, 1], 
    sm_interm_idx = capitalize(stats[:, 1]), 
    sm_interm_a = vec([fill("", 11); varinteran(capitalize(stats[:, 1]))]),
    sm_interan = vec([fill("", 11); smfn(gtdata)]), 
)

@chain simple_mean_df begin 
    @rtransform!(:sm_interan = ifelse(:date in transition_periods, :sm_interm_a, :sm_interan))
    # @rsubset((:date in transition_periods))
end

weighted_mean_df = DataFrame(
    date = dates,
    wm_interm_v = stats[:, 2], 
    wm_interm_idx = capitalize(stats[:, 2]), 
    wm_interm_a = vec([fill("", 11); varinteran(capitalize(stats[:, 2]))]),
    wm_interan = vec([fill("", 11); wmfn(gtdata)]), 
)

@chain weighted_mean_df begin 
    @rtransform!(:wm_interan = ifelse(:date in transition_periods, :wm_interm_a, :wm_interan))
    # @rsubset((:date in transition_periods))
end


rename!(simple_mean_df,["Mes","Media Simple Intermensual por definición", "Índice Media Simple Intermensual por definición", "Variación interanual del Índice de Media Simple Intermensual", "Media Simple Interanual"])
rename!(weighted_mean_df,["Mes","Media Ponderada Intermensual por definición", "Índice Media Ponderada Intermensual por definición", "Variación interanual del Índice de Media Ponderada Intermensual", "Media Ponderada Interanual"])

save_csv(joinpath(savedir,"Media_Simple.csv"), string.(simple_mean_df))
save_csv(joinpath(savedir,"Media_Pond.csv"), string.(weighted_mean_df))



#=

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
=#