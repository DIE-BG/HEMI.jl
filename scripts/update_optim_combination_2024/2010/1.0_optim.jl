using DrWatson
@quickactivate "HEMI"

include(scriptsdir("TOOLS","OPTIM","optim.jl"))

########################################################
################ BASE 2010 #############################
########################################################

savepath = datadir("optim_comb_2024","2010","individual")  

##
#Datos a Utilizar
gtdata_eval = GTDATA[Date(2022,12)]
gtdata_eval = UniformCountryStructure(gtdata_eval[2])

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



