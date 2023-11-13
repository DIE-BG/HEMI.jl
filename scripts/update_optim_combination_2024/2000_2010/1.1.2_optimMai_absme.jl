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
savepath_b00 = datadir("optim_comb_2024","2000_2010","MAI", "B00","absme")  
savepath_b10 = datadir("optim_comb_2024","2000_2010","MAI", "B10","absme") 
savepath_best_b00 = datadir("optim_comb_2024","2000_2010","B00", "absme") 
savepath_best_b10 = datadir("optim_comb_2024","2000_2010","B10", "absme") 



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
        metric = :absme
    )
end 

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
        metric = :absme
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
            sort(:absme)
            #first(3)
        end
    end
    filter(:K => k -> k == K, _)
    #select(:method, :n, :absme, :q)
end

prelim_methods_b10 = @chain df10 begin 
    groupby(_, :method)
    combine(_) do gdf 
        # Obtener las tres menores métricas de cada tipo de medida 
        @chain gdf begin 
            sort(:absme)
            #first(3)
        end
    end
    filter(:K => k -> k == K, _)
    #select(:method, :n, :absme, :q)
end

#pretty_table(prelim_methods_b00[:,[:method,:n,:absme,:q]])

# ┌─────────┬────────┬───────────┬───────────────────────────────────────────────────────┐
# │  method │      n │     absme │                                                     q │
# │ String? │ Int64? │  Float64? │                                      Vector{Float64}? │
# ├─────────┼────────┼───────────┼───────────────────────────────────────────────────────┤
# │    MaiG │      6 │ 0.0363649 │         [0.166667, 0.333333, 0.5, 0.666667, 0.833333] │
# │    MaiG │      5 │ 0.0635333 │               [0.17605, 0.266741, 0.618268, 0.724194] │
# │    MaiG │      4 │ 0.0794547 │                        [0.292138, 0.473261, 0.909172] │
# │    MaiF │      4 │ 0.0566897 │                        [0.358598, 0.611077, 0.919984] │
# │    MaiF │      6 │ 0.0581802 │     [0.19891, 0.331394, 0.504884, 0.726973, 0.899183] │
# │    MaiF │      5 │ 0.0666888 │              [0.218359, 0.518247, 0.597907, 0.980518] │
# │   MaiFP │      5 │   0.13223 │              [0.014435, 0.405414, 0.409624, 0.992652] │
# │   MaiFP │      6 │  0.161972 │ [0.00471193, 0.0397867, 0.552003, 0.698044, 0.986294] │
# │   MaiFP │      4 │  0.428465 │                        [0.335146, 0.455616, 0.628611] │
# └─────────┴────────┴───────────┴───────────────────────────────────────────────────────┘


# pretty_table(prelim_methods_b10[:,[:method,:n,:absme,:q]])

# ┌─────────┬────────┬───────────┬────────────────────────────────────────────────────┐
# │  method │      n │     absme │                                                  q │
# │ String? │ Int64? │  Float64? │                                   Vector{Float64}? │
# ├─────────┼────────┼───────────┼────────────────────────────────────────────────────┤
# │    MaiG │      4 │ 0.0337431 │                     [0.382762, 0.465677, 0.743625] │
# │    MaiG │      6 │ 0.0567085 │ [0.311555, 0.383987, 0.426631, 0.515297, 0.882308] │
# │    MaiG │      5 │ 0.0673111 │              [0.287217, 0.386396, 0.48896, 0.6434] │
# │    MaiF │      6 │ 0.0637255 │  [0.315777, 0.39534, 0.532519, 0.802071, 0.968343] │
# │    MaiF │      4 │ 0.0679888 │                      [0.272766, 0.43074, 0.932017] │
# │    MaiF │      5 │ 0.0696572 │           [0.126075, 0.330882, 0.767814, 0.975642] │
# │   MaiFP │      5 │  0.107001 │            [0.37928, 0.463846, 0.662765, 0.999294] │
# │   MaiFP │      6 │   0.15405 │ [0.0459219, 0.181026, 0.853046, 0.945599, 0.99956] │
# │   MaiFP │      4 │  0.155286 │                      [0.152671, 0.28672, 0.995327] │
# └─────────┴────────┴───────────┴────────────────────────────────────────────────────┘


# Se seleccionaron manualmente los siguientes metodos basados en su similitud con los resultados
# de la optima absme 2022, dado que su evaluacion no es significativamente peor que la mejor evaluada

df_best_b00 = prelim_methods_b00[[1,4,7],:]
df_best_b10 = prelim_methods_b10[[1,4,7],:]


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





