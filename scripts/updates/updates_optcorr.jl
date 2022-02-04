## -----------------------------------------------
# Importando paquetes
using DrWatson
@quickactivate "HEMI"

using HEMI 
using DataFrames, CSV, StringEncodings

## ------------------------------------------------
# Actualizar datos
@info "Actualizando archivo de datos"
include(scriptsdir("load_data.jl"))
HEMI.load_data()


# Helper functions
include(joinpath(@__DIR__, "updates_helpers.jl"))

## --------------------------------------------------
# Óptimas MSE , ABSME y CORR 2020

# MSE
include(scriptsdir("mse-combination", "optmse2022.jl"))

# ABSME
config_savepath_absme = datadir("results", "absme-combination", "Esc-G")
optabsme2022 = wload(datadir(config_savepath_absme, "optabsme2022", "optabsme2022.jld2"), "optabsme2022")

maioptabsme_path = datadir("results", "CoreMai", "Esc-G", "BestOptim", "absme-weights", "maioptfn.jld2")
optmai2018_absme = wload(maioptabsme_path, "maioptfn")

# CORR
config_savepath_corr = datadir("results", "corr-combination", "Esc-F")
optcorr2022 = wload(datadir(config_savepath_corr, "optcorr2022", "optcorr2022.jld2"), "optcorr2022")

maioptcorr_path = datadir("results", "CoreMai", "Esc-F", "BestOptim", "corr-weights", "maioptfn.jld2")
optmai2018_corr = wload(maioptcorr_path, "maioptfn")

## --------------------------------------------------------
# Fechas

dates     = infl_dates(gtdata) 
idx_dates = dates[1] - Month(11): Month(1) : dates[end]

## ---------------------------------------------------------
# DATAFRAMES

# MSE_optimization
MSE_optimization = DataFrame(
    "Fecha"  => idx_dates,
    "Índice" => optmse2022(gtdata, CPIIndex()),
    "Combinación lineal óptima MSE" =>  vcat(fill(missing, 11), optmse2022(gtdata))
)

# ABSME_optimization
ABSME_optimization = DataFrame(
    "Fecha"  => idx_dates,
    "Índice" => optabsme2022(gtdata, CPIIndex()),
    "Combinación lineal óptima ABSME" =>  vcat(fill(missing, 11), optabsme2022(gtdata))
)

# CORR_optimization
CORR_optimization = DataFrame(
    "Fecha"  => idx_dates,
    "Índice" => optcorr2022(gtdata, CPIIndex()),
    "Combinación lineal óptima CORR" =>  vcat(fill(missing, 11), optcorr2022(gtdata))
)

# MSE_optimization_final_weights
temp1 = components(optmse2022).weights
temp2 = components(optmse2022).measure
temp1 = reshape(temp1, (1,7))
MSE_optimization_final_weights = DataFrame(temp1,temp2)

# ABSME_optimization_final_weights
temp1 = components(optabsme2022)[[5,6,1,3,4,7,2],:].weights   #Para orden correcto
temp2 = components(optabsme2022)[[5,6,1,3,4,7,2],:].measure   #Para orden correcto
temp1 = reshape(temp1, (1,7))
ABSME_optimization_final_weights = DataFrame(temp1,temp2)

# CORR_optimization_final_weights
temp1 = components(optcorr2022)[[4,1,6,3,2,7,5],:].weights   #Para orden correcto
temp2 = components(optcorr2022)[[4,1,6,3,2,7,5],:].measure   #Para orden correcto
temp1 = reshape(temp1, (1,7))
CORR_optimization_final_weights = DataFrame(temp1,temp2)

#MSE_optimization_index_components
opt_components = components(optmse2022)
mai_components = components(optmai2018)
df1 = DataFrame(optmse2022.ensemble(gtdata, CPIIndex()), opt_components.measure)
df2 = DataFrame(optmai2018.ensemble(gtdata, CPIIndex()), mai_components.measure)
MSE_optimization_index_components = hcat(df1, df2)
insertcols!(MSE_optimization_index_components, 1, "Fecha" => idx_dates)

#ABSME_optimization_index_components
opt_components = components(optabsme2022)[[5,6,1,3,4,7,2],:]   #Para orden correcto
mai_components = components(optmai2018_absme)
df1 = DataFrame(optabsme2022.ensemble(gtdata, CPIIndex()), opt_components.measure)
df2 = DataFrame(optmai2018_absme.ensemble(gtdata, CPIIndex()), mai_components.measure)
ABSME_optimization_index_components = hcat(df1, df2)
insertcols!(ABSME_optimization_index_components, 1, "Fecha" => idx_dates)

