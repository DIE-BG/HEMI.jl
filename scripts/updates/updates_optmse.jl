using DrWatson
@quickactivate "HEMI"

using HEMI 
using DataFrames, CSV

# Actualizar datos
@info "Actualizando archivo de datos"
include(scriptsdir("load_data.jl"))
HEMI.load_data()

# Óptima MSE 2020
include(scriptsdir("mse-combination", "optmse2022.jl"))

# Generar la trayectoria observada 
dates = infl_dates(gtdata) 
df_optmse = DataFrame(
    dates = dates[1] - Month(11): Month(1) : dates[end],
    i_optmse = optmse2022(gtdata, CPIIndex()), 
    m_optmse = optmse2022(gtdata, CPIVarInterm()), 
    a_optmse = vcat(repeat([missing], 11), optmse2022(gtdata))
)

last(df_optmse, 5)

# Tabla de componentes y ponderaciones 
df_comp = components(optmse2022)

# Obtener componentes interanuales 
df_components = DataFrame(optmse2022.ensemble(gtdata), df_comp.measure)
insertcols!(df_components, 1, :dates => dates)


# Guardar los resultados 
savepath = mkpath(datadir("updates"))

@info "Guardando archivos de resultados"
CSV.write(joinpath(savepath, "optmse2022.csv"), df_optmse)
CSV.write(joinpath(savepath, "optmse2022_components.csv"), df_comp)
CSV.write(joinpath(savepath, "optmse2022_interannual_components.csv"), df_components)
