# Cominación Lineal Óptim CORR 2024 B

w = [0.013201  0.004728  0.944753  0.012774  0.012666  0.011891][:]

ensemble = [
    InflationPercentileEq(0.76f0),
    InflationPercentileWeighted(0.76f0),
    InflationTrimmedMeanEq(60.0f0, 88.0f0),
    InflationTrimmedMeanWeighted(58.0f0, 91.0f0),
    InflationDynamicExclusion(0.1f0, 0.4f0),
    InflationFixedExclusionCPI{2}(([35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193, 161], [29, 46, 39, 31, 116, 40, 30, 186, 35, 47, 197, 41, 22, 185, 48, 34, 37, 184, 25, 38, 32, 229, 237, 45, 42, 196, 3, 33, 44, 274, 19, 59, 10, 61, 15, 24, 195, 43, 27, 36, 23, 115, 26, 275, 71, 113, 236, 117, 148, 49, 268, 213, 20, 9, 202]))
]

optcorr2024_b = CombinationFunction(
    ensemble...,
    w,
    "Subyacente Óptima CORR 2024 B",
    "SubOptCORR_2024_B"
)