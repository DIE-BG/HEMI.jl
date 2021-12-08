using DrWatson
@quickactivate "HEMI"

using HEMI 
using DataFrames, CSV, StringEncodings

# Actualizar datos
@info "Actualizando archivo de datos"
include(scriptsdir("load_data.jl"))
HEMI.load_data()

# Helper functions
include(joinpath(@__DIR__, "updates_helpers.jl"))

## Óptima MSE 2020
include(scriptsdir("mse-combination", "optmse2022.jl"))

# Generar la trayectoria observada 
dates = infl_dates(gtdata) 
df_obs_optmse = DataFrame(
    dates = dates[1] - Month(11): Month(1) : dates[end],
    i_optmse = optmse2022(gtdata, CPIIndex()), 
    m_optmse = optmse2022(gtdata, CPIVarInterm()), 
    a_optmse = vcat(fill(missing, 11), optmse2022(gtdata))
)

println(last(df_obs_optmse, 5))

# Tabla de componentes y ponderaciones 
optmse_components = components(optmse2022)

# Obtener componentes interanuales 
optmse_obs_components = DataFrame(optmse2022.ensemble(gtdata), optmse_components.measure)
insertcols!(optmse_obs_components, 1, :dates => dates)


## Componentes MAI óptima 

# DataFrame de componentes
mai_components = components(optmai2018)
# Variaciones interanuales
mai_obs_components = DataFrame(optmai2018.ensemble(gtdata), mai_components.measure)
insertcols!(mai_obs_components, 1, :dates => dates)


## Intervalos de confianza 

# Obtener intervalos de confianza
df_obs_optmse_ci = get_ci(df_obs_optmse, optmse2022_ci)


## Guardar los resultados 
savepath = mkpath(datadir("updates"))

@info "Guardando archivos de resultados"
save_csv(joinpath(savepath, "optmse2022.csv"), df_obs_optmse)
save_csv(joinpath(savepath, "optmse2022_components.csv"), optmse_components)
save_csv(joinpath(savepath, "optmse2022_interannual_components.csv"), optmse_obs_components)
save_csv(joinpath(savepath, "optmse2022_mai_components.csv"), mai_components)
save_csv(joinpath(savepath, "optmse2022_mai_interannual_components.csv"), mai_obs_components)
save_csv(joinpath(savepath, "optmse2022_confidence_intervals_97.5.csv"), df_obs_optmse_ci)
