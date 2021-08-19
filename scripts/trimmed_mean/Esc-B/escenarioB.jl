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
include(scriptsdir("trimmed_mean","scripts","grid_batch.jl"))
include(scriptsdir("trimmed_mean","scripts","grid_optim.jl"))


# Obtener una grilla para las medidas
grid_batch(gtdata,InflationTrimmedMeanEq, ResampleScrambleVarMonths(), 
            TrendRandomWalk(),10_000, 45:75, 70:100,InflationTotalRebaseCPI(36,2),
            Date(2020,12); esc="Esc-B"
)
            
grid_batch(gtdata,InflationTrimmedMeanWeighted, ResampleScrambleVarMonths(), 
            TrendRandomWalk(),10_000, 5:35, 70:100,InflationTotalRebaseCPI(36,2),
            Date(2020,12); esc="Esc-B"
)


# Optimizar
dir_list = [joinpath("InflationTrimmedMeanEq","Esc-B","MTEq_SVM_RW_Rebase36_N10000_2020-12"), 
            joinpath("InflationTrimmedMeanWeighted","Esc-B","MTW_SVM_RW_Rebase36_N10000_2020-12")
]


grid_optim(dir_list[1],gtdata,125_000,7 ; esc="Esc-B")
grid_optim(dir_list[2],gtdata,125_000,7 ; esc="Esc-B")

# Graficar trayectorias

dirs = [joinpath("InflationTrimmedMeanEq","Esc-B","optim"),
        joinpath("InflationTrimmedMeanWeighted","Esc-B","optim")
]

df1 = collect_results(datadir("results",dirs[1]))
df2 = collect_results(datadir("results",dirs[2]))

df = vcat(df1,df2)

p = plot(InflationTotalCPI(), gtdata, fmt = :svg)
plot!(df.inflfn[1], gtdata, fmt = :svg)
plot!(df.inflfn[2], gtdata, fmt = :svg)

plotpath = joinpath("docs", "src", "eval", "EscB", "images", "trimmed_mean")
Plots.svg(p, joinpath(plotpath, "trayectorias_MT"))

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

# Para construir la documentación desde el REPL 
# julia> ] 
# (HEMI) pkg> activate docs
# (docs) pkg> instantiate
# julia> include("docs\\make.jl")

# using Documenter
# using Literate
# using Chain
# @chain "docs\\make.jl" include