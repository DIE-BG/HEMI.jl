# Cominación Lineal Óptim CORR 2024 B
w_00 = [0.0204378  3.10559e-6  0.811857  0.00912357  0.0112348  0.0947092  0.00876126  0.0437943  6.25579e-6][:]
w_10 = [0.0279822  0.00899382  0.935041  0.00824192  0.0195432  0.0  0.000197362  5.20047e-6  7.12773e-5][:]
w_23 = [0.013201  0.004728  0.944753  0.012774  0.012666  0.011891][:]

ENSEMBLE1 = [
    InflationPercentileEq(0.67f0),
    InflationPercentileWeighted(0.77f0),
    InflationTrimmedMeanEq(56.0f0, 89.0f0),
    InflationTrimmedMeanWeighted(50.0f0, 92.0f0),
    InflationDynamicExclusion(0.3f0, 1.3f0),
    InflationFixedExclusionCPI{3}(([35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193, 161], [29, 31, 116, 39, 46, 40, 30, 35, 186, 47, 197, 41, 22, 48, 185, 34, 184, 25, 38, 37, 229, 32, 45, 3, 33, 44, 237, 274, 19, 10, 42, 24, 15, 59, 43, 27, 275, 61, 115, 23, 71, 26, 113, 49, 268, 236, 213, 117, 20, 36, 9],[])),
    InflationCoreMai(MaiFP([0.0, 0.25, 0.5, 0.75, 1.0])),
    InflationCoreMai(MaiF([0.0, 0.25, 0.5, 0.75, 1.0])),
    InflationCoreMai(MaiG([0.0, 0.25, 0.5, 0.75, 1.0]))
]

ENSEMBLE2 = [
    InflationPercentileEq(0.77f0),
    InflationPercentileWeighted(0.78f0),
    InflationTrimmedMeanEq(63.0f0, 87.0f0),
    InflationTrimmedMeanWeighted(65.0f0, 85.0f0),
    InflationDynamicExclusion(0.1f0, 0.3f0),
    InflationFixedExclusionCPI{3}(([35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193, 161], [29, 31, 116, 39, 46, 40, 30, 35, 186, 47, 197, 41, 22, 48, 185, 34, 184, 25, 38, 37, 229, 32, 45, 3, 33, 44, 237, 274, 19, 10, 42, 24, 15, 59, 43, 27, 275, 61, 115, 23, 71, 26, 113, 49, 268, 236, 213, 117, 20, 36, 9],[])),
    InflationCoreMai(MaiFP([0.0, 0.2672442881778741, 0.473091342209772, 0.7479902174123896, 1.0])),
    InflationCoreMai(MaiF([0.0, 0.3049173169194217, 0.48316073418620653, 0.7527851981524679, 1.0])),
    InflationCoreMai(MaiG([0.0, 0.2751703195250005, 0.3747402369144304, 0.6046948092173894, 0.8095453414573179, 1.0]))
]

ENSEMBLE3 = [
    InflationPercentileEq(0.76f0),
    InflationPercentileWeighted(0.76f0),
    InflationTrimmedMeanEq(60.0f0, 88.0f0),
    InflationTrimmedMeanWeighted(58.0f0, 91.0f0),
    InflationDynamicExclusion(0.1f0, 0.4f0),
    InflationFixedExclusionCPI{3}(([35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193, 161], [29, 46, 39, 31, 116, 40, 30, 186, 35, 47, 197, 41, 22, 185, 48, 34, 37, 184, 25, 38, 32, 229, 237, 45, 42, 196, 3, 33, 44, 274, 19, 59, 10, 61, 15, 24, 195, 43, 27, 36, 23, 115, 26, 275, 71, 113, 236, 117, 148, 49, 268, 213, 20, 9, 202],[]))
]

c1 = CombinationFunction(
    ENSEMBLE1...,
    w_00
)

c2 = CombinationFunction(
    ENSEMBLE2..., 
    w_10
)

c3 = CombinationFunction(
    ENSEMBLE3..., 
    w_23
)

optcorr2024_b = Splice([c1,c2,c3]; dates=nothing, name="Subyacente Óptima CORR 2024 B", tag="SubOptCORR_2024_B")
