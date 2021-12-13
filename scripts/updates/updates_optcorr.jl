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
    "Combinación lineal óptima ABSME" =>  vcat(fill(missing, 11), optmse2022(gtdata))
)

# CORR_optimization
CORR_optimization = DataFrame(
    "Fecha"  => idx_dates,
    "Índice" => optcorr2022(gtdata, CPIIndex()),
    "Combinación lineal óptima CORR" =>  vcat(fill(missing, 11), optmse2022(gtdata))
)

# MSE_optimization_final_weights
temp1 = components(optmse2022).weights
temp2 = components(optmse2022).measure
temp1 = reshape(temp1, (1,7))
MSE_optimization_final_weights = DataFrame(temp1,temp2)

# ABSME_optimization_final_weights
temp1 = components(optabsme2022).weights
temp2 = components(optabsme2022).measure
temp1 = reshape(temp1, (1,7))
ABSME_optimization_final_weights = DataFrame(temp1,temp2)

# CORR_optimization_final_weights
temp1 = components(optcorr2022).weights
temp2 = components(optcorr2022).measure
temp1 = reshape(temp1, (1,7))
CORR_optimization_final_weights = DataFrame(temp1,temp2)

#MSE_optimization_index_components
opt_components = components(optmse2022)
mai_components = components(optmai2018)
df1 = DataFrame(optmse2022.ensemble(gtdata, CPIIndex()), opt_components.measure)
df2 = DataFrame(optmai2018.ensemble(gtdata, CPIIndex()), mai_components.measure)
MSE_optimization_index_components = hcat(df1, df2)
insertcols!(MSE_optimization_index_components, 1, "Fecha" => idx_dates)




