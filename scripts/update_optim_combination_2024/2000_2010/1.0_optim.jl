using DrWatson
@quickactivate "HEMI"

include(scriptsdir("TOOLS","OPTIM","optim.jl"))

savepath = datadir("optim_comb_2024","2000_2010")  

## CARGANDO DATOS

gtdata_eval = GTDATA[Date(2022,12)]

# Creamos periodo de evaluacion para medidas hasta Dic 2020.
GT_EVAL_B2020 = EvalPeriod(Date(2011, 12), Date(2020, 12), "gt_b2020")


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
    :traindate => Date(2020, 12),
    :nsim => 10_000,
    :evalperiods => (CompletePeriod(), GT_EVAL_B00, GT_EVAL_B2020, GT_EVAL_B10)
) |> dict_list

savepath_grid = joinpath(savepath,"grid")

# vaciamos el directorio
rm.(readdir(savepath_grid, join=true))

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

##### B00 ##########
####################

savepath_mse_b00 = joinpath(savepath,"B00","mse")

#limpiamos el contenido anterior
mkpath(savepath_mse_b00)
rm.(readdir(savepath_mse_b00, join=true))

# Filtramos
percEQ = sort(grid_DF[grid_DF.infltypefn .== InflationPercentileEq,:],order(:gt_b00_mse))
percW = sort(grid_DF[grid_DF.infltypefn .== InflationPercentileWeighted,:],order(:gt_b00_mse))
TMEQ = sort(grid_DF[grid_DF.infltypefn .== InflationTrimmedMeanEq,:],order(:gt_b00_mse))
TMW = sort(grid_DF[grid_DF.infltypefn .== InflationTrimmedMeanWeighted,:],order(:gt_b00_mse))
DE = sort(grid_DF[grid_DF.infltypefn .== InflationDynamicExclusion,:],order(:gt_b00_mse))

# Guardamos El mejor resultado
cp(percEQ.path[1], joinpath(savepath_mse_b00, basename(percEQ.path[1])), force=true)
cp(percW.path[1], joinpath(savepath_mse_b00, basename(percW.path[1])), force=true)
cp(TMEQ.path[1], joinpath(savepath_mse_b00, basename(TMEQ.path[1])), force=true)
cp(TMW.path[1], joinpath(savepath_mse_b00, basename(TMW.path[1])), force=true)
cp(DE.path[1], joinpath(savepath_mse_b00, basename(DE.path[1])), force=true)

##### B10 ##########
####################

savepath_mse_b10 = joinpath(savepath,"B10","mse")

#limpiamos el contenido anterior
mkpath(savepath_mse_b10)
rm.(readdir(savepath_mse_b10, join=true))

# Filtramos
percEQ = sort(grid_DF[grid_DF.infltypefn .== InflationPercentileEq,:],order(:gt_b2020_mse))
percW = sort(grid_DF[grid_DF.infltypefn .== InflationPercentileWeighted,:],order(:gt_b2020_mse))
TMEQ = sort(grid_DF[grid_DF.infltypefn .== InflationTrimmedMeanEq,:],order(:gt_b2020_mse))
TMW = sort(grid_DF[grid_DF.infltypefn .== InflationTrimmedMeanWeighted,:],order(:gt_b2020_mse))
DE = sort(grid_DF[grid_DF.infltypefn .== InflationDynamicExclusion,:],order(:gt_b2020_mse))

# Guardamos 
cp(percEQ.path[1], joinpath(savepath_mse_b10, basename(percEQ.path[1])), force=true)
cp(percW.path[1], joinpath(savepath_mse_b10, basename(percW.path[1])), force=true)
cp(TMEQ.path[1], joinpath(savepath_mse_b10, basename(TMEQ.path[1])), force=true)
cp(TMW.path[1], joinpath(savepath_mse_b10, basename(TMW.path[1])), force=true)
cp(DE.path[1], joinpath(savepath_mse_b10, basename(DE.path[1])), force=true)

######################################################
############ ABSME #####################################
######################################################

##### B00 ##########
####################

savepath_absme_b00 = joinpath(savepath, "B00","absme")

#limpiamos el contenido anterior
mkpath(savepath_absme_b00)
rm.(readdir(savepath_absme_b00, join=true))

# Filtramos
percEQ = sort(grid_DF[grid_DF.infltypefn .== InflationPercentileEq,:],order(:gt_b00_absme))
percW = sort(grid_DF[grid_DF.infltypefn .== InflationPercentileWeighted,:],order(:gt_b00_absme))
TMEQ = sort(grid_DF[grid_DF.infltypefn .== InflationTrimmedMeanEq,:],order(:gt_b00_absme))
TMW = sort(grid_DF[grid_DF.infltypefn .== InflationTrimmedMeanWeighted,:],order(:gt_b00_absme))
DE = sort(grid_DF[grid_DF.infltypefn .== InflationDynamicExclusion,:],order(:gt_b00_absme))

