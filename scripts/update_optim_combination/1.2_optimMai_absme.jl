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
savepath = datadir("results", "optim", "absme", "CoreMAI")
savepath_best = datadir("results", "optim", "absme")

## Cargar el módulo de Distributed para computación paralela
using Distributed
# Agregar procesos trabajadores
nprocs() < 5 && addprocs(4, exeflags="--project")
# Cargar los paquetes utilizados en todos los procesos
@everywhere using HEMI


## Configuración para simulaciones
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
        metric = :me,
        backend = :BlackBoxOptim,
        maxtime = 3*3_600,
        init = :uniform
    )
end 

## Cargar resultados de búsqueda de cuantiles 
df = collect_results(savepath)
prelim_methods = @chain df begin 
    groupby(_, :method)
    combine(_) do gdf 
        # Obtener las tres menores métricas de cada tipo de medida 
        @chain gdf begin 
            sort(:absme)
            #first(3)
        end
    end
    #filter(:K => k -> k == K, _)
    #select(:method, :n, :mse, :q)
end

# pretty_table(prelim_methods[:,[:method,:n,:absme,:q]])
# ┌─────────┬────────┬───────────┬────────────────────────────────────────────────────┐
# │  method │      n │     absme │                                                  q │
# │ String? │ Int64? │  Float64? │                                   Vector{Float64}? │
# ├─────────┼────────┼───────────┼────────────────────────────────────────────────────┤
# │    MaiG │      6 │ 0.0406891 │ [0.148357, 0.315087, 0.526742, 0.615879, 0.776466] │ <---|
# │    MaiG │      4 │  0.043272 │                     [0.197828, 0.448167, 0.763565] │     |
# │    MaiG │      5 │ 0.0561184 │           [0.276123, 0.350627, 0.477197, 0.930151] │     |
# │   MaiFP │      5 │  0.044918 │           [0.384589, 0.429569, 0.574328, 0.854354] │ <---|---METODOS SELECCIONADOS
# │   MaiFP │      4 │ 0.0495434 │                     [0.173449, 0.389123, 0.792378] │     |
# │   MaiFP │      6 │ 0.0584587 │ [0.232582, 0.337702, 0.572088, 0.612812, 0.817327] │     |
# │    MaiF │      4 │ 0.0512946 │                     [0.170386, 0.401727, 0.845245] │ <---|
# │    MaiF │      5 │ 0.0529323 │           [0.225146, 0.452865, 0.643564, 0.868421] │
# │    MaiF │      6 │ 0.0588993 │ [0.160454, 0.431597, 0.645889, 0.778536, 0.851868] │
# └─────────┴────────┴───────────┴────────────────────────────────────────────────────┘

df_best = prelim_methods[[1,4,7],:]

# pretty_table(df_best[:,[:method,:n,:absme,:q]])
# ┌─────────┬────────┬───────────┬────────────────────────────────────────────────────┐
# │  method │      n │     absme │                                                  q │
# │ String? │ Int64? │  Float64? │                                   Vector{Float64}? │
# ├─────────┼────────┼───────────┼────────────────────────────────────────────────────┤
# │    MaiG │      6 │ 0.0406891 │ [0.148357, 0.315087, 0.526742, 0.615879, 0.776466] │
# │   MaiFP │      5 │  0.044918 │           [0.384589, 0.429569, 0.574328, 0.854354] │
# │    MaiF │      4 │ 0.0512946 │                     [0.170386, 0.401727, 0.845245] │
# └─────────┴────────┴───────────┴────────────────────────────────────────────────────┘

maifns = map(eachrow(df_best)) do r
    method = :($(Symbol(r.method))([0, $(r.q)..., 1.0]))
    maifn  = InflationCoreMai(eval(method))
    return maifn.method
end

df_best[!,:maifns] = maifns

for x in eachrow(df_best)
    name = string(x.method)*".jld2"
    wsave(datadir(savepath_best,name), "nsim", x.K , "measure", x.method, "optimal", x.absme, "minimizer", x.q)
end