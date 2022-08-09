using DrWatson
@quickactivate "HEMI"

include(scriptsdir("OPTIM","optim.jl"))
include(scriptsdir("OPTIM","mai-optim-functions.jl"))


# # Script de evaluación de variantes de inflación subyacente MAI
using DrWatson
@quickactivate "HEMI"

using HEMI 
using Optim 
using CSV, DataFrames, Chain 

# Directorios de resultados 
savepath = datadir("results", "optim", "corr", "CoreMAI_optim")
savepath_best = datadir("results", "optim", "corr")

## Cargar el módulo de Distributed para computación paralela
using Distributed
# Agregar procesos trabajadores
nprocs() < 5 && addprocs(4, exeflags="--project")
# Cargar los paquetes utilizados en todos los procesos
@everywhere using HEMI


## Configuración para simulaciones

# Parámetros de configuración general del escenario de evaluación 
genconfig = Dict(
    :paramfn => InflationTotalRebaseCPI(36, 2),
    :resamplefn => ResampleScrambleVarMonths(),
    :trendfn => TrendRandomWalk(),
    :traindate => Date(2019, 12),
    :nsim => 125_000
)

optconfig = merge(genconfig, Dict(
    # Parámetros para búsqueda iterativa de cuantiles 
    :mainseg => [4,5,6],
    :maimethod => [MaiF, MaiG, MaiFP], 
)) |> dict_list

## Optimización de métodos MAI - búsqueda inicial de percentiles 

K = 200
MAXITER = 1000

for config in optconfig
    optimizemai(config, gtdata; 
        K, 
        savepath, 
        maxiterations = MAXITER, 
        metric = :corr,
        #backend = :BlackBoxOptim,
        backend = :Optim,
        maxtime = 3*3_600,
        #init = :uniform
    )
end 

## Cargar resultados de búsqueda de cuantiles 
df = collect_results(savepath)
prelim_methods = @chain df begin 
    groupby(_, :method)
    combine(_) do gdf 
        # Obtener las tres menores métricas de cada tipo de medida 
        @chain gdf begin 
            sort(:corr)
            #first(3)
        end
    end
    filter(:K => k -> k == K, _)
    #select(:method, :n, :mse, :q)
end

# pretty_table(prelim_methods[:,[:method,:n,:corr,:q]])
# ┌─────────┬────────┬───────────┬───────────────────────────────────────────────────────────┐
# │  method │      n │      corr │                                                         q │
# │ String? │ Int64? │  Float32? │                                          Vector{Float32}? │
# ├─────────┼────────┼───────────┼───────────────────────────────────────────────────────────┤
# │    MaiG │      4 │ -0.945207 │                     Float32[0.260524, 0.503361, 0.746734] │  <---|
# │    MaiG │      5 │ -0.939121 │           Float32[0.230281, 0.397606, 0.611463, 0.798299] │      |
# │    MaiG │      6 │ -0.894766 │  Float32[0.12224, 0.148215, 0.175127, 0.690638, 0.719511] │      |
# │   MaiFP │      4 │ -0.957113 │                      Float32[0.25752, 0.506395, 0.749041] │  <---|---METODOS SELECCIONADOS
# │   MaiFP │      5 │  -0.95189 │           Float32[0.241006, 0.369802, 0.610866, 0.762022] │      |
# │   MaiFP │      6 │ -0.948461 │ Float32[0.233613, 0.319229, 0.517229, 0.661703, 0.811795] │      |
# │    MaiF │      4 │ -0.957346 │                     Float32[0.252018, 0.502175, 0.742866] │  <---|
# │    MaiF │      5 │ -0.952402 │           Float32[0.235394, 0.370952, 0.607036, 0.789784] │
# │    MaiF │      6 │ -0.949823 │  Float32[0.17793, 0.327947, 0.503828, 0.669071, 0.829188] │
# └─────────┴────────┴───────────┴───────────────────────────────────────────────────────────┘

df_best = prelim_methods[[1,4,7],:]

# pretty_table(df_best[:,[:method,:n,:corr,:q]])
# ┌─────────┬────────┬───────────┬───────────────────────────────────────┐
# │  method │      n │      corr │                                     q │
# │ String? │ Int64? │  Float32? │                      Vector{Float32}? │
# ├─────────┼────────┼───────────┼───────────────────────────────────────┤
# │    MaiG │      4 │ -0.945207 │ Float32[0.260524, 0.503361, 0.746734] │
# │   MaiFP │      4 │ -0.957113 │  Float32[0.25752, 0.506395, 0.749041] │
# │    MaiF │      4 │ -0.957346 │ Float32[0.252018, 0.502175, 0.742866] │
# └─────────┴────────┴───────────┴───────────────────────────────────────┘

maifns = map(eachrow(df_best)) do r
    method = :($(Symbol(r.method))([0, $(r.q)..., 1.0]))
    maifn  = InflationCoreMai(eval(method))
    return maifn.method
end

df_best[!,:maifns] = maifns


for x in eachrow(df_best)
    name = string(x.method)*".jld2"
    wsave(datadir(savepath_best,name), "nsim", x.K , "measure", x.method, "optimal", x.corr, "minimizer", x.q)
end