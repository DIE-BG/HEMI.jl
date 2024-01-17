using DrWatson
@quickactivate "HEMI"

include(scriptsdir("TOOLS","OPTIM","optim.jl"))

savepath = datadir("results","optim_comb_2024_B")
mkpath(savepath)  

## CARGANDO DATOS

gtdata_eval = GTDATA[Date(2022,12)]

# Creamos periodos de evaluacion hasta 2008 y hasta 2020
GT_EVAL_B08 = EvalPeriod(Date(2001, 12), Date(2008, 12), "gt_b08")
GT_EVAL_B20 = EvalPeriod(Date(2011, 12), Date(2020, 12), "gt_b20")

# Creamos un período especial 2001-2008 y 2011-2020 
GT_EVAL_B0820 = InflationEvalTools.PeriodVector(
    [
        (Date(2001, 12), Date(2008, 12)),
        (Date(2011, 12), Date(2020, 12))
    ],
    "gt_b0820"
)


##########################################################################################################
################ GRID EXPLORATORIA ######################################################################
##########################################################################################################


config_dict = Dict(
    :inflfn => [InflationPercentileEq.(2:99)...,
                InflationPercentileWeighted.(2:99)..., 
                [InflationTrimmedMeanEq(x,y) for x in 01:99 for y in x:99]...,
                [InflationTrimmedMeanWeighted(x,y) for x in 01:99 for y in x:99]...,
                [InflationDynamicExclusion(x,y) for x in 0.1:0.1:5.0 for y in 0.1:0.1:5.0]...,
                ], 
    :resamplefn => ResampleScrambleVarMonths(), 
    :trendfn => TrendRandomWalk(),
    :paramfn => InflationTotalRebaseCPI(36,3), 
    :traindate => Date(2022, 12),
    :nsim => 10_000,
    :evalperiods => (CompletePeriod(), GT_EVAL_B00, GT_EVAL_B20, GT_EVAL_B10, GT_EVAL_B0820, GT_EVAL_B08)
) |> dict_list

savepath_grid = joinpath(savepath,"grid")
mkpath(savepath_grid)

# vaciamos el directorio
# CUIDADO! 
#rm.(readdir(savepath_grid, join=true), recursive=true, force=true)

# Ejecutamos run_batch
run_batch(gtdata_eval, config_dict, savepath_grid; savetrajectories = false)
grid_DF = collect_results(savepath_grid)


# agregamos tipo de funcion
grid_DF[!,:infltypefn] = typeof.(grid_DF[:,:inflfn])

# Le creamos una columna donde se encuentren los parametros de cada medida
grid_DF.k = map(
    x -> x isa Union{InflationPercentileEq, InflationPercentileWeighted} ? x.k :
    x isa Union{InflationTrimmedMeanEq, InflationTrimmedMeanWeighted} ? (x.l1,x.l2) :
    x isa InflationDynamicExclusion ? (x.lower_factor,x.upper_factor) : NaN,
    grid_DF.inflfn
)


# Filtramos los NaNs en donde hay cantidades numericas
filter!(row -> all(x -> !(x isa Number && isnan(x)), row), grid_DF)


######################################################
############ MSE #####################################
######################################################

savepath_mse = joinpath(savepath,"mse")

#limpiamos el contenido anterior
mkpath(savepath_mse)
rm.(readdir(savepath_mse, join=true))

# Filtramos
percEQ = sort(grid_DF[grid_DF.infltypefn .== InflationPercentileEq,:],order(:gt_b0820_mse))
percW = sort(grid_DF[grid_DF.infltypefn .== InflationPercentileWeighted,:],order(:gt_b0820_mse))
TMEQ = sort(grid_DF[grid_DF.infltypefn .== InflationTrimmedMeanEq,:],order(:gt_b0820_mse))
TMW = sort(grid_DF[grid_DF.infltypefn .== InflationTrimmedMeanWeighted,:],order(:gt_b0820_mse))
DE = sort(grid_DF[grid_DF.infltypefn .== InflationDynamicExclusion,:],order(:gt_b0820_mse))

