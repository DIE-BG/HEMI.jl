# # Combinación lineal de estimadores muestrales de inflación MAI
using DrWatson
@quickactivate "HEMI"

using HEMI 
using DataFrames, Chain
using Plots

# Funciones de ayuda 
includet(scriptsdir("mai", "eval-helpers.jl"))

# Obtenemos el directorio de trayectorias resultados 
tray_dir = datadir("results", "CoreMai", "Esc-A", "tray_infl")
plotspath = mkpath(plotsdir("CoreMai"))

# CountryStructure con datos hasta diciembre de 2019
gtdata_eval = gtdata[Date(2019, 12)]


## Obtener las trayectorias de simulación de inflación MAI de variantes F y G
df_mai = collect_results(savepath)

# Obtener variantes de MAI a combinar. Como se trata de los resultados de 2019,
# se combinan todas las versiones F y G
tray_paths = @chain df_mai begin 
    filter(:measure => s -> !occursin("FP",s), _)
    select(:measure, :mse, :path => ByRow(p -> joinpath(tray_dir, basename(p))) => :tray_path)
end

# Obtener las trayectorias 
tray_list_mai = map(tray_paths.tray_path) do path
    tray_infl = load(path, "tray_infl")
end

# Obtener el arreglo de 3 dimensiones de trayectorias (T, 10, K)
tray_infl_mai = reduce(hcat, tray_list_mai)


## Obtener trayectoria paramétrica de inflación 

resamplefn = df_mai[1, :resamplefn]
trendfn = df_mai[1, :trendfn]
paramfn = df_mai[1, :paramfn]
param = InflationParameter(paramfn, resamplefn, trendfn)
tray_infl_pob = param(gtdata_eval)


## Algoritmo de combinación para ponderadores óptimos

# Obtener los ponderadores de combinación óptimos para el cubo de trayectorias
# de inflación MAI 
a_optim = combination_weights(tray_infl_mai, tray_infl_pob)

dfweights = DataFrame(
    measure = tray_paths.measure, 
    weight = a_optim
)

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
@info "Métricas de evaluación:" metrics...