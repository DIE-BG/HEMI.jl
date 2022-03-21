using DrWatson
@quickactivate "HEMI" 
using HEMI 
using JLD2

## Parallel processing
using Distributed
nprocs() < 5 && addprocs(4, exeflags="--project")
@everywhere using HEMI 

## Otras librerías
using DataFrames, Chain
using Plots

## Directorios de resultados 
data_savepath = datadir("results", "core-no-trans", "data", "NOT_data.jld2")
config_savepath = datadir("results", "core-no-trans", "mse-combination")
tray_dir = datadir(config_savepath, "tray_infl")

# CountryStructure con datos de no transables 
NOT_GTDATA = load(data_savepath, "NOT_GTDATA")
gtdata_all = UniformCountryStructure(GTDATA[2])
gtdata_eval = NOT_GTDATA[Date(2020,12)]

# Subyacente óptima MSE 2022 para comparación
include(scriptsdir("mse-combination", "optmse2022.jl"))

##  ----------------------------------------------------------------------------
#   Configuración de simulación para generación de trayectorias de combinación
#   de error cuadrático medio
#   ----------------------------------------------------------------------------

## Se obtiene la función de inflación, de remuestreo y de tendencia a aplicar
resamplefn = ResampleScrambleVarMonths()
trendfn = TrendRandomWalk() 
paramfn = InflationWeightedMean()

# Medidas óptimas a diciembre de 2020

# Configurar el conjunto de medidas a combinar
inflfn = InflationEnsemble(
    InflationPercentileEq(0.763932f0),
    InflationPercentileWeighted(0.7451065f0),
    InflationTrimmedMeanEq(24.053515624999996, 97.28046874999998),
    InflationTrimmedMeanWeighted(39.31861920752279, 97.63786911443505),
    InflationDynamicExclusion(0.30716660097241405, 2.9402031447738386),
)

##  ----------------------------------------------------------------------------
#   Generación de datos de simulación 
#
#   Generar datos de simulación para algoritmo de combinación de valor absoluto
#   de error medio. 
#   ----------------------------------------------------------------------------

config_mse = Dict(
    :inflfn => [inflfn.functions...], 
    :resamplefn => resamplefn, 
    :trendfn => trendfn,
    :paramfn => paramfn, 
    :traindate => Date(2020,12),
    :evalperiods => (CompletePeriod(),),
    :nsim => 10_000) |> dict_list

run_batch(gtdata_eval, config_mse, config_savepath)

## Combinación de error cuadrático medio 
df_results = collect_results(config_savepath)

@chain df_results begin 
    select(:measure, :mse)
end

# DataFrame de combinación 
combine_df = @chain df_results begin 
    select(:measure, :mse, :me, :inflfn, 
        :path => ByRow(p -> joinpath(tray_dir, basename(p))) => :tray_path, 
    )
    sort(:mse)
end

## Obtener las trayectorias de los archivos guardados en el directorio tray_infl 
# Genera un arreglo de 3 dimensiones de trayectorias (T, n, K)
tray_infl = mapreduce(hcat, combine_df.tray_path) do path
    load(path, "tray_infl")
end

## Obtener trayectoria paramétrica de inflación 

resamplefn = df_results[1, :resamplefn]
trendfn = df_results[1, :trendfn]
paramfn = df_results[1, :paramfn]
param = InflationParameter(paramfn, resamplefn, trendfn)
tray_infl_pob = param(gtdata_eval)


## Algoritmo de combinación 

functions = combine_df.inflfn
# components_mask = [!(fn isa InflationFixedExclusionCPI) for fn in functions]
components_mask = [!(fn isa InflationTrimmedMeanWeighted) for fn in functions]

# Filtro de períodos, optimización de combinación lineal en período dic-2011 - dic-2020
combine_period = EvalPeriod(Date(2011, 12), Date(2020, 12), "combperiod") 
periods_filter = eval_periods(gtdata_eval, combine_period)

# Combinación de estimadores para minimizar el MSE
a_optim = share_combination_weights(tray_infl[periods_filter, components_mask, :], tray_infl_pob[periods_filter],
    show_status = true
)
a_optim = combination_weights(tray_infl[periods_filter, components_mask, :], tray_infl_pob[periods_filter])

dfweights = DataFrame(
    measure = combine_df.measure[components_mask], 
    weight = a_optim, 
    inflfn = functions[components_mask]
)

# Combinación lineal óptima para error cuadrático medio
optmsenot2022 = InflationCombination(
    # dfweights.inflfn..., infxexc,
    # Float32[dfweights.weight..., 0], 
    dfweights.inflfn..., 
    dfweights.weight,
    "Subyacente óptima (no transables) MSE 2022"
)

# Guardar función de inflación 
wsave(datadir(config_savepath, "optmsenot2022", "optmsenot2022.jld2"), "optmsenot2022", optmsenot2022)
optmsenot2022 = wload(datadir(config_savepath, "optmsenot2022", "optmsenot2022.jld2"), "optmsenot2022")

## Trayectorias históricas

optmse_periods = eval_periods(GTDATA, EvalPeriod(Date(2011,12), Date(2022,02), ""))

historic_df = DataFrame(
    dates = infl_dates(NOT_GTDATA), 
    optmse2022 = optmse2022(GTDATA)[optmse_periods],
    optmsenot2022 = optmsenot2022(NOT_GTDATA)
)
println(historic_df)

## Grafica de trayectorias y comparación con óptima MSE 

p1 = plot(InflationTotalCPI(), GTDATA)
plot!(optmsenot2022, NOT_GTDATA)
plot!(optmse2022, GTDATA)

p2 = plot(InflationTotalCPI(), GTDATA)
plot!(optmsenot2022.ensemble, NOT_GTDATA)

plot(p1, p2, 
    size = (800, 600),
    layout=(1,2)
)