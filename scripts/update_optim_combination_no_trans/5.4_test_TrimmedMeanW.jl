using DrWatson
@quickactivate "HEMI"

using Distributed
# Agregar procesos trabajadores
nprocs() < 5 && addprocs(4, exeflags="--project")
# Cargar los paquetes utilizados en todos los procesos
@everywhere using HEMI


data_loadpath = datadir("results", "no_trans", "data", "NOT_data.jld2")
NOT_GTDATA = load(data_loadpath, "NOT_GTDATA")

########################
#### GTDATA_EVAL #######
########################

gtdata_eval = NOT_GTDATA[Date(2021, 12)]

#########################################################################################
############# DEFINIMOS PARAMETROS ######################################################
#########################################################################################

# PARAMETRO HASTA 2021
param = InflationParameter(
    InflationTotalRebaseCPI(36, 2), 
    ResampleScrambleVarMonths(), 
    TrendRandomWalk()
)

# PARAMETRO HASTA 2019 (para evaluacion en periodo de optimizacion de medidas individuales)
param_2019 = InflationParameter(
    InflationTotalRebaseCPI(36, 2), 
    ResampleScrambleVarMonths(), 
    TrendRandomWalk()
)

# TRAYECOTRIAS DE LOS PARAMETROS 
tray_infl_pob      = param(gtdata_eval)
tray_infl_pob_19   = param_2019(gtdata_eval[Date(2019,12)])


################################################################################
########################### GEN TRAY MSE #######################################
################################################################################

genconfig = Dict(
    :paramfn => InflationTotalRebaseCPI(36, 2),
    :resamplefn => ResampleScrambleVarMonths(),
    :trendfn => TrendRandomWalk(),
    #:traindate => Date(2021, 12),
    :nsim => 10_000
)

savepath    = datadir("results", "no_trans", "tray_infl_test_TrimmedMeanW")
savepath_19 = datadir("results", "no_trans", "tray_infl_test_TrimmedMeanW", "tray_19")

inflfn_mse = [
    InflationTrimmedMeanWeighted(x,y) for x in [10:5:95...,99] for y in [x:5:95...,99]
]

config    =  merge(genconfig, Dict(:traindate => Date(2021, 12), :inflfn => inflfn_mse)) |> dict_list
config_19 =  merge(genconfig, Dict(:traindate => Date(2019, 12), :inflfn => inflfn_mse)) |> dict_list

#run_batch(NOT_GTDATA, config, savepath; savetrajectories = true)
#run_batch(NOT_GTDATA, config_19, savepath_19; savetrajectories = true)

################################################################################
########################### PLOT DE EVALUACION #################################
################################################################################

#### DEFINIMOS PERIODOS DE EVALUACION ######

period_b00 = EvalPeriod(Date(2001,12), Date(2010,12), "b00")
period_trn = EvalPeriod(Date(2011,01), Date(2011,11), "trn")
period_b10 = EvalPeriod(Date(2011,12), Date(2021,12), "b10")

b00_mask = eval_periods(gtdata_eval, period_b00)
trn_mask = eval_periods(gtdata_eval, period_trn)
b10_mask = eval_periods(gtdata_eval, period_b10)

######### CARGAMOS DATOS Y TRAYECTORIAS ###########################################

loadpath    = datadir("results", "no_trans", "tray_infl_test_TrimmedMeanW")
loadpath_19 = datadir("results", "no_trans", "tray_infl_test_TrimmedMeanW", "tray_19")

tray_dir    = joinpath(loadpath, "tray_infl")
tray_dir_19 = joinpath(loadpath_19, "tray_infl")

df     = collect_results(loadpath)
df_19  = collect_results(loadpath_19)

df[!,:tray_path] = joinpath.(tray_dir,basename.(df.path))
df[!,:tray_infl] = [x["tray_infl"] for x in load.(df.tray_path)]

df_19[!,:tray_path] = joinpath.(tray_dir_19,basename.(df_19.path))
df_19[!,:tray_infl] = [x["tray_infl"] for x in load.(df_19.tray_path)]

df[!, :measure_tag]    = measure_tag.(df.inflfn)
df_19[!, :measure_tag] = measure_tag.(df_19.inflfn)

### Convertimos del tipo de Union{Missing, x} a x
for x in names(df)
    df[!,x] = identity.(df[:,x])
end

for x in names(df_19)
    df_19[!,x] = identity.(df_19[:,x])
end

# Agregamos ciertos elementos de df_19 a df
df[!,:tray_infl_19] = df_19[:,:tray_infl]
df[!,:gt_b19_mse] = (x -> eval_metrics(x,tray_infl_pob_19)[:mse]).(df_19.tray_infl)
df[!,:gt_b19_absme] = (x -> eval_metrics(x,tray_infl_pob_19)[:absme]).(df_19.tray_infl)
df[!,:gt_b19_corr] = (x -> eval_metrics(x,tray_infl_pob_19)[:corr]).(df_19.tray_infl)

