using DrWatson
@quickactivate "HEMI" 

using HEMI 

## Parallel processing
using Distributed
nprocs() < 5 && addprocs(4, exeflags="--project")
@everywhere using HEMI 

## Otras librerías
using DataFrames, Chain


include(scriptsdir("generate_optim_combination","2022","optabsme2022.jl"))
gtdata_eval = GTDATA[Date(2020, 12)]




loadpath = datadir("results", "2022_tray_infl","tray_infl", "absme")
tray_dir = joinpath(loadpath, "tray_infl")

df               = collect_results(loadpath)
df[!,:tray_path] = joinpath.(tray_dir,basename.(df.path))
df[!,:tray_infl] = [x["tray_infl"] for x in load.(df.tray_path)]
df               = innerjoin(df, components(optabsme2022), on=:measure)
df[!,:w_tray]    = df.tray_infl .* df.weights

temp = DataFrame(measure = optabsme2022.name, tray_infl=[sum(df.w_tray)])

df_final = vcat(df[:,[:measure,:tray_infl]],temp)

param = InflationParameter(
    InflationTotalRebaseCPI(36, 2), 
    ResampleScrambleVarMonths(), 
    TrendRandomWalk()
)

tray_infl_pob      = param(gtdata_eval)

#################################
######### PLOTS #################
#################################
# NO DESCOMENTAR
#=
using Plots
using StatsBase

for i in 1:8

    TITLE = df_final[i,:measure]
    PARAM = tray_infl_pob
    X = infl_dates(gtdata_eval)
    TRAYS = df_final[i,:tray_infl]
    TRAY_INFL = [ TRAYS[:,:,i] for i in 1:size(TRAYS)[3]]
    TRAY_VEC = sample(TRAY_INFL,500)
    TRAY_PROM = mean(TRAYS,dims=3)[:,:,1]
    TRAY_MED = median(TRAYS,dims=3)[:,:,1]
    TRAY_25 = [percentile(x[:],25) for x in eachslice(TRAYS,dims=1)][:,:] 
    TRAY_75 = [percentile(x[:],75) for x in eachslice(TRAYS,dims=1)][:,:]
    # cambiamos el rango de fechas
    #X = X[b10_mask]
    #TRAY_VEC = map(x -> x[b10_mask],TRAY_VEC)
    #PARAM = PARAM[b10_mask]

    p=plot(
        X,
        TRAY_VEC;
        legend = true,
        label = false,
        c="grey12",
        linewidth = 0.25/2,
        title = TITLE,
        size = (900,600),
        ylims = (0,14)
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

    p=plot!(
        X,TRAY_MED;
        legend = true,
        label="Mediana",
        c="green",
        linewidth = 2.0
    )

    p=plot!(
        X,TRAY_25;
        legend = true,
        label = "Percentil 25",
        c="green",
        linewidth = 2.0,
        linestyle=:dash
    )

    p=plot!(
        X,TRAY_75;
        legend = true,
        label = "Percentil 75",
        c="green",
        linewidth = 2.0,
        linestyle=:dash
    )
    display(p)
    savefig("C:\\Users\\DJGM\\Desktop\\PLOTS\\2022\\plot_"*string(i+8)*".png")
end
=#