#CORR_optimization_index_components
opt_components = components(optcorr2022)[[4,1,6,3,2,7,5],:]   #Para orden correcto
mai_components = components(optmai2018_corr)
df1 = DataFrame(optcorr2022.ensemble(gtdata, CPIIndex()), opt_components.measure)
df2 = DataFrame(optmai2018_corr.ensemble(gtdata, CPIIndex()), mai_components.measure)
CORR_optimization_index_components = hcat(df1, df2)
insertcols!(CORR_optimization_index_components, 1, "Fecha" => idx_dates)

#MSE_optimization_interannual_components
opt_components = components(optmse2022)
mai_components = components(optmai2018)
df1 = DataFrame(optmse2022.ensemble(gtdata), opt_components.measure)
df2 = DataFrame(optmai2018.ensemble(gtdata), mai_components.measure)
MSE_optimization_interannual_components = hcat(df1, df2)
insertcols!(MSE_optimization_interannual_components, 1, "Fecha" => dates)

#ABSME_optimization_interannual_components
opt_components = components(optabsme2022)[[5,6,1,3,4,7,2],:]  #Para orden correcto
mai_components = components(optmai2018_absme)
df1 = DataFrame(optabsme2022.ensemble(gtdata), opt_components.measure)
df2 = DataFrame(optmai2018_absme.ensemble(gtdata), mai_components.measure)
ABSME_optimization_interannual_components = hcat(df1, df2)
insertcols!(ABSME_optimization_interannual_components, 1, "Fecha" => dates)

#CORR_optimization_interannual_components
opt_components = components(optcorr2022)[[4,1,6,3,2,7,5],:]   #Para orden correcto
mai_components = components(optmai2018_corr)
df1 = DataFrame(optcorr2022.ensemble(gtdata), opt_components.measure)
df2 = DataFrame(optmai2018_corr.ensemble(gtdata), mai_components.measure)
CORR_optimization_interannual_components = hcat(df1, df2)
insertcols!(CORR_optimization_interannual_components, 1, "Fecha" => dates)

# MSE_optimization_mai_weights
temp1 = components(optmai2018).weights
temp2 = components(optmai2018).measure
temp1 = reshape(temp1, (1,3))
MSE_optimization_mai_weights = DataFrame(temp1,temp2)

# ABSME_optimization_mai_weights
temp1 = components(optmai2018_absme).weights
temp2 = components(optmai2018_absme).measure
temp1 = reshape(temp1, (1,3))
ABSME_optimization_mai_weights = DataFrame(temp1,temp2)

# CORR_optimization_mai_weights
temp1 = components(optmai2018_corr).weights
temp2 = components(optmai2018_corr).measure
temp1 = reshape(temp1, (1,3))
CORR_optimization_mai_weights = DataFrame(temp1,temp2)


## ----------------------------------
# Guardando CSVs

csv_savepath = datadir("results","CSVs")

save_csv(joinpath(csv_savepath, "MSE_optimization.csv"), MSE_optimization)
save_csv(joinpath(csv_savepath, "ABSME_optimization.csv"), ABSME_optimization)
save_csv(joinpath(csv_savepath, "CORR_optimization.csv"), CORR_optimization)

save_csv(joinpath(csv_savepath, "MSE_optimization_final_weights.csv"), MSE_optimization_final_weights)
save_csv(joinpath(csv_savepath, "ABSME_optimization_final_weights.csv"), ABSME_optimization_final_weights)
save_csv(joinpath(csv_savepath, "CORR_optimization_final_weights.csv"), CORR_optimization_final_weights)

save_csv(joinpath(csv_savepath, "MSE_optimization_index_components.csv"), MSE_optimization_index_components)
save_csv(joinpath(csv_savepath, "ABSME_optimization_index_components.csv"), ABSME_optimization_index_components)
save_csv(joinpath(csv_savepath, "CORR_optimization_index_components.csv"), CORR_optimization_index_components)

save_csv(joinpath(csv_savepath, "MSE_optimization_interannual_components.csv"), MSE_optimization_interannual_components)
save_csv(joinpath(csv_savepath, "ABSME_optimization_interannual_components.csv"), ABSME_optimization_interannual_components)
save_csv(joinpath(csv_savepath, "CORR_optimization_interannual_components.csv"), CORR_optimization_interannual_components)

save_csv(joinpath(csv_savepath, "MSE_optimization_mai_weights.csv"), MSE_optimization_mai_weights)
save_csv(joinpath(csv_savepath, "ABSME_optimization_mai_weights.csv"), ABSME_optimization_mai_weights)
save_csv(joinpath(csv_savepath, "CORR_optimization_mai_weights.csv"), CORR_optimization_mai_weights)


## ------------------------------------------------------------------------------
## ------------------------------------------------------------------------- 
# IMPORTANDO ARCHIVOS DE EVALUACION 
# (Para graficas que se cambian una vez al año)

