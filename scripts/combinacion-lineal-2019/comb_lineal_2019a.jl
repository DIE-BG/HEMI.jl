using DrWatson
@quickactivate "HEMI"

using DataFrames, Chain
using HEMI 

# NOTA: correr este script para generar trayectorias de las medidas de 
#       inflación (con la excepción de las MAI)

gtdata_eval = gtdata[Date(2019, 12)]

legacy_param = InflationParameter(
    InflationTotalRebaseCPI(36, 2), # Cada 36 meses y hasta 2 cambios de base 
    ResampleScrambleVarMonths(), 
    TrendRandomWalk()
)

tray_infl_param = legacy_param(gtdata_eval)

excOpt00 = [35,30,190,36,37,40,31,104,162,32,33,159,193,161]
excOpt10 = [29,31,116,39,46,40,30,35,186,47,197,41,22,48,185,34,184]

inf_list = [InflationPercentileEq(72), InflationPercentileWeighted(70),
            InflationTrimmedMeanEq(57.5, 84), InflationTrimmedMeanWeighted(15,97),
            InflationFixedExclusionCPI(excOpt00, excOpt10), InflationDynamicExclusion(0.3222, 1.7283) 
]

sims = Dict(
    :inflfn => inf_list,
    :resamplefn => ResampleScrambleVarMonths(), 
    :trendfn => TrendRandomWalk(),
    :paramfn => InflationTotalRebaseCPI(36,2),
    :traindate => Date(2019,12),
    :nsim => 125_000
) |> dict_list

savepath   = datadir("tray2019")

run_batch(gtdata, sims, savepath; savetrajectories=true)


