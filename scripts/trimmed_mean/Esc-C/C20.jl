using DrWatson
using Plots
using DataFrames
using Chain
using PrettyTables
@quickactivate "HEMI"

## Cargar el módulo de Distributed para computación paralela
using Distributed
# Agregar procesos trabajadores
addprocs(4, exeflags="--project")

# Cargar los paquetes utilizados en todos los procesos
@everywhere using HEMI

# Cargar scripts auxiliares para optimización
include("../scripts/grid_batch.jl")
include("../scripts/grid_optim.jl")


# Obtener una grilla para las medidas

grid_batch(gtdata,InflationTrimmedMeanEq, ResampleScrambleVarMonths(),
            TrendRandomWalk(),10_000, 45:75, 70:100,InflationTotalRebaseCPI(60),
            Date(2020,12);esc="Esc-C"
)

grid_batch(gtdata,InflationTrimmedMeanWeighted, ResampleScrambleVarMonths(),
            TrendRandomWalk(),10_000, 5:35, 70:100,InflationTotalRebaseCPI(60),
            Date(2020,12);esc="Esc-C"
)

# Optimizar
dir_list = ["InflationTrimmedMeanEq\\Esc-C\\MTEq_SVM_RW_Rebase60_N10000_2020-12", 
            "InflationTrimmedMeanWeighted\\Esc-C\\MTW_SVM_RW_Rebase60_N10000_2020-12"
]

grid_optim(dir_list[1],gtdata,125_000,7 ; esc="Esc-C")
grid_optim(dir_list[2],gtdata,125_000,7 ; esc="Esc-C")


# Obtenemos resultados optimos para 2020

dirs = ["InflationTrimmedMeanEq\\Esc-C\\optim",
        "InflationTrimmedMeanWeighted\\Esc-C\\optim"
]

df1 = collect_results(datadir("results",dirs[1]))
df2 = collect_results(datadir("results",dirs[2]))

df3 = vcat(df1,df2)
cond = (df3[:,:traindate].== Date(2020,12))
df = DataFrame(df3[cond,:])


# Graficamos

p = plot(InflationTotalCPI(), gtdata, fmt = :svg)
plot!(df.inflfn[1], gtdata, fmt = :svg)
plot!(df.inflfn[2], gtdata, fmt = :svg)

plotpath = joinpath("docs", "src", "eval", "EscC", "images", "trimmed_mean")
Plots.svg(p, joinpath(plotpath, "trayectorias_MT2020"))

# Para hacer tablas
df.tag = measure_tag.(df.inflfn)

res1 = @chain df begin 
    select(:tag, :mse, :mse_std_error)
    sort(:mse)
    filter(r -> r.mse < 1, _)
    filter(:tag => s -> !occursin("FP",s), _)
end

res2 = @chain df begin 
    select(:tag, :mse, r"^mse_[bvc]")
    sort(:mse)
    filter(r -> r.mse < 1, _)
    filter(:tag => s -> !occursin("FP",s), _)
end

res3 = @chain df begin 
    select(:tag, :rmse, :me, :mae, :huber, :corr)
    sort(:rmse)
    filter(r -> r.rmse < 1, _)
    filter(:tag => s -> !occursin("FP",s), _)
end

tab1 = pretty_table(res1, tf=tf_markdown, formatters=ft_round(4))
tab2 = pretty_table(res2, tf=tf_markdown, formatters=ft_round(4))
tab3 = pretty_table(res3, tf=tf_markdown, formatters=ft_round(4))