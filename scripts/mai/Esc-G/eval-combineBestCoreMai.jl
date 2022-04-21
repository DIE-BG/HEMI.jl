# # Combinación lineal de estimadores muestrales de inflación MAI
using DrWatson
@quickactivate "HEMI"

using HEMI 
using DataFrames, Chain, PrettyTables
using Optim
using Plots


# Configuración de escenario
EVALDATE = Date(2018, 12)
PARAMSCENARIO = 36
SCENARIO = "G18"
@info "Escenario de evaluación:" SCENARIO

# Obtenemos el directorio de trayectorias resultados 
savepath = datadir("results", "CoreMai", "Esc-G", "BestOptim")
tray_dir = datadir(savepath, "tray_infl")
plotspath = mkpath(plotsdir("CoreMai", "Esc-G"))

# CountryStructure con datos hasta EVALDATE
gtdata_eval = gtdata[EVALDATE]


## Obtener las trayectorias de simulación de inflación MAI de variantes F y G
df_mai = collect_results(savepath)

# Obtener variantes de MAI a combinar
combine_df = @chain df_mai begin 
    select(:measure, :absme, :inflfn, :path => ByRow(p -> joinpath(tray_dir, basename(p))) => :tray_path)
    sort(:absme)
end

## Obtener las trayectorias de los archivos guardados en el directorio tray_infl 
# Genera un arreglo de 3 dimensiones de trayectorias (T, n, K)
tray_infl_mai = mapreduce(hcat, combine_df.tray_path) do path
    load(path, "tray_infl")
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

# Combinar las variantes MAI para valor absoluto de error medio ... (to-do)
a_optim = metric_combination_weights(tray_infl_mai, tray_infl_pob,
    metric =:absme,
    max_iterations = 250
)


## Conformar un DataFrame de ponderadores y guardarlos en un directorio 

dfweights = DataFrame(
    measure = combine_df.measure, 
    analytic_weight = a_optim, 
    inflfn = combine_df.inflfn
)

# Guardar el DataFrame de medidas y ponderaciones 
wsave(datadir(savepath, "absme-weights", "dfweights.jld2"), "dfweights", dfweights)

# Guardar el vector de ponderaciones 
weightsfile = datadir(savepath, "absme-weights", "mai-absme-weights.jld2")
wsave(weightsfile, "mai_absme_weights", a_optim)

# Guardar la función de inflación MAI óptima 
maioptfn = InflationCombination(
    dfweights.inflfn...,
    dfweights.analytic_weight, 
    "MAI óptima de absme 2018"
)

wsave(datadir(savepath, "absme-weights", "maioptfn.jld2"), "maioptfn", maioptfn)


## Evaluación de combinación lineal óptima 

a_optim = wload(weightsfile, "mai_absme_weights")
dfweights = wload(datadir(savepath, "absme-weights", "dfweights.jld2"), "dfweights")
maioptfn = wload(datadir(savepath, "absme-weights", "maioptfn.jld2"), "maioptfn")

tray_infl_maiopt = sum(tray_infl_mai .* a_optim', dims=2)
# mask_periods = eval_periods(gtdata_eval, GT_EVAL_B00)
# mask_periods = eval_periods(gtdata_eval, GT_EVAL_B10)
# mask_periods = eval_periods(gtdata_eval, GT_EVAL_T0010)
mask_periods = eval_periods(gtdata_eval, CompletePeriod())
metrics = eval_metrics(tray_infl_maiopt[mask_periods, :, :], tray_infl_pob[mask_periods])
@info "Métricas de evaluación:" metrics...

## Generación de gráfica de trayectoria histórica 

plot(InflationTotalCPI(), gtdata)
plot!(maioptfn, gtdata, 
    label="Combinación lineal MAI óptima de absme ($SCENARIO)", 
    legend=:topright)

savefig(plotsdir(plotspath, "MAI-optima-bestOptim-ABSME-$SCENARIO.svg"))

## Tablas de resultados 

combined_metrics = DataFrame(metrics)
combined_metrics.measure = ["Combinación MAI"]
combined_metrics

# Resultados principales 
main_results = @chain df_mai begin 
    select(:measure, :absme, :mse_std_error)
    sort(:absme)
    [_; select(combined_metrics, :measure, :absme, :mse_std_error)]
end

# Descomposición del ABSME
mse_decomp = @chain df_mai begin 
    select(:measure, :absme, r"^mse_[bvc]")
    [_; select(combined_metrics, :measure, :absme, :mse_bias, :mse_var, :mse_cov)]
    select(:measure, :absme, :mse_bias, :mse_var, :mse_cov)
end 

# Otras métricas 
sens_metrics = @chain df_mai begin 
    select(:measure, :rmse, :me, :mae, :huber, :absme)
    [_; select(combined_metrics, :measure, :rmse, :me, :mae, :huber, :absme)]
end 

# Tabla de ponderadores analíticos 
weights_results = @chain dfweights begin 
    select(:measure, :analytic_weight)
end

pretty_table(main_results, tf=tf_markdown, formatters=ft_round(4))
pretty_table(mse_decomp, tf=tf_markdown, formatters=ft_round(4))
pretty_table(sens_metrics, tf=tf_markdown, formatters=ft_round(4))
pretty_table(weights_results, tf=tf_markdown, formatters=ft_round(4))


## Revisión de métodos 

@chain combine_df begin 
    select(:measure, :absme, 
        :inflfn => ByRow(fn -> fn.method.p) => :q, 
    )
    select(:, 
        :q => ByRow(q -> q[2]) => :q_first, 
        :q => ByRow(q -> q[end-1]) => :q_last, 
    )
end

qopt = map(combine_df.inflfn) do fn 
    fn.method.p
end
