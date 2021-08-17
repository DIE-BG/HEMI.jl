# # Combinación lineal de estimadores muestrales de inflación MAI
using DrWatson
@quickactivate "HEMI"

using HEMI 
using DataFrames, Chain, PrettyTables
using Optim
using Plots

# Funciones de ayuda 
includet(scriptsdir("mai", "mai-optimization.jl"))

# Configuración de fechas final
EVALDATE = Date(2020,12)
SCENARIO = "C" * Dates.format(EVALDATE, "yy")

# Obtenemos el directorio de trayectorias resultados 
savepath = datadir("results", "CoreMai", "Esc-C", SCENARIO, "bestOptim")
tray_dir = datadir(savepath, "tray_infl")
plotspath = mkpath(plotsdir("CoreMai", "Esc-C", SCENARIO))

# CountryStructure con datos hasta EVALDATE
gtdata_eval = gtdata[EVALDATE]


## Obtener las trayectorias de simulación de inflación MAI de variantes F y G
df_mai = collect_results(savepath)

# Obtener variantes de MAI a combinar
combine_df = @chain df_mai begin 
    # filter(:measure => s -> !occursin("G",s), _)
    select(:measure, :mse, :inflfn, :path => ByRow(p -> joinpath(tray_dir, basename(p))) => :tray_path)
    sort(:mse)
end

# Obtener las trayectorias de los archivos guardados en el directorio tray_infl 
tray_list_mai = map(combine_df.tray_path) do path
    tray_infl = load(path, "tray_infl")
end

# Obtener el arreglo de 3 dimensiones de trayectorias (T, n, K)
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

n = size(tray_infl_mai, 2)
msefnwdata!(F, G, a) = msefn!(F, G, a, tray_infl_mai, tray_infl_pob)
optres = Optim.optimize(
    Optim.only_fg!(msefnwdata!), # Función objetivo = MSE
    rand(Float32, n), # Punto inicial de búsqueda 
    Optim.LBFGS(), # Algoritmo 
    Optim.Options(show_trace = true)) 

a_optim_iter = Optim.minimizer(optres)

println(optres)
println(a_optim_iter)
@info "Resultados de optimización:" min_mse=minimum(optres) iterations=Optim.iterations(optres)


## Conformar un DataFrame de ponderadores y guardarlos en un directorio 

dfweights = DataFrame(
    measure = combine_df.measure, 
    analytic_weight = a_optim, 
    iter_weight = a_optim_iter
)

weightsfile = datadir(savepath, "mse-weights", "mai-mse-weights.jld2")
wsave(weightsfile, "mai_mse_weights", a_optim)

## Evaluación de combinación lineal óptima 

# a_optim = ones(Float32, n) / n
# a_optim = a_optim_iter
tray_infl_maiopt = sum(tray_infl_mai .* a_optim', dims=2)

# Estadísticos 
metrics = eval_metrics(tray_infl_maiopt, tray_infl_pob)
@info "Métricas de evaluación:" metrics...

## Generación de gráfica de trayectoria histórica 

tray_infl_mai_obs = mapreduce(inflfn -> inflfn(gtdata), hcat, combine_df.inflfn)
tray_infl_maiopt = tray_infl_mai_obs * a_optim

plot(InflationTotalCPI(), gtdata)
plot!(infl_dates(gtdata), tray_infl_maiopt, 
    label="Combinación lineal óptima MSE MAI ($SCENARIO)", 
    legend=:topright)

savefig(plotsdir(plotspath, "MAI-optima-bestOptim-MSE-$SCENARIO.svg"))

## Tablas de resultados 

combined_metrics = DataFrame(metrics)
combined_metrics.measure = ["Combinación MAI"]
combined_metrics

# Resultados principales 
main_results = @chain df_mai begin 
    select(:measure, :mse, :mse_std_error)
    sort(:mse)
    [_; select(combined_metrics, :measure, :mse, :mse_std_error)]
end

# Descomposición del MSE 
mse_decomp = @chain df_mai begin 
    select(:measure, :mse, r"mse_[bvc]")
    [_; select(combined_metrics, :measure, :mse, r"mse_[bvc]")]
end 

# Otras métricas 
sens_metrics = @chain df_mai begin 
    select(:measure, :rmse, :me, :mae, :huber, :corr)
    [_; select(combined_metrics, :measure, :rmse, :me, :mae, :huber, :corr)]
end 

# Tabla de ponderadores analíticos 
weights_results = @chain dfweights begin 
    select(:measure, :analytic_weight)
end

pretty_table(main_results, tf=tf_markdown, formatters=ft_round(4))
pretty_table(mse_decomp, tf=tf_markdown, formatters=ft_round(4))
pretty_table(sens_metrics, tf=tf_markdown, formatters=ft_round(4))
pretty_table(weights_results, tf=tf_markdown, formatters=ft_round(4))