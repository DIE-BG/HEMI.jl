# # Combinación lineal de estimadores muestrales de inflación MAI
using DrWatson
@quickactivate "HEMI"

using HEMI 
using DataFrames, Chain
using Optim
using Plots

# Funciones de ayuda 
includet(scriptsdir("mai", "Esc-A", "eval-helpers.jl"))

# Obtenemos el directorio de trayectorias resultados 
savepath = datadir("results", "CoreMai", "Esc-A")
tray_dir = datadir(savepath, "tray_infl")
plotspath = mkpath(plotsdir("CoreMai"))

# CountryStructure con datos hasta diciembre de 2019
gtdata_eval = gtdata[Date(2019, 12)]


## Obtener las trayectorias de simulación de inflación MAI de variantes F y G
df_mai = collect_results(savepath)

# Obtener variantes de MAI a combinar. Como se trata de los resultados de 2019,
# se combinan todas las versiones F y G
combine_df = @chain df_mai begin 
    filter(:measure => s -> !occursin("FP",s), _)
    select(:measure, :mse, :inflfn, :path => ByRow(p -> joinpath(tray_dir, basename(p))) => :tray_path)
    sort(:mse)
end

# Obtener las trayectorias de los archivos guardados en el directorio tray_infl 
tray_list_mai = map(combine_df.tray_path) do path
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

## Optimización iterativa con Optim 

msefnwdata!(F, G, a) = msefn!(F, G, a, tray_infl_mai, tray_infl_pob)
optres = Optim.optimize(
    Optim.only_fg!(msefnwdata!), # Función objetivo = MSE
    rand(Float32, 10), # Punto inicial de búsqueda 
    Optim.LBFGS(), # Algoritmo 
    Optim.Options(show_trace = true)) 

a_optim_iter = Optim.minimizer(optres)

println(optres)
println(a_optim_iter)
@info "Resultados de optimización:" min_mse=minimum(optres) iterations=Optim.iterations(optres)


## Conformar un DataFrame de ponderadores 

dfweights = DataFrame(
    measure = combine_df.measure, 
    analytic_weight = a_optim, 
    iter_weight = a_optim_iter
)


## Evaluación de combinación lineal óptima 

# a_optim = ones(Float32, 10) / 10
# a_optim = a_optim_iter
tray_infl_maiopt = sum(tray_infl_mai .* a_optim', dims=2)

# Estadísticos 
metrics = eval_metrics(tray_infl_maiopt, tray_infl_pob)
@info "Métricas de evaluación:" metrics...


## Prueba con funciones sin utilización de inplace 
#=
function mseonly(w, tray_infl, tray_infl_pob) 
    # Trayectoria promedio ponderado entre las medidas a combinar
    tray_infl_comb = sum(tray_infl .* w', dims=2)

    # Definición del error como función de los ponderadores
    err_t_k =  tray_infl_comb .- tray_infl_pob

    # Función objetivo
    # Definición del MSE promedio en función de los ponderadores
    mse_prom = mean(err_t_k .^ 2)
    mse_prom
end

function gradonly(w, tray_infl, tray_infl_pob) 
    # Trayectoria promedio ponderado entre las medidas a combinar
    tray_infl_comb = sum(tray_infl .* w', dims=2)

    # Definición del error como función de los ponderadores
    err_t_k =  tray_infl_comb .- tray_infl_pob

    # Cómputo de gradientes
    mse_grad = 2 * vec(mean(err_t_k .* tray_infl, dims=[1, 3]))
    mse_grad
end

optres = optimize(
    a -> mseonly(a, tray_infl_mai, tray_infl_pob), 
    a -> gradonly(a, tray_infl_mai, tray_infl_pob), 
    ones(Float32, 10) / 10; 
    inplace = false, show_trace = true)
=#

## Generación de gráfica de trayectoria histórica 

tray_infl_mai_obs = mapreduce(inflfn -> inflfn(gtdata), hcat, combine_df.inflfn)
tray_infl_maiopt = tray_infl_mai_obs * a_optim

plot(InflationTotalCPI(), gtdata)
plot!(infl_dates(gtdata), tray_infl_maiopt, 
    label="Combinación lineal óptima MSE MAI", 
    legend=:topright)

savefig(plotsdir(plotspath, "MAI-optima-MSE.svg"))