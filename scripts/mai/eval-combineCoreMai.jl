# # Combinación lineal de estimadores muestrales de inflación MAI
using DrWatson
@quickactivate "HEMI"

using HEMI 
using DataFrames
using Plots

# Funciones de ayuda 
includet(scriptsdir("mai", "eval-helpers.jl"))

# Obtenemos el directorio de trayectorias resultados 
tray_dir = datadir("results", "CoreMai", "tray_infl")
plotspath = mkpath(plotsdir("CoreMai"))

# CountryStructure con datos hasta diciembre de 2020
gtdata_eval = gtdata[Date(2020, 12)]

##
# ## Obtener las trayectorias de simulación de inflación MAI

# Funciones de remuestreo y tendencia
resamplefn = ResampleSBB(36)
trendfn = TrendRandomWalk()

variants = [4, 5, 10, 20, 40]
maifs = [InflationCoreMai(MaiF(i)) for i in variants]
maigs = [InflationCoreMai(MaiG(i)) for i in variants]
inflfns = vcat(maifs, maigs)

config_mai = Dict(
    :inflfn => inflfns, 
    :resamplefn => resamplefn, 
    :trendfn => trendfn,
    :nsim => 125_000) |> dict_list

# Función para obtener el nombre de archivo de una configuración
fn_tray_name = c -> savename(c, "jld2", connector= " - ", equals=" = ")

tray_infl_mai = map(config_mai) do config
    simconf = dict_config(config) 
    # Obtenemos nombre del archivo de trayectorias y lo cargamos
    filepath = joinpath(tray_dir, fn_tray_name(simconf))
    tray_infl = load(filepath, "tray_infl")
end
# Obtener cubo de trayectorias de simulación 
tray_infl_mai = cat(tray_infl_mai..., dims=2)

# Nombres de las medidas a combinar 
mai_names = map(config_mai) do config 
    simconf = dict_config(config)
    measure_name(simconf.inflfn)
end


##
# ## Obtener trayectoria paramétrica de inflación 

param = ParamTotalCPIRebase(resamplefn, trendfn)
tray_infl_pob = param(gtdata_eval)

##
# ## Algoritmo de combinación para ponderadores óptimos

# Obtener los ponderadores de combinación óptimos para el cubo de trayectorias
# de inflación MAI 
a_optim = combination_weights(tray_infl_mai, tray_infl_pob)

# Ejercicio de combinación sin la variante F-40
# tray_infl_nof40 = tray_infl_mai[:, [1,2,3,4,6,7,8,9,10], :]
# a_optimsens = combination_weights(tray_infl_nof40, tray_infl_pob)
# tray_infl_maisens = sum(tray_infl_nof40 .* a_optimsens', dims=2)
# metrics_sens = eval_metrics(tray_infl_maisens, tray_infl_pob)

a_df = DataFrame(measure = mai_names, weight = a_optim)

# Gráfica de ponderadores 
bar(a_df.measure, a_df.weight, 
    label="Ponderadores óptimos MSE", 
    xrotation=45)
savefig(plotsdir(plotspath, "opt_weights_mai"))

##
# ## Evaluación de combinación lineal óptima 

tray_infl_maiopt = sum(tray_infl_mai .* a_optim', dims=2)

## Estadísticos 

metrics = eval_metrics(tray_infl_maiopt, tray_infl_pob)
@info "Métricas de evaluación:" metrics

# ┌ Info: Métricas de evaluación:
# │   metrics =
# │    Dict{Symbol, AbstractFloat} with 6 entries:
# │      :rmse          => 1.20281
# │      :mse           => 2.53356
# │      :mae           => 1.20281
# │      :std_sim_error => 0.0122459
# │      :me            => -0.328675
# └      :corr          => 0.836101