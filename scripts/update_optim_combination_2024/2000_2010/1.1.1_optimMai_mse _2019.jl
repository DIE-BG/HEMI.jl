using DrWatson
@quickactivate "HEMI"

include(scriptsdir("TOOLS","OPTIM","optim.jl"))
include(scriptsdir("TOOLS","OPTIM","mai-optim-functions.jl"))


# # Script de evaluación de variantes de inflación subyacente MAI
using DrWatson
@quickactivate "HEMI"

using HEMI 
using Optim 
using CSV, DataFrames, Chain 

## Cargar el módulo de Distributed para computación paralela
using Distributed
# Agregar procesos trabajadores
nprocs() < 5 && addprocs(4, exeflags="--project")
# Cargar los paquetes utilizados en todos los procesos
@everywhere using HEMI


GTDATA_EVAL = GTDATA[Date(2022,12)]
GTDATA_00   = UniformCountryStructure(GTDATA_EVAL[1])
GTDATA_10   = UniformCountryStructure(GTDATA_EVAL[2])

# Directorios de resultados 
savepath_b00 = datadir("optim_comb_2024","2000_2010","MAI", "2019", "B00","mse")  
savepath_b10 = datadir("optim_comb_2024","2000_2010","MAI", "2019", "B10","mse") 
savepath_best_b00 = datadir("optim_comb_2024","2000_2010","B00", "mse", "2019") 
savepath_best_b10 = datadir("optim_comb_2024","2000_2010","B10", "mse", "2019") 



## Configuración para simulaciones
genconfig = Dict(
    :paramfn => InflationTotalRebaseCPI(36, 3),
    :resamplefn => ResampleScrambleVarMonths(),
    :trendfn => TrendRandomWalk(),
    :traindate => Date(2019, 12),
    :nsim => 10_000
)

optconfig = merge(genconfig, Dict(
    # Parámetros para búsqueda iterativa de cuantiles 
    :mainseg => [4,5,6],
    :maimethod => [MaiF, MaiG, MaiFP], 
)) |> dict_list

## Optimización de métodos MAI - búsqueda inicial de percentiles 

K = 200
MAXITER = 1_000


## Optimizacion para base 2000
for config in optconfig
    if config[:maimethod] == MaiF && config[:mainseg] == 4
        qstart = [0.38, 0.67, 0.83]
    elseif config[:maimethod] == MaiFP && config[:mainseg] == 4
        qstart = [0.28, 0.72, 0.76]
    elseif config[:maimethod] == MaiG && config[:mainseg] == 5
        qstart = [0.06, 0.27, 0.74, 0.77]
    else
        qstart = nothing
    end
    optimizemai(config, GTDATA_00; 
        K, 
        savepath = savepath_b00, 
        maxiterations = MAXITER, 
        backend = :BlackBoxOptim,
        maxtime = 7_200,#3_600, #
        qstart = qstart,
        init = :uniform
    )
end 

## Optimizacion para base 2010
for config in optconfig
    if config[:maimethod] == MaiF && config[:mainseg] == 4
        qstart = [0.38, 0.67, 0.83]
    elseif config[:maimethod] == MaiFP && config[:mainseg] == 4
        qstart = [0.28, 0.72, 0.76]
    elseif config[:maimethod] == MaiG && config[:mainseg] == 5
        qstart = [0.06, 0.27, 0.74, 0.77]
    else
        qstart = nothing
    end
    optimizemai(config, GTDATA_10; 
        K, 
        savepath = savepath_b10, 
        maxiterations = MAXITER, 
        backend = :BlackBoxOptim,
        maxtime = 7_200, #3_600, #
        qstart = qstart, 
        init = :uniform
    )
end 

## Cargar resultados de búsqueda de cuantiles 
df00 = collect_results(savepath_b00)
df10 = collect_results(savepath_b10)

##
prelim_methods_b00 = @chain df00 begin 
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

prelim_methods_b10 = @chain df00 begin 
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

# pretty_table(prelim_methods_b00[:,[:method,:n,:mse,:q]])
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

# pretty_table(prelim_methods_b10[:,[:method,:n,:mse,:q]])
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

df_best_b00 = prelim_methods_b00[[1,4,7],:]
df_best_b10 = prelim_methods_b10[[1,4,7],:]

# pretty_table(df_best_b00[:,[:method,:n,:mse,:q]])
# ┌─────────┬────────┬───────────────────────────────────────────┬──────────┐
# │  method │      n │                                         q │      mse │
# │ String? │ Int64? │                          Vector{Float64}? │ Float64? │
# ├─────────┼────────┼───────────────────────────────────────────┼──────────┤
# │   MaiFP │      4 │            [0.276032, 0.718878, 0.757874] │ 0.277311 │
# │    MaiF │      4 │             [0.382601, 0.667259, 0.82893] │ 0.284195 │
# │    MaiG │      5 │ [0.0588968, 0.271835, 0.742957, 0.771684] │ 0.594854 │
# └─────────┴────────┴───────────────────────────────────────────┴──────────┘

# pretty_table(df_best_b10[:,[:method,:n,:mse,:q]])
# ┌─────────┬────────┬───────────────────────────────────────────┬──────────┐
# │  method │      n │                                         q │      mse │
# │ String? │ Int64? │                          Vector{Float64}? │ Float64? │
# ├─────────┼────────┼───────────────────────────────────────────┼──────────┤
# │   MaiFP │      4 │            [0.276032, 0.718878, 0.757874] │ 0.277311 │
# │    MaiF │      4 │             [0.382601, 0.667259, 0.82893] │ 0.284195 │
# │    MaiG │      5 │ [0.0588968, 0.271835, 0.742957, 0.771684] │ 0.594854 │
# └─────────┴────────┴───────────────────────────────────────────┴──────────┘


## Crea las medidas utilizando los resultados optimos
maifns_b00 = map(eachrow(df_best_b00)) do r
    method = :($(Symbol(r.method))([0, $(r.q)..., 1.0]))
    maifn  = InflationCoreMai(eval(method))
    return maifn.method
end

maifns_b10 = map(eachrow(df_best_b10)) do r
    method = :($(Symbol(r.method))([0, $(r.q)..., 1.0]))
    maifn  = InflationCoreMai(eval(method))
    return maifn.method
end

# Le agregamos las mediadas a los dataframes
df_best_b00[!,:maifns] = maifns_b00
df_best_b10[!,:maifns] = maifns_b10


################# GENERAMOS METRICAS DE MAIs OPTIMAS ################################### 

# Creamos periodo de evaluacion para medidas hasta Dic 2020.
GT_EVAL_B2020 = EvalPeriod(Date(2011, 12), Date(2019, 12), "gt_b2019")

## Configuracion General base 2000
config_dict_b00 = Dict(
    :inflfn => [InflationCoreMai(x) for x in df_best_b00[:,:maifns]], 
    :resamplefn => ResampleScrambleVarMonths(), 
    :trendfn => TrendRandomWalk(),
    :paramfn => InflationTotalRebaseCPI(36,3), 
    :traindate => Date(2022, 12),
    :nsim => 10_000,
    :evalperiods => (CompletePeriod(), GT_EVAL_B00, GT_EVAL_B10, GT_EVAL_B2020)
) |> dict_list

config_dict_b10 = Dict(
    :inflfn => [InflationCoreMai(x) for x in df_best_b10[:,:maifns]], 
    :resamplefn => ResampleScrambleVarMonths(), 
    :trendfn => TrendRandomWalk(),
    :paramfn => InflationTotalRebaseCPI(36,3), 
    :traindate => Date(2022, 12),
    :nsim => 10_000,
    :evalperiods => (CompletePeriod(), GT_EVAL_B00, GT_EVAL_B10, GT_EVAL_B2020)
) |> dict_list


run_batch(GTDATA_EVAL, config_dict_b00, savepath_best_b00; savetrajectories = false)
run_batch(GTDATA_EVAL, config_dict_b10, savepath_best_b10; savetrajectories = false)