evalmse_savepath = datadir("results","mse-combination","Esc-E-Scramble-OptMAI","optmse2022", "optmse2022_evalresults.jld2")
optmse2022_eval = wload(evalmse_savepath,"optmse_evalresults")

evalabsme_savepath = datadir("results","absme-combination","Esc-G","optabsme2022", "optabsme2022_evalresults.jld2")
optabsme2022_eval = wload(evalabsme_savepath,"optabsme_evalresults")[[6,7,4,5,2,3,1,8],:]  #Para orden correcto

evalcorr_savepath = datadir("results","corr-combination","Esc-F","optcorr2022", "optcorr2022_evalresults.jld2")
optcorr2022_eval = wload(evalcorr_savepath,"optcorr_evalresults")[[6,7,4,5,2,3,1,8],:]  #Para orden correcto

mai_savepath = datadir("results","CoreMai","metrics-2022","opt_mai_eval")
mse_mai = wload(joinpath(mai_savepath,  "optmaimse_evalresults.jld2"), "optmai_mse")
absme_mai = wload(joinpath(mai_savepath,  "optmaiabsme_evalresults.jld2"), "optmai_absme")[[2,3,1],:]  #Para orden correcto
corr_mai = wload(joinpath(mai_savepath,  "optmaicorr_evalresults.jld2"), "optmai_corr")[[3,2,1],:]  #Para orden correcto



## ------------------------------------------------------------------------------
# DATAFRAMES DE EVALUACION 


# MSE y MSE_b10
temp1 = Float32.(optmse2022_eval.mse)
temp2 = String.(optmse2022_eval.measure)
temp1 = reshape(temp1, (1,8))
MSE = DataFrame(temp1,temp2)

temp1 = Float32.(optmse2022_eval.gt_b10_mse)
temp2 = String.(optmse2022_eval.measure)
temp1 = reshape(temp1, (1,8))
MSE_b10 = DataFrame(temp1,temp2)


#ABSME y ABSME_b10
temp1 = Float32.(optabsme2022_eval.absme)
temp2 = String.(optabsme2022_eval.measure)
temp1 = reshape(temp1, (1,8))
ABSME = DataFrame(temp1,temp2)

temp1 = Float32.(optabsme2022_eval.gt_b10_absme)
temp2 = String.(optabsme2022_eval.measure)
temp1 = reshape(temp1, (1,8))
ABSME_b10 = DataFrame(temp1,temp2)


#CORR y CORR_b10
temp1 = Float32.(optcorr2022_eval.corr)
temp2 = String.(optcorr2022_eval.measure)
temp1 = reshape(temp1, (1,8))
CORR = DataFrame(temp1,temp2)

temp1 = Float32.(optcorr2022_eval.gt_b10_corr)
temp2 = String.(optcorr2022_eval.measure)
temp1 = reshape(temp1, (1,8))
CORR_b10 = DataFrame(temp1,temp2)

# MSE_MAI
df1   = vcat(mse_mai,optmse2022_eval[optmse2022_eval.measure.=="MAI óptima MSE 2018",[:measure,:mse]])
temp1 = Float32.(df1.mse)
temp2 = String.(df1.measure)
temp1 = reshape(temp1, (1,4))
MSE_MAI = DataFrame(temp1,temp2)


# ABSME_MAI
df1   = vcat(absme_mai,optabsme2022_eval[optabsme2022_eval.measure.=="MAI óptima de absme 2018",[:measure,:absme]])
temp1 = Float32.(df1.absme)
temp2 = String.(df1.measure)
temp1 = reshape(temp1, (1,4))
ABSME_MAI = DataFrame(temp1,temp2)

# CORR_MAI
df1   = vcat(corr_mai,optcorr2022_eval[optcorr2022_eval.measure.=="MAI óptima de correlación 2018",[:measure,:corr]])
temp1 = Float32.(df1.corr)
temp2 = String.(df1.measure)
temp1 = reshape(temp1, (1,4))
CORR_MAI = DataFrame(temp1,temp2)

## ----------------------------------
# Guardando CSVs

save_csv(joinpath(csv_savepath, "MSE.csv"), MSE)
save_csv(joinpath(csv_savepath, "ABSME.csv"), ABSME)
save_csv(joinpath(csv_savepath, "CORR.csv"), CORR)

save_csv(joinpath(csv_savepath, "MSE_b10.csv"), MSE_b10)
save_csv(joinpath(csv_savepath, "ABSME_b10.csv"), ABSME_b10)
save_csv(joinpath(csv_savepath, "CORR_b10.csv"), CORR_b10)

save_csv(joinpath(csv_savepath, "MSE_MAI.csv"), MSE_MAI)
save_csv(joinpath(csv_savepath, "ABSME_MAI.csv"), ABSME_MAI)
save_csv(joinpath(csv_savepath, "CORR_MAI.csv"), CORR_MAI)
