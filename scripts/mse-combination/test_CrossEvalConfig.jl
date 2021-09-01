using DrWatson
@quickactivate "HEMI" 

using DataFrames

## Se carga el módulo de `Distributed` para computación paralela
using Distributed
nprocs() < 5 && addprocs(4, exeflags="--project")
@everywhere using HEMI 

## Directorios de resultados 
savepath = datadir("results", "mse-combination", "Esc-E")

## Se obtiene la función de inflación, de remuestreo y de tendencia a aplicar
resamplefn = ResampleSBB(36)
trendfn = TrendRandomWalk() 
paramfn = InflationTotalRebaseCPI(60)

inflfn = EnsembleFunction(
    InflationPercentileEq(71.43), 
    InflationPercentileWeighted(69.04), 
    InflationTrimmedMeanEq(43.78, 90), 
    InflationTrimmedMeanWeighted(17.63, 96.2), 
    InflationDynamicExclusion(0.5695, 2.6672), 
    InflationFixedExclusionCPI(
        [35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193, 161, 50, 160, 21, 163, 3, 4, 97, 2, 27, 1, 191, 188], 
        [29, 46, 39, 31, 116]),
    InflationCoreMai(MaiFP([0, 0.29, 0.81, 0.98, 1])), 
    InflationCoreMai(MaiF([0, 0.29, 0.78, 0.98, 1])), 
    InflationCoreMai(MaiG([0, 0.28, 0.39, 0.98, 1])), 
)

CV_PERIODS = (
    EvalPeriod(Date(2013, 1), Date(2014, 12), "cv1314"),
    EvalPeriod(Date(2014, 1), Date(2015, 12), "cv1415"),
    EvalPeriod(Date(2015, 1), Date(2016, 12), "cv1516"),
    EvalPeriod(Date(2016, 1), Date(2017, 12), "cv1617"),
    EvalPeriod(Date(2017, 1), Date(2018, 12), "cv1718")
)

cvconfig = CrossEvalConfig(
    inflfn, 
    resamplefn, 
    trendfn, 
    paramfn, 
    10, 
    CV_PERIODS
)


## Generar datos de simulación para algoritmo de validación cruzada
# La función makesim genera un diccionario con trayectorias de inflación y trayectorias paramétricas generadas datos en diferentes subperíodos. 

# cvdata = makesim(gtdata, cvconfig)
cvdata, _ = produce_or_load(savepath, cvconfig, c -> makesim(gtdata, c))


## Datos de entrenamiento 
TRAIN_DATE = Date(2018,12)
gtdata_train = gtdata[TRAIN_DATE]

## Función para obtener error de validación cruzada utilizando CrossEvalConfig 

function makesimcv(data::CountryStructure, config::CrossEvalConfig, weightsfunction)

    cv_mse = zeros(eltype(data), length(config.evalperiods))

    # Obtener parámetro de inflación 
    param = InflationParameter(config.paramfn, config.resamplefn, config.trendfn)

    for (i, evalperiod) in enumerate(config.evalperiods)
    
        @info "Ejecutando iteración $i de validación cruzada" evalperiod 

        # Obtener los datos de entrenamiento 
        traindate = evalperiod.startdate - Month(1)
        train_data = data[traindate]

        # Obtener trayectorias de inflación y computar ponderaciones 
        train_tray_infl = pargentrayinfl(config.inflfn, config.resamplefn, config.trendfn, train_data; K = config.nsim)
        train_tray_infl_param = param(train_data)
        @info "Datos de entrenamiento:" traindate size(train_tray_infl) size(train_tray_infl_param)

        a = weightsfunction(train_tray_infl, train_tray_infl_param)

        # Generar datos del subperíodo de validación cruzada 
        cvdate = evalperiod.finaldate
        cv_data = data[cvdate]

        cv_tray_infl = pargentrayinfl(config.inflfn, config.resamplefn, config.trendfn, cv_data; K = config.nsim)
        cv_tray_infl_param = param(cv_data)

        @info "Datos de validación:" cvdate size(cv_tray_infl) size(cv_tray_infl_param)

        # Máscara de períodos de evaluación 
        mask = eval_periods(cv_data, evalperiod)

        # Obtener métrica de evaluación en subperíodo de CV 
        cv_tray_infl_opt = sum(cv_tray_infl .* a', dims=2)
        mse_cv = eval_metrics(cv_tray_infl_opt[mask, :, :], cv_tray_infl_param[mask], short=true)[:mse]
        cv_mse[i] = mse_cv

        @info "MSE de validación cruzada:" evalperiod mse_cv
    
    end

    cv_mse

end


cv_ls = makesimcv(gtdata_train, config, combination_weights)
## 
cv_ridge1 = makesimcv(gtdata_train, config, (t,p) -> ridge_combination_weights(t, p, 0.25))
cv_ridge2 = makesimcv(gtdata_train, config, (t,p) -> ridge_combination_weights(t, p, 0.75))
cv_ridge2 = makesimcv(gtdata_train, config, (t,p) -> ridge_combination_weights(t, p, 20))

# AVANCEEEEEEEE
# julia> mean(cv_ls), mean(cv_ridge1), mean(cv_ridge2)
# (1.0202167f0, 1.0926495f0, 0.881017f0)

0.84145176f0
0.7871582f0
0.7758907f0
0.7838515f0
0.80045414f0


##993

map(CV_PERIODS) do period 
    println(period)
end



##

function mm(a; kwargs...)
    @info kwargs
    prekw = Dict(kwargs)
    kw = filter(s -> s != :a, prekw)
    @info kw
    a
end