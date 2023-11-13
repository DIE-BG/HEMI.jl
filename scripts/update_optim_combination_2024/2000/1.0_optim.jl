using DrWatson
@quickactivate "HEMI"

include(scriptsdir("TOOLS","OPTIM","optim.jl"))

########################################################
################ BASE 2000 #############################
########################################################

savepath = datadir("optim_comb_2024","2000","individual")  

##
#Datos a Utilizar
gtdata_eval = GTDATA[Date(2010,12)]

##Configuración 

D = dict_list(
    Dict(
        :infltypefn => [
            InflationPercentileEq, 
            InflationPercentileWeighted, 
            InflationTrimmedMeanEq, 
            InflationTrimmedMeanWeighted, 
            InflationDynamicExclusion,
        ],
    :resamplefn => ResampleScrambleVarMonths(),
    :trendfn => TrendRandomWalk(),
    :paramfn => InflationTotalRebaseCPI(36,3),
    :nsim => 10_000,
    :traindate => Date(2010, 12)
    )
)

M = [:mse, :absme, :corr]

## Asignación de Valores Iniciales 
X0 = [
    [
       0.72,
       0.69,
        [58.0, 83.0],
       [21.0, 95.0],
       [0.31, 1.68]
    ]
,
   [
       0.71,
        0.69,
        [35.0, 93.0],
        [34.0, 93.0],
        [1.00, 3.42]

    ]
,
    [
        0.77,
        0.80,
        [55.0, 92.0],
        [46.0, 98.0],
        [0.46, 4.97]

    ]
]

## Optimización

DF = DataFrame()

for i in 1:length(M)
    for j in 1:length(D)
        save_path = joinpath(savepath,string(M[i]))
        optres = optimize_config(D[j], gtdata_eval; measure=M[i], savepath = save_path, x0 = X0[i][j])
        merge!(optres, tostringdict(D[j]))
        optres["minimizer"]= Ref(optres["minimizer"])
        global DF = vcat(DF,DataFrame(optres))
    end
end

## Resultados
using PrettyTables
pretty_table(DF[:,[:measure,:metric,:minimizer, :optimal]])

# ┌──────────────────────────────┬────────┬───────────────────────────────────────────┬────────────┐
# │                      measure │ metric │                                 minimizer │    optimal │
# │                       String │ Symbol │                                    String │    Float64 │
# ├──────────────────────────────┼────────┼───────────────────────────────────────────┼────────────┤
# │        InflationPercentileEq │    mse │                                0.71991086 │   0.200018 │
# │  InflationPercentileWeighted │    mse │                                 0.6969478 │   0.404245 │
# │       InflationTrimmedMeanEq │    mse │   [53.104444980621324, 86.56443614959717] │   0.172042 │
# │ InflationTrimmedMeanWeighted │    mse │    [33.23044020980596, 92.21051075756554] │   0.309032 │
# │    InflationDynamicExclusion │    mse │ [0.29588394165039045, 1.4893161773681638] │   0.306363 │
# │        InflationPercentileEq │  absme │                                0.71239126 │   0.305044 │
# │  InflationPercentileWeighted │  absme │                                0.68823665 │   0.132583 │
# │       InflationTrimmedMeanEq │  absme │     [42.72982835769655, 91.0218214035034] │ 0.00789602 │
# │ InflationTrimmedMeanWeighted │  absme │    [45.59877253142186, 87.04819001266733] │ 7.62834e-5 │
# │    InflationDynamicExclusion │  absme │  [1.1207321733236313, 3.4683535182476044] │ 3.07523e-5 │
# │        InflationPercentileEq │   corr │                                0.79305905 │   0.975212 │
# │  InflationPercentileWeighted │   corr │                                0.77419573 │   0.938846 │
# │       InflationTrimmedMeanEq │   corr │       [53.6291259765625, 89.752685546875] │   0.978878 │
# │ InflationTrimmedMeanWeighted │   corr │    [50.38429222106934, 91.86738662719728] │   0.952717 │
# │    InflationDynamicExclusion │   corr │ [0.31163650512695307, 1.2446017456054674] │   0.950955 │
# └──────────────────────────────┴────────┴───────────────────────────────────────────┴────────────┘