# Guardamos El mejor resultado
cp(percEQ.path[1], joinpath(savepath_mse, basename(percEQ.path[1])), force=true)
cp(percW.path[1], joinpath(savepath_mse, basename(percW.path[1])), force=true)
cp(TMEQ.path[1], joinpath(savepath_mse, basename(TMEQ.path[1])), force=true)
cp(TMW.path[1], joinpath(savepath_mse, basename(TMW.path[1])), force=true)
cp(DE.path[1], joinpath(savepath_mse, basename(DE.path[1])), force=true)


######################################################
############ ABSME #####################################
######################################################

savepath_absme = joinpath(savepath,"absme")

#limpiamos el contenido anterior
mkpath(savepath_absme)
rm.(readdir(savepath_absme, join=true))

# Filtramos
percEQ = sort(grid_DF[grid_DF.infltypefn .== InflationPercentileEq,:],order(:gt_b0820_absme))
percW = sort(grid_DF[grid_DF.infltypefn .== InflationPercentileWeighted,:],order(:gt_b0820_absme))
TMEQ = sort(grid_DF[grid_DF.infltypefn .== InflationTrimmedMeanEq,:],order(:gt_b0820_absme))
TMW = sort(grid_DF[grid_DF.infltypefn .== InflationTrimmedMeanWeighted,:],order(:gt_b0820_absme))
DE = sort(grid_DF[grid_DF.infltypefn .== InflationDynamicExclusion,:],order(:gt_b0820_absme))

# Guardamos 
cp(percEQ.path[1], joinpath(savepath_absme, basename(percEQ.path[1])), force=true)
cp(percW.path[1], joinpath(savepath_absme, basename(percW.path[1])), force=true)
cp(TMEQ.path[1], joinpath(savepath_absme, basename(TMEQ.path[1])), force=true)
cp(TMW.path[1], joinpath(savepath_absme, basename(TMW.path[1])), force=true)
cp(DE.path[1], joinpath(savepath_absme, basename(DE.path[1])), force=true)

######################################################
############ CORR #####################################
######################################################

# Creamos un promedio de correlación entre ambas bases
grid_DF[!,:gt_b0820_corr] = 0.5 .* grid_DF.gt_b08_corr .+ 0.5 .* grid_DF.gt_b20_corr


savepath_corr = joinpath(savepath,"corr")

#limpiamos el contenido anterior
mkpath(savepath_corr)
rm.(readdir(savepath_corr, join=true))

# Filtramos
percEQ = sort(grid_DF[grid_DF.infltypefn .== InflationPercentileEq,:],order(:gt_b0820_corr), rev=true)
percW = sort(grid_DF[grid_DF.infltypefn .== InflationPercentileWeighted,:],order(:gt_b0820_corr), rev=true)
TMEQ = sort(grid_DF[grid_DF.infltypefn .== InflationTrimmedMeanEq,:],order(:gt_b0820_corr), rev=true)
TMW = sort(grid_DF[grid_DF.infltypefn .== InflationTrimmedMeanWeighted,:],order(:gt_b0820_corr), rev=true)
DE = sort(grid_DF[grid_DF.infltypefn .== InflationDynamicExclusion,:],order(:gt_b0820_corr), rev=true)

# Guardamos 
wsave(joinpath(savepath_corr, basename(percEQ.path[1])), tostringdict(percEQ[1,:]))
wsave(joinpath(savepath_corr, basename(percW.path[1])), tostringdict(percW[1,:]))
wsave(joinpath(savepath_corr, basename(TMEQ.path[1])), tostringdict(TMEQ[1,:]))
wsave(joinpath(savepath_corr, basename(TMW.path[1])), tostringdict(TMW[1,:]))
wsave(joinpath(savepath_corr, basename(DE.path[1])), tostringdict(DE[1,:]))

