using DrWatson
@quickactivate "HEMI" 
using HEMI 

## Parallel processing
using Distributed
nprocs() < 5 && addprocs(4, exeflags="--project")
@everywhere using HEMI 

## Other libraries
using CSV
using DataFrames, Chain
using StringEncodings
using Plots

## Directorios de resultados 
config_savepath = datadir("results", "CoreMai", "metrics-2022")

# Rutas a funciones de inflación MAI 
opt_corr_mai_path = datadir("results", "CoreMai", "Esc-F", "BestOptim", "corr-weights", "maioptfn.jld2")
opt_absme_mai_path = datadir("results", "CoreMai", "Esc-G", "BestOptim", "absme-weights", "maioptfn.jld2")
opt_mse_mai_path = datadir("results", "CoreMai", "Esc-E-Scramble", "BestOptim", "mse-weights", "maioptfn.jld2")

# CountryStructure con datos hasta período de evaluación 
FINAL_DATE = Date(2020, 12)
gtdata_eval = gtdata[FINAL_DATE]

##  ----------------------------------------------------------------------------
#   Configuración de simulación para generación de trayectorias de combinación
#   ----------------------------------------------------------------------------

## Se obtiene la función de inflación, de remuestreo y de tendencia a aplicar
resamplefn = ResampleScrambleVarMonths()
trendfn = TrendRandomWalk() 
paramfn = InflationTotalRebaseCPI(36, 2)

## Medidas óptimas a diciembre de 2018

optmai_mse = wload(opt_mse_mai_path, "maioptfn")
optmai_absme = wload(opt_absme_mai_path, "maioptfn")
optmai_corr = wload(opt_corr_mai_path, "maioptfn")

# for metric in [:absme, :corr]
# for metric in [:absme]
# metric = :absme    
for metric in [:mse, :absme, :corr]

    if metric == :mse
        maioptfn = optmai_mse
    elseif metric == :absme
        maioptfn = optmai_absme
    elseif metric == :corr
        maioptfn = optmai_corr 
    else
        error("métrica incorrecta")
    end

    inflfn = [maioptfn.ensemble.functions...]

    ##  ----------------------------------------------------------------------------
    #   Generación de datos de simulación 
    #   ----------------------------------------------------------------------------

    mai_config = Dict(
        :inflfn => inflfn, 
        :resamplefn => resamplefn, 
        :trendfn => trendfn,
        :paramfn => paramfn, 
        :traindate => FINAL_DATE,
        :nsim => 10_000,
    ) |> dict_list

    final_path = joinpath(config_savepath, measure_tag(maioptfn))
    tray_dir = datadir(final_path, "tray_infl")
    run_batch(gtdata, mai_config, final_path)

    ## Combinación de correlacion 
    df_results = collect_results(final_path)

    # Combinar las trayectorias y evaluar la combinación óptima 
    weights_df = components(maioptfn)

    needed_metrics = [
        metric, 
        Symbol("gt_b00_", metric), 
        Symbol("gt_b10_", metric), 
        Symbol("gt_t0010_", metric),
    ]

    combine_df = @chain df_results begin 
        select(
            :measure, 
            needed_metrics..., 
            :path => ByRow(p -> joinpath(tray_dir, basename(p))) => :tray_path
        )
        leftjoin(weights_df, on=:measure)
    end

    # Trayectorias de inflación 
    tray_infl_mai = mapreduce(hcat, combine_df.tray_path) do path
        load(path, "tray_infl")
    end

    param = InflationParameter(paramfn, resamplefn, trendfn)
    tray_infl_pob = param(gtdata_eval)

    # Trayectorias de simulación de la óptima
    tray_infl_maiopt = sum(tray_infl_mai .* combine_df.weights', dims=2)
    metrics = eval_metrics(tray_infl_maiopt, tray_infl_pob)

    # Métricas por todos los períodos
    EVAL_PERIODS = (CompletePeriod(), GT_EVAL_B00, GT_EVAL_T0010, GT_EVAL_B10)
    metrics = mapreduce(merge, EVAL_PERIODS) do period 
        mask = eval_periods(gtdata_eval, period)
        prefix = period_tag(period)
        metrics = @views eval_metrics(tray_infl_maiopt[mask, :, :], tray_infl_pob[mask]; short=false, prefix)
        metrics 
    end

    # Convertir las métricas a un DataFrame
    opt_metrics_df = DataFrame(metrics)
    opt_metrics_df[!, :measure] .= measure_name(maioptfn)

    # Mezclamos las métricas 
    all_metrics_df = vcat(
        select(df_results, :measure, needed_metrics...), 
        select(opt_metrics_df, :measure, needed_metrics...), 
    )

    ## Evaluación en el período de optimización dic-01 - dic-18
    optim_period = EvalPeriod(Date(2001,12), Date(2018,12), "opt18")
    optim_mask = eval_periods(gtdata_eval, optim_period)

    # Métricas de la óptima en el período de optimización 
    optim_opt_df = mapreduce(merge, [optim_period]) do period 
        mask = eval_periods(gtdata_eval, period)
        prefix = period_tag(period)
        metrics = @views eval_metrics(tray_infl_maiopt[mask, :, :], tray_infl_pob[mask]; short=false, prefix)
        metrics 
    end |> DataFrame
    optim_opt_df[!, :measure] .= measure_name(maioptfn)

    # Métricas de las componentes en el período de optimización 
    optim_components_df = mapreduce(vcat, 1:3) do i 
        tray_infl_comp_mai = tray_infl_mai[:, i, :]
        mask = eval_periods(gtdata_eval, optim_period)
        prefix = period_tag(optim_period)
        metrics = @views eval_metrics(tray_infl_comp_mai[mask, :, :], tray_infl_pob[mask]; short=false, prefix)
        DataFrame(metrics)
    end
    optim_components_df[!, :measure] .= combine_df[!, :measure]
    optim_components_df

    # Métricas de todas las medidas en el período de optimización 
    optim_metrics_df = vcat(
        select(optim_components_df, :measure, Symbol(:opt18_, metric)),
        select(optim_opt_df, :measure, Symbol(:opt18_, metric)),
    )

    ## Combinamos las métricas históricas con las del período de optimización 
    full_metrics_df = leftjoin(
        all_metrics_df, 
        optim_metrics_df,
        on=:measure
    )

    ## Guardar los resultados
    metrics_savepath = mkpath(datadir("updates", "metrics"))
    params_config = (measure=measure_tag(maioptfn), metric=metric)
    HEMI.save_csv(
        joinpath(metrics_savepath, savename("metrics", params_config, "csv")),
        full_metrics_df
    )

# end