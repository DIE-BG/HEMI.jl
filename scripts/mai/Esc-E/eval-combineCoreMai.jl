# # Combinación lineal de estimadores muestrales de inflación MAI
using DrWatson
@quickactivate "HEMI"

using HEMI 
using DataFrames, Chain, PrettyTables
using Optim
using Plots

# Funciones de ayuda 
includet(scriptsdir("mai", "mai-optimization.jl"))
includet(scriptsdir("mse-combination-2019", "optmse2019.jl"))

# Configuración de escenario
EVALDATE = Date(2018,12)
PARAMSCENARIO = 60
SCENARIO = "E" * Dates.format(EVALDATE, "yy") * "-" * string(PARAMSCENARIO)
@info "Escenario de evaluación:" SCENARIO

# Obtenemos el directorio de trayectorias resultados 
savepath = datadir("results", "CoreMai", "Esc-E", "Standard")
tray_dir = datadir(savepath, "tray_infl")
plotspath = mkpath(plotsdir("CoreMai", "Esc-E", "Standard"))
weightsfile = datadir(savepath, "mse-weights", "mai-mse-weights.jld2")

# CountryStructure con datos hasta EVALDATE
gtdata_eval = gtdata[EVALDATE]


## Obtener las trayectorias de simulación de inflación MAI de variantes F y G
df_mai = collect_results(savepath)

# Obtener variantes de MAI a combinar. Se combinan únicamente variantes F y G
# como punto de comparación con los resultados de 2019
combine_df = @chain df_mai begin 
    filter(r -> r.traindate == EVALDATE, _)
    transform(
        :inflfn => ByRow(fn -> fn.method.n) => :nseg,
        :measure => ByRow(s -> match(r"MAI \((\w+)", s).captures[1]) => :maitype)
    sort([:maitype, :nseg])
    # filter(:measure => s -> !occursin("FP,",s), _)
    filter(r -> r.nseg in [4,5,10,20,40], _)
    select(:measure, :mse, :inflfn, :path => ByRow(p -> joinpath(tray_dir, basename(p))) => :tray_path)
end

# Obtener el arreglo de 3 dimensiones de trayectorias (T, n, K)
tray_infl_mai = mapreduce(hcat, combine_df.tray_path) do path
    tray_infl = load(path, "tray_infl")
    tray_infl
end

## Obtener trayectoria paramétrica de inflación 

resamplefn = df_mai[1, :resamplefn]
trendfn = df_mai[1, :trendfn]
paramfn = df_mai[1, :paramfn]
param = InflationParameter(paramfn, resamplefn, trendfn)
tray_infl_pob = param(gtdata_eval)


## Algoritmo de combinación para ponderadores óptimos

# Obtener los ponderadores de combinación óptimos para el cubo de trayectorias
# de inflación MAI 

# a_optim = combination_weights(tray_infl_mai, tray_infl_pob)
a_optim = ridge_combination_weights(tray_infl_mai, tray_infl_pob, 2.5)

## Conformar un DataFrame de ponderadores y guardarlos en un directorio 

dfweights = DataFrame(
    measure = combine_df.measure, 
    inflfn = combine_df.inflfn,
    analytic_weight = a_optim, 
)

wsave(weightsfile, "mai_mse_weights", dfweights)

## Evaluación de combinación lineal óptima 

periods_mask = eval_periods(gtdata_eval, GT_EVAL_B10)
# periods_mask = eval_periods(gtdata_eval, CompletePeriod())

# a_optim = combination_weights(tray_infl_mai[periods_mask, :, :], tray_infl_pob[periods_mask])
# a_optim = ridge_combination_weights(tray_infl_mai[periods_mask, :, :], tray_infl_pob[periods_mask], 1.75)

# a_optim = combination_weights(tray_infl_mai, tray_infl_pob)
a_optim = ridge_combination_weights(tray_infl_mai, tray_infl_pob, 2.5)

tray_infl_maiopt = sum(tray_infl_mai .* a_optim', dims=2)
m_tray_infl_opt = vec(mean(tray_infl_maiopt, dims=3))

metrics = eval_metrics(tray_infl_maiopt[periods_mask, :, :], tray_infl_pob[periods_mask])
@info "Métricas de evaluación:" metrics...

ks = 100
plot(infl_dates(gtdata_eval), reshape(tray_infl_maiopt[:, :, 1:ks], :, ks), 
    label = false, 
    alpha = 0.3, 
    color = :gray
)
plot!(infl_dates(gtdata_eval), tray_infl_pob, 
    linewidth = 2,
    color = :blue,
    label = "Inflación paramétrica"
)
plot!(infl_dates(gtdata_eval), m_tray_infl_opt, 
    linewidth = 2,
    color = :red,
    label = "Trayectoria promedio"
)
# savefig(joinpath(plotspath, "ls.svg"))


## Generación de gráfica de trayectoria histórica 

a_optim = ridge_combination_weights(tray_infl_mai, tray_infl_pob, 2.5)

tray_infl_mai_obs = mapreduce(inflfn -> inflfn(gtdata), hcat, combine_df.inflfn)
tray_infl_maiopt = tray_infl_mai_obs * a_optim

fdate = Dates.format(EVALDATE, "uyy")
plot(InflationTotalCPI(), gtdata)
plot!(optmai2019, gtdata)
plot!(infl_dates(gtdata), tray_infl_maiopt, 
    linewidth = 2,
    label = "Combinación lineal óptima MSE MAI ($SCENARIO)", 
    legend = :topright)

# savefig(plotsdir(plotspath, savename("MAI-optima-MSE", (@dict SCENARIO), "svg")))


## Tablas de resultados 

combined_metrics = DataFrame(metrics)
combined_metrics.measure = ["Combinación MAI"]
combined_metrics

# Resultados principales 
main_results = @chain combined_metrics begin 
    select(:measure, :mse, :mse_std_error)
end

# Descomposición del MSE 
mse_decomp = @chain combined_metrics begin 
    select(:measure, :mse, r"^mse_[bvc]")
    select(:measure, :mse, :mse_bias, :mse_var, :mse_cov)
end 

# Otras métricas 
sens_metrics = @chain combined_metrics begin 
    select(:measure, :rmse, :me, :mae, :huber, :corr)
end 

# Tabla de ponderadores analíticos 
weights_results = @chain dfweights begin 
    select(:measure, :analytic_weight)
end

# Impresión de resultados en Markdown
pretty_table(main_results, tf=tf_markdown, formatters=ft_round(4))
pretty_table(mse_decomp, tf=tf_markdown, formatters=ft_round(4))
pretty_table(sens_metrics, tf=tf_markdown, formatters=ft_round(4))
pretty_table(weights_results, tf=tf_markdown, formatters=ft_round(4))