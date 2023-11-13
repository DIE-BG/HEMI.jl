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
savepath_b00 = datadir("optim_comb_2024","2000_2010","MAI", "B00","corr")  
savepath_b10 = datadir("optim_comb_2024","2000_2010","MAI", "B10","corr") 
savepath_best_b00 = datadir("optim_comb_2024","2000_2010","B00", "corr") 
savepath_best_b10 = datadir("optim_comb_2024","2000_2010","B10", "corr") 



## Configuración para simulaciones
genconfig = Dict(
    :paramfn => InflationTotalRebaseCPI(36, 3),
    :resamplefn => ResampleScrambleVarMonths(),
    :trendfn => TrendRandomWalk(),
    :traindate => Date(2020, 12),
    :nsim => 10_000
)

optconfig = merge(genconfig, Dict(
    # Parámetros para búsqueda iterativa de cuantiles 
    :mainseg => [4,5,6],
    :maimethod => [MaiF, MaiG, MaiFP], 
)) |> dict_list

## Optimización de métodos MAI - búsqueda inicial de percentiles 

K = 300#200
MAXITER = 1_000


## Optimizacion para base 2000
for config in optconfig
    qstart = nothing
    optimizemai(config, GTDATA_00; 
        K, 
        savepath = savepath_b00, 
        maxiterations = MAXITER, 
        backend = :BlackBoxOptim,
        maxtime = 3_600, #7_200
        qstart = qstart,
        init = :uniform,
        metric = :corr
    )
end 
# for config in optconfig
#     if config[:maimethod] == MaiF && config[:mainseg] == 4
#         qstart = [0.38, 0.67, 0.83]
#     elseif config[:maimethod] == MaiFP && config[:mainseg] == 4
#         qstart = [0.28, 0.72, 0.76]
#     elseif config[:maimethod] == MaiG && config[:mainseg] == 5
#         qstart = [0.06, 0.27, 0.74, 0.77]
#     else
#         qstart = nothing
#     end
#     optimizemai(config, GTDATA_00; 
#         K, 
#         savepath = savepath_b00, 
#         maxiterations = MAXITER, 
#         backend = :BlackBoxOptim,
#         maxtime = 3_600, #7_200
#         qstart = qstart,
#         init = :uniform,
#         metric = :corr
#     )
# end 

## Optimizacion para base 2010
for config in optconfig
    qstart = nothing
        optimizemai(config, GTDATA_10; 
            K, 
            savepath = savepath_b10, 
            maxiterations = MAXITER, 
            backend = :BlackBoxOptim,
            maxtime = 3_600, #7_200,
            qstart = qstart, 
            init = :uniform,
            metric = :corr
        )
    end 
# for config in optconfig
#     if config[:maimethod] == MaiF && config[:mainseg] == 4
#         qstart = [0.38, 0.67, 0.83]
#     elseif config[:maimethod] == MaiFP && config[:mainseg] == 4
#         qstart = [0.28, 0.72, 0.76]
#     elseif config[:maimethod] == MaiG && config[:mainseg] == 5
#         qstart = [0.06, 0.27, 0.74, 0.77]
#     else
#         qstart = nothing
#     end
#     optimizemai(config, GTDATA_10; 
#         K, 
#         savepath = savepath_b10, 
#         maxiterations = MAXITER, 
#         backend = :BlackBoxOptim,
#         maxtime = 3_600, #7_200,
#         qstart = qstart, 
#         init = :uniform,
#         metric = :corr
#     )
# end 

## Cargar resultados de búsqueda de cuantiles 
df00 = collect_results(savepath_b00)
df10 = collect_results(savepath_b10)

##
prelim_methods_b00 = @chain df00 begin 
    groupby(_, :method)
    combine(_) do gdf 
        # Obtener las tres menores métricas de cada tipo de medida 
        @chain gdf begin 
            sort(:corr)
            #first(3)
        end
    end
    filter(:K => k -> k == K, _)
    #select(:method, :n, :corr, :q)
end

prelim_methods_b10 = @chain df10 begin 
    groupby(_, :method)
    combine(_) do gdf 
        # Obtener las tres menores métricas de cada tipo de medida 
        @chain gdf begin 
            sort(:corr)
            #first(3)
        end
    end
    filter(:K => k -> k == K, _)
    #select(:method, :n, :corr, :q)
end

#pretty_table(prelim_methods_b00[:,[:method,:n,:corr,:q]])
# ┌─────────┬────────┬───────────┬───────────────────────────────────────────────────┐
# │  method │      n │      corr │                                                 q │
# │ String? │ Int64? │  Float64? │                                  Vector{Float64}? │
# ├─────────┼────────┼───────────┼───────────────────────────────────────────────────┤
# │    MaiG │      4 │ -0.912732 │                                 [0.25, 0.5, 0.75] │
# │    MaiG │      5 │ -0.905546 │                              [0.2, 0.4, 0.6, 0.8] │
# │    MaiG │      6 │  -0.89641 │ [0.220329, 0.400628, 0.52166, 0.750498, 0.817163] │
# │   MaiFP │      4 │   -0.9492 │                                 [0.25, 0.5, 0.75] │
# │   MaiFP │      5 │ -0.936885 │           [0.268266, 0.496792, 0.64727, 0.777786] │
# │   MaiFP │      6 │ -0.932079 │     [0.166667, 0.333333, 0.5, 0.666667, 0.833333] │
# │    MaiF │      4 │ -0.949093 │                                 [0.25, 0.5, 0.75] │
# │    MaiF │      5 │ -0.938775 │                              [0.2, 0.4, 0.6, 0.8] │
# │    MaiF │      6 │ -0.934134 │     [0.166667, 0.333333, 0.5, 0.666667, 0.833333] │
# └─────────┴────────┴───────────┴───────────────────────────────────────────────────┘

#pretty_table(prelim_methods_b10[:,[:method,:n,:corr,:q]])
# ┌─────────┬────────┬───────────┬────────────────────────────────────────────────────┐
# │  method │      n │      corr │                                                  q │
# │ String? │ Int64? │  Float64? │                                   Vector{Float64}? │
# ├─────────┼────────┼───────────┼────────────────────────────────────────────────────┤
# │    MaiG │      5 │ -0.866052 │             [0.27517, 0.37474, 0.604695, 0.809545] │
# │    MaiG │      4 │ -0.865247 │                     [0.314625, 0.521176, 0.766596] │
# │    MaiG │      6 │ -0.820827 │      [0.166667, 0.333333, 0.5, 0.666667, 0.833333] │
# │   MaiFP │      4 │  -0.92752 │                      [0.267244, 0.473091, 0.74799] │
# │   MaiFP │      5 │ -0.921536 │           [0.254592, 0.371068, 0.579395, 0.801717] │
# │   MaiFP │      6 │ -0.913194 │ [0.286925, 0.358902, 0.433988, 0.730001, 0.834546] │
# │    MaiF │      4 │ -0.926098 │                     [0.304917, 0.483161, 0.752785] │
# │    MaiF │      5 │ -0.923353 │             [0.312071, 0.37266, 0.635494, 0.76846] │
# │    MaiF │      6 │ -0.913823 │  [0.286406, 0.313263, 0.52538, 0.564591, 0.768076] │
# └─────────┴────────┴───────────┴────────────────────────────────────────────────────┘


# Se seleccionaron manualmente los siguientes metodos basados en su similitud con los resultados
# de la optima corr 2022, dado que su evaluacion no es significativamente peor que la mejor evaluada

df_best_b00 = prelim_methods_b00[[1,4,7],:]
df_best_b10 = prelim_methods_b10[[1,4,7],:]

#pretty_table(df_best_b00[:,[:method,:n,:corr,:q]])
# ┌─────────┬────────┬───────────┬───────────────────┐
# │  method │      n │      corr │                 q │
# │ String? │ Int64? │  Float64? │  Vector{Float64}? │
# ├─────────┼────────┼───────────┼───────────────────┤
# │    MaiG │      4 │ -0.912732 │ [0.25, 0.5, 0.75] │
# │   MaiFP │      4 │   -0.9492 │ [0.25, 0.5, 0.75] │
# │    MaiF │      4 │ -0.949093 │ [0.25, 0.5, 0.75] │
# └─────────┴────────┴───────────┴───────────────────┘

# pretty_table(df_best_b10[:,[:method,:n,:corr,:q]])
# ┌─────────┬────────┬───────────┬────────────────────────────────────────┐
# │  method │      n │      corr │                                      q │
# │ String? │ Int64? │  Float64? │                       Vector{Float64}? │
# ├─────────┼────────┼───────────┼────────────────────────────────────────┤
# │    MaiG │      5 │ -0.866052 │ [0.27517, 0.37474, 0.604695, 0.809545] │
# │   MaiFP │      4 │  -0.92752 │          [0.267244, 0.473091, 0.74799] │
# │    MaiF │      4 │ -0.926098 │         [0.304917, 0.483161, 0.752785] │
# └─────────┴────────┴───────────┴────────────────────────────────────────┘


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
GT_EVAL_B2020 = EvalPeriod(Date(2011, 12), Date(2020, 12), "gt_b2020")

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





