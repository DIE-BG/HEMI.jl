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


# Configuración inicial para Medias Truncadas
inflfn1    = InflationTrimmedMeanEq(57.5, 84)
inflfn2    = InflationTrimmedMeanWeighted(15,97) 
resamplefn = ResampleScrambleVarMonths()
trendfn    = TrendRandomWalk()
paramfn    = InflationTotalRebaseCPI(36, 2)
nsim       = 125_000
ff         = Date(2019, 12)

config1  = SimConfig(inflfn1, resamplefn, trendfn, paramfn, nsim, ff)
config2 = SimConfig(inflfn2, resamplefn, trendfn, paramfn, nsim, ff)

# Simulación
results1, _ = makesim(gtdata, config1)
results2, _ = makesim(gtdata, config2)

# Guardamos resultados
filename1   = savename(config1, "jld2")
filename2   = savename(config2, "jld2")

dir1 = datadir("results", string(typeof(inflfn1)),"Esc-A")
dir2 = datadir("results", string(typeof(inflfn2)),"Esc-A")

wsave(joinpath(dir1, filename1), tostringdict(results1))
wsave(joinpath(dir2, filename2), tostringdict(results2))

# Graficamos trayectorias

df1 = collect_results(dir1)
df2 = collect_results(dir2)

df = vcat(df1,df2)


p = plot(InflationTotalCPI(), gtdata, fmt = :svg)
plot!(df.inflfn[1], gtdata, fmt = :svg)
plot!(df.inflfn[2], gtdata, fmt = :svg)

plotpath = joinpath("docs", "src", "eval", "EscA", "images", "trimmed_mean")
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