# Guardamos 
cp(percEQ.path[1], joinpath(savepath_absme_b00, basename(percEQ.path[1])), force=true)
cp(percW.path[1], joinpath(savepath_absme_b00, basename(percW.path[1])), force=true)
cp(TMEQ.path[1], joinpath(savepath_absme_b00, basename(TMEQ.path[1])), force=true)
cp(TMW.path[1], joinpath(savepath_absme_b00, basename(TMW.path[1])), force=true)
cp(DE.path[1], joinpath(savepath_absme_b00, basename(DE.path[1])), force=true)

##### B10 ##########
####################

savepath_absme_b10 = joinpath(savepath,"B10","absme")

#limpiamos el contenido anterior
mkpath(savepath_absme_b10)
rm.(readdir(savepath_absme_b10, join=true))

# Filtramos
percEQ = sort(grid_DF[grid_DF.infltypefn .== InflationPercentileEq,:],order(:gt_b2020_absme))
percW = sort(grid_DF[grid_DF.infltypefn .== InflationPercentileWeighted,:],order(:gt_b2020_absme))
TMEQ = sort(grid_DF[grid_DF.infltypefn .== InflationTrimmedMeanEq,:],order(:gt_b2020_absme))
TMW = sort(grid_DF[grid_DF.infltypefn .== InflationTrimmedMeanWeighted,:],order(:gt_b2020_absme))
DE = sort(grid_DF[grid_DF.infltypefn .== InflationDynamicExclusion,:],order(:gt_b2020_absme))

# Guardamos 
cp(percEQ.path[1], joinpath(savepath_absme_b10, basename(percEQ.path[1])), force=true)
cp(percW.path[1], joinpath(savepath_absme_b10, basename(percW.path[1])), force=true)
cp(TMEQ.path[1], joinpath(savepath_absme_b10, basename(TMEQ.path[1])), force=true)
cp(TMW.path[1], joinpath(savepath_absme_b10, basename(TMW.path[1])), force=true)
cp(DE.path[1], joinpath(savepath_absme_b10, basename(DE.path[1])), force=true)

######################################################
############ CORR #####################################
######################################################

##### B00 ##########
####################

savepath_corr_b00 = joinpath(savepath,"B00","corr")

#limpiamos el contenido anterior
mkpath(savepath_corr_b00)
rm.(readdir(savepath_corr_b00, join=true))

# Filtramos
percEQ = sort(grid_DF[grid_DF.infltypefn .== InflationPercentileEq,:],order(:gt_b00_corr), rev=true)
percW = sort(grid_DF[grid_DF.infltypefn .== InflationPercentileWeighted,:],order(:gt_b00_corr), rev=true)
TMEQ = sort(grid_DF[grid_DF.infltypefn .== InflationTrimmedMeanEq,:],order(:gt_b00_corr), rev=true)
TMW = sort(grid_DF[grid_DF.infltypefn .== InflationTrimmedMeanWeighted,:],order(:gt_b00_corr), rev=true)
DE = sort(grid_DF[grid_DF.infltypefn .== InflationDynamicExclusion,:],order(:gt_b00_corr), rev=true)

# Guardamos 
cp(percEQ.path[1], joinpath(savepath_corr_b00, basename(percEQ.path[1])), force=true)
cp(percW.path[1], joinpath(savepath_corr_b00, basename(percW.path[1])), force=true)
cp(TMEQ.path[1], joinpath(savepath_corr_b00, basename(TMEQ.path[1])), force=true)
cp(TMW.path[1], joinpath(savepath_corr_b00, basename(TMW.path[1])), force=true)
cp(DE.path[1], joinpath(savepath_corr_b00, basename(DE.path[1])), force=true)

##### B10 ##########
####################

savepath_corr_b10 = joinpath(savepath,"B10","corr")

#limpiamos el contenido anterior
mkpath(savepath_corr_b10)
rm.(readdir(savepath_corr_b10, join=true))

# Filtramos
percEQ = sort(grid_DF[grid_DF.infltypefn .== InflationPercentileEq,:],order(:gt_b2020_corr), rev=true)
percW = sort(grid_DF[grid_DF.infltypefn .== InflationPercentileWeighted,:],order(:gt_b2020_corr), rev=true)
TMEQ = sort(grid_DF[grid_DF.infltypefn .== InflationTrimmedMeanEq,:],order(:gt_b2020_corr), rev=true)
TMW = sort(grid_DF[grid_DF.infltypefn .== InflationTrimmedMeanWeighted,:],order(:gt_b2020_corr), rev=true)
DE = sort(grid_DF[grid_DF.infltypefn .== InflationDynamicExclusion,:],order(:gt_b2020_corr), rev=true)

# Guardamos 
cp(percEQ.path[1], joinpath(savepath_corr_b10, basename(percEQ.path[1])), force=true)
cp(percW.path[1], joinpath(savepath_corr_b10, basename(percW.path[1])), force=true)
cp(TMEQ.path[1], joinpath(savepath_corr_b10, basename(TMEQ.path[1])), force=true)
cp(TMW.path[1], joinpath(savepath_corr_b10, basename(TMW.path[1])), force=true)
cp(DE.path[1], joinpath(savepath_corr_b10, basename(DE.path[1])), force=true)