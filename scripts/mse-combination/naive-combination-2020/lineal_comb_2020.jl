using DrWatson
@quickactivate "HEMI" 
using HEMI 
using DataFrames, PrettyTables
using Plots

## Se carga el módulo de `Distributed` para computación paralela
using Distributed
nprocs() < 5 && addprocs(4, exeflags="--project")
@everywhere using HEMI 

## Directorios de resultados 
data_savepath = datadir("results", "mse-combination", "naive-2020", "data")
plots_path = mkpath(plotsdir("mse-combination", "naive-2020"))

# Función de inflación óptima MSE 2019
include(scriptsdir("mse-combination-2019", "optmse2019.jl"))

##  ----------------------------------------------------------------------------
#   Configuración para generación de trayectorias para combinación lineal
#   ----------------------------------------------------------------------------

# Datos de evaluación a diciembre de 2020
evaldata = gtdata[Date(2020, 12)]

## Se obtiene la función de inflación, de remuestreo y de tendencia a aplicar
resamplefn = ResampleScrambleVarMonths()
trendfn = TrendRandomWalk() 
paramfn = InflationTotalRebaseCPI(36, 2)

# Medidas óptimas a diciembre de 2020, variantes MAI a combinar 
inflfn = InflationEnsemble(
    InflationPercentileEq(72), 
    InflationPercentileWeighted(70), 
    InflationTrimmedMeanEq(58.76, 83.15), 
    InflationTrimmedMeanWeighted(21.0, 95.89), 
    InflationDynamicExclusion(0.3243, 1.7657), 
    InflationFixedExclusionCPI(
        [35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193, 161], 
        [29, 46, 39, 31, 116, 40, 30, 186, 35, 47, 197, 41, 22, 185, 48, 34, 37, 184]),
    InflationCoreMai(MaiF(4)),
    InflationCoreMai(MaiF(5)),
    InflationCoreMai(MaiF(10)),
    InflationCoreMai(MaiF(20)),
    InflationCoreMai(MaiF(40)),
    InflationCoreMai(MaiG(4)),
    InflationCoreMai(MaiG(5)),
    InflationCoreMai(MaiG(10)),
    InflationCoreMai(MaiG(20)),
    InflationCoreMai(MaiG(40)),
)

config = SimConfig(inflfn, resamplefn, trendfn, paramfn, 10_000, Date(2020, 12))

##  ----------------------------------------------------------------------------
#   Parámetro de inflación 
#   ----------------------------------------------------------------------------

param = InflationParameter(paramfn, resamplefn, trendfn)
tray_infl_param = param(evaldata)

##  ----------------------------------------------------------------------------
#   Generación de trayectorias y guardado de resultados
#   ----------------------------------------------------------------------------

# Cargar o producir las trayectorias para su combinación
data, _ = produce_or_load(data_savepath, config) do config 

    # Diccionario de resultados
    results = Dict{String, Any}()

    # Generar trayectorias de inflación 
    results["tray_infl"] = pargentrayinfl(
        config.inflfn, 
        config.resamplefn,
        config.trendfn, 
        evaldata; K = config.nsim)
    results
end

tray_infl = data["tray_infl"]

##  ----------------------------------------------------------------------------
#   Obtener combinación óptima MAI
#   ----------------------------------------------------------------------------

# Máscara de funciones de inflación MAI
mai_mask = [fn isa InflationCoreMai for fn in inflfn.functions]

# Trayectorias de variantes de inflación MAI
tray_infl_mai_indv = @view tray_infl[:, mai_mask, :]

# Obtener ponderaciones óptimas MAI MSE
mai_weights = combination_weights(tray_infl_mai_indv, tray_infl_param)
wsave(joinpath(data_savepath, "mai_weights.jld2"), "mai_weights", mai_weights)

# Trayectorias de inflación MAI óptima MSE
tray_infl_mai = sum(tray_infl_mai_indv .* mai_weights', dims=2)


##  ----------------------------------------------------------------------------
#   Combinación óptima de medidas de inflación 
#   ----------------------------------------------------------------------------

# Trayectorias de simulación de familias de estimadores
comb_tray_infl = hcat(tray_infl[:, .!mai_mask, :], tray_infl_mai)

# Pesos de combinación óptima de variantes
optmse_weights = combination_weights(comb_tray_infl, tray_infl_param)
wsave(joinpath(data_savepath, "optmse_weights.jld2"), "optmse_weights", optmse_weights)


##  ----------------------------------------------------------------------------
#   Evaluación de combinación óptima 
#   ----------------------------------------------------------------------------

tray_infl_opt = sum(comb_tray_infl .* optmse_weights', dims=2)

metrics = eval_metrics(tray_infl_opt, tray_infl_param)
@info "Métricas de evaluación" metrics...

##  ----------------------------------------------------------------------------
#   Gráfica de trayectorias observada
#   ----------------------------------------------------------------------------

maioptmse2020 = InflationCombination(
    inflfn.functions[mai_mask]..., 
    mai_weights, 
    "MAI óptima MSE 2020"
)

optmse2020 = InflationCombination(
    inflfn.functions[.!mai_mask]..., # Estimadores de inflación sin MAI
    maioptmse2020, 
    optmse_weights, 
    "Subyacente óptima MSE 2020"
)

# Guardar la función de inflación óptima
wsave(joinpath(data_savepath, "optmse2020.jld2"), "optmse2020", optmse2020)


# Gráfica de trayectoria observada y comparación con la óptima de 2019
plotly()
dates = Date(2001, 12):Year(1):Date(2020, 12)

plot(InflationTotalCPI(), gtdata,
    xticks = (dates, Dates.format.(dates, dateformat"u-yy")),
    xrotation = 45
)
plot!(optmse2019, gtdata, linewidth = 2, color = :black)
plot!(optmse2020, gtdata, linewidth = 2, color = :blue)
savefig(joinpath(plots_path, "trajectories.html"))


##  ----------------------------------------------------------------------------
#   Tablas de ponderadores 
#   ----------------------------------------------------------------------------

mai_df = DataFrame(
    measure = measure_name.([inflfn.functions[mai_mask]...]),
    weights = mai_weights
)

optmse_df = DataFrame(
    measure = measure_name.([optmse2020.ensemble.functions...]), 
    weights = optmse_weights
)

pretty_table(mai_df, tf=tf_markdown, formatters=ft_round(4))
pretty_table(optmse_df, tf=tf_markdown, formatters=ft_round(4))
