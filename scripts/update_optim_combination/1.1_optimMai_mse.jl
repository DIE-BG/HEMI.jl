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
savepath = datadir("results", "optim", "mse", "CoreMAI")
savepath_best = datadir("results", "optim", "mse")

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
        backend = :BlackBoxOptim,
        maxtime = 7_200,
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
            sort(:mse)
            #first(3)
        end
    end
    filter(:K => k -> k == K, _)
    #select(:method, :n, :mse, :q)
end

# pretty_table(prelim_methods[:,[:method,:n,:mse,:q]])
# ┌─────────┬────────┬──────────┬────────────────────────────────────────────────────┐
# │  method │      n │      mse │                                                  q │
# │ String? │ Int64? │ Float64? │                                   Vector{Float64}? │
# ├─────────┼────────┼──────────┼────────────────────────────────────────────────────┤
# │   MaiFP │      4 │ 0.277311 │                     [0.276032, 0.718878, 0.757874] │  <---|
# │   MaiFP │      5 │ 0.288835 │           [0.295325, 0.297613, 0.703355, 0.786653] │      |
# │   MaiFP │      6 │ 0.293016 │      [0.166667, 0.333333, 0.5, 0.666667, 0.833333] │      |
# │    MaiF │      5 │ 0.273132 │            [0.243512, 0.33586, 0.715301, 0.798704] │      |
# │    MaiF │      4 │ 0.284195 │                      [0.382601, 0.667259, 0.82893] │  <---|---  METODOS SELECCIONADOS
# │    MaiF │      6 │ 0.292753 │ [0.253906, 0.301861, 0.715315, 0.806472, 0.808036] │      |
# │    MaiG │      4 │ 0.538834 │                    [0.0520718, 0.609893, 0.738493] │      |
# │    MaiG │      6 │ 0.567726 │ [0.069199, 0.267753, 0.584127, 0.683626, 0.776651] │      |
# │    MaiG │      5 │ 0.594854 │          [0.0588968, 0.271835, 0.742957, 0.771684] │  <---|
# └─────────┴────────┴──────────┴────────────────────────────────────────────────────┘

# Se seleccionaron manualmente los siguientes metodos basados en su similitud con los resultados
# de la optima MSE 2022, dado que su evaluacion no es significativamente peor que la mejor evaluada

df_best = prelim_methods[[1,5,9],:]

# pretty_table(df_best[:,[:method,:n,:mse,:q]])
# ┌─────────┬────────┬───────────────────────────────────────────┬──────────┐
# │  method │      n │                                         q │      mse │
# │ String? │ Int64? │                          Vector{Float64}? │ Float64? │
# ├─────────┼────────┼───────────────────────────────────────────┼──────────┤
# │   MaiFP │      4 │            [0.276032, 0.718878, 0.757874] │ 0.277311 │
# │    MaiF │      4 │             [0.382601, 0.667259, 0.82893] │ 0.284195 │
# │    MaiG │      5 │ [0.0588968, 0.271835, 0.742957, 0.771684] │ 0.594854 │
# └─────────┴────────┴───────────────────────────────────────────┴──────────┘



maifns = map(eachrow(df_best)) do r
    method = :($(Symbol(r.method))([0, $(r.q)..., 1.0]))
    maifn  = InflationCoreMai(eval(method))
    return maifn.method
end

df_best[!,:maifns] = maifns


for x in eachrow(df_best)
    name = string(x.method)*".jld2"
    wsave(datadir(savepath_best,name), "nsim", x.K , "measure", x.method, "optimal", x.mse, "minimizer", x.q)
end