# REMOVEMOS NANS
replace_nan(v) = map(x -> isnan(x) ? zero(x) : x, v)
df[!,:gt_b00_corr] = df[:,:gt_b00_corr] |> replace_nan
df[!,:gt_b10_corr] = df[:,:gt_b10_corr] |> replace_nan
df[!,:gt_b19_corr] = df[:,:gt_b19_corr] |> replace_nan
df[!,:gt_t0010_corr] = df[:,:gt_t0010_corr] |> replace_nan



#########################################
######### PLOTS #########################
#########################################

using Plots
using StatsBase
using Gadfly

######## MSE #####################

L = [:gt_b19_mse, :gt_b10_mse]

for j in L

    plot1 = Gadfly.plot(
        x = [x[1] for x in df.params], 
        y = [x[2] for x in df.params],
        color = 1 ./ df[:,j][1:end] |> replace_nan,
        Gadfly.Geom.rectbin,
        Gadfly.Guide.xlabel("ℓ₁"),
        Gadfly.Guide.ylabel("ℓ₂"),
        Gadfly.Guide.title("TMW, MSE⁻¹, "*string(j)),
        Gadfly.Guide.colorkey(title="MSE⁻¹"),
        Guide.xticks(ticks=unique([x[1] for x in df.params])),
        Guide.yticks(ticks=unique([x[2] for x in df.params])),
        Gadfly.Coord.cartesian(
            xmin=minimum([x[1] for x in df.params]), 
            xmax=maximum([x[1] for x in df.params]),
            ymin=minimum([x[2] for x in df.params]), 
            ymax=maximum([x[2] for x in df.params])
        ),
        Gadfly.Theme(
            background_color="white",
            major_label_font="CMU Serif", 
            minor_label_font="CMU Serif",
            #key_label_font="CMU Serif",
            key_title_font="CMU Serif"
        ),
    )
    img = SVG("C:\\Users\\DJGM\\Desktop\\PLOTS\\TEST\\TMW\\MSE_"*string(j)*".svg", 6inch, 4inch)
    Gadfly.draw(img, plot1)
    display(plot1)


    sorted_df = sort(df, j)

    for i in [1,2,3,4,5]

        TITLE = sorted_df[i,:measure]*"\n"*string(L[1])*" = "*string(sorted_df[i,L[1]])*"\n"*string(L[2])*" = "*string(sorted_df[i,L[2]])
        PARAM = tray_infl_pob
        X = infl_dates(gtdata_eval)
        TRAYS = sorted_df[i,:tray_infl]
        TRAY_INFL = [ TRAYS[:,:,i] for i in 1:size(TRAYS)[3]]
        TRAY_VEC = sample(TRAY_INFL,500)
        TRAY_PROM = mean(TRAYS,dims=3)[:,:,1]
        TRAY_MED = median(TRAYS,dims=3)[:,:,1]
        TRAY_25 = [percentile(x[:],25) for x in eachslice(TRAYS,dims=1)][:,:] 
        TRAY_75 = [percentile(x[:],75) for x in eachslice(TRAYS,dims=1)][:,:]

        p=Plots.plot(
            X,
            TRAY_VEC;
            legend = true,
            label = false,
            c="grey12",
            linewidth = 0.25/2,
            title = TITLE,
            size = (900,600),
            ylims = (0,12)
        )

        p=plot!(
            X,PARAM;
            legend = true,
            label="Parámetro",
            c="blue3",
            linewidth = 3.5
        )

        p=plot!(
            X,TRAY_PROM;
            legend = true,
            label="Promedio",
            c="red",
            linewidth = 3.5
        )
        display(p)
        savefig("C:\\Users\\DJGM\\Desktop\\PLOTS\\TEST\\TMW\\MSE_"*string(j)*string(i)*".png")
    end

end

######## ABSME #####################

L = [:gt_b19_absme, :gt_b10_absme]

for j in L

    plot1 = Gadfly.plot(
        x = [x[1] for x in df.params], 
        y = [x[2] for x in df.params],
        color = 1 ./ df[:,j][1:end] |> replace_nan,
        Gadfly.Geom.rectbin,
        Gadfly.Guide.xlabel("ℓ₁"),
        Gadfly.Guide.ylabel("ℓ₂"),
        Gadfly.Guide.title("TMW, ABSME⁻¹, "*string(j)),
        Gadfly.Guide.colorkey(title="ABSME⁻¹"),
        Guide.xticks(ticks=unique([x[1] for x in df.params])),
        Guide.yticks(ticks=unique([x[2] for x in df.params])),
        Gadfly.Coord.cartesian(
            xmin=minimum([x[1] for x in df.params]), 
            xmax=maximum([x[1] for x in df.params]),
            ymin=minimum([x[2] for x in df.params]), 
            ymax=maximum([x[2] for x in df.params])
        ),
        Gadfly.Theme(
            background_color="white",
            major_label_font="CMU Serif", 
            minor_label_font="CMU Serif",
            #key_label_font="CMU Serif",
            key_title_font="CMU Serif"
        ),
    )
    img = SVG("C:\\Users\\DJGM\\Desktop\\PLOTS\\TEST\\TMW\\ABSME_"*string(j)*".svg", 6inch, 4inch)
    Gadfly.draw(img, plot1)
    display(plot1)


    sorted_df = sort(df, j)

    for i in [1,2,3,4,5]

        TITLE = sorted_df[i,:measure]*"\n"*string(L[1])*" = "*string(sorted_df[i,L[1]])*"\n"*string(L[2])*" = "*string(sorted_df[i,L[2]])
        PARAM = tray_infl_pob
        X = infl_dates(gtdata_eval)
        TRAYS = sorted_df[i,:tray_infl]
        TRAY_INFL = [ TRAYS[:,:,i] for i in 1:size(TRAYS)[3]]
        TRAY_VEC = sample(TRAY_INFL,500)
        TRAY_PROM = mean(TRAYS,dims=3)[:,:,1]
        TRAY_MED = median(TRAYS,dims=3)[:,:,1]
        TRAY_25 = [percentile(x[:],25) for x in eachslice(TRAYS,dims=1)][:,:] 
        TRAY_75 = [percentile(x[:],75) for x in eachslice(TRAYS,dims=1)][:,:]

        p=Plots.plot(
            X,
            TRAY_VEC;
            legend = true,
            label = false,
            c="grey12",
            linewidth = 0.25/2,
            title = TITLE,
            size = (900,600),
            ylims = (0,12)
        )

        p=plot!(
            X,PARAM;
            legend = true,
            label="Parámetro",
            c="blue3",
            linewidth = 3.5
        )

        p=plot!(
            X,TRAY_PROM;
            legend = true,
            label="Promedio",
            c="red",
            linewidth = 3.5
        )
        display(p)
        savefig("C:\\Users\\DJGM\\Desktop\\PLOTS\\TEST\\TMW\\ABSME_"*string(j)*string(i)*".png")
    end

end


######## CORR #####################

L = [:gt_b19_corr, :gt_b10_corr]

for j in L

    plot1 = Gadfly.plot(
        x = [x[1] for x in df.params], 
        y = [x[2] for x in df.params],
        color = df[:,j][1:end] |> replace_nan,
        Gadfly.Geom.rectbin,
        Gadfly.Guide.xlabel("ℓ₁"),
        Gadfly.Guide.ylabel("ℓ₂"),
        Gadfly.Guide.title("MTEQ, CORR, "*string(j)),
        Gadfly.Guide.colorkey(title="CORR"),
        Guide.xticks(ticks=unique([x[1] for x in df.params])),
        Guide.yticks(ticks=unique([x[2] for x in df.params])),
        Gadfly.Coord.cartesian(
            xmin=minimum([x[1] for x in df.params]), 
            xmax=maximum([x[1] for x in df.params]),
            ymin=minimum([x[2] for x in df.params]), 
            ymax=maximum([x[2] for x in df.params])
        ),
        Gadfly.Theme(
            background_color="white",
            major_label_font="CMU Serif", 
            minor_label_font="CMU Serif",
            #key_label_font="CMU Serif",
            key_title_font="CMU Serif"
        ),
    )
    img = SVG("C:\\Users\\DJGM\\Desktop\\PLOTS\\TEST\\TMW\\CORR_"*string(j)*".svg", 6inch, 4inch)
    Gadfly.draw(img, plot1)
    display(plot1)


    sorted_df = sort(df, j, rev= true)

    for i in [1,2,3,4,5]

        TITLE = sorted_df[i,:measure]*"\n"*string(L[1])*" = "*string(sorted_df[i,L[1]])*"\n"*string(L[2])*" = "*string(sorted_df[i,L[2]])
        PARAM = tray_infl_pob
        X = infl_dates(gtdata_eval)
        TRAYS = sorted_df[i,:tray_infl]
        TRAY_INFL = [ TRAYS[:,:,i] for i in 1:size(TRAYS)[3]]
        TRAY_VEC = sample(TRAY_INFL,500)
        TRAY_PROM = mean(TRAYS,dims=3)[:,:,1]
        TRAY_MED = median(TRAYS,dims=3)[:,:,1]
        TRAY_25 = [percentile(x[:],25) for x in eachslice(TRAYS,dims=1)][:,:] 
        TRAY_75 = [percentile(x[:],75) for x in eachslice(TRAYS,dims=1)][:,:]

        p=Plots.plot(
            X,
            TRAY_VEC;
            legend = true,
            label = false,
            c="grey12",
            linewidth = 0.25/2,
            title = TITLE,
            size = (900,600),
            ylims = (0,12)
        )

        p=plot!(
            X,PARAM;
            legend = true,
            label="Parámetro",
            c="blue3",
            linewidth = 3.5
        )

        p=plot!(
            X,TRAY_PROM;
            legend = true,
            label="Promedio",
            c="red",
            linewidth = 3.5
        )
        display(p)
        savefig("C:\\Users\\DJGM\\Desktop\\PLOTS\\TEST\\TMW\\CORR_"*string(j)*string(i)*".png")
    end

end