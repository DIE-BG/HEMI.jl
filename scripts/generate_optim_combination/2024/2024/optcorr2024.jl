# Función de combinación lineal óptima CORR 2024

w_00 = [0.0204378  3.10559e-6  0.811857  0.00912357  0.0112348  0.0947092  0.00876126  0.0437943  6.25579e-6][:]
w_10 = [0.0279822  0.00899382  0.935041  0.00824192  0.0195432  0.0  0.000197362  5.20047e-6  7.12773e-5][:]
ENSEMBLE1 = [
    InflationPercentileEq(0.67f0),
    InflationPercentileWeighted(0.77f0),
    InflationTrimmedMeanEq(56.0f0, 89.0f0),
    InflationTrimmedMeanWeighted(50.0f0, 92.0f0),
    InflationDynamicExclusion(0.3f0, 1.3f0),
    InflationFixedExclusionCPI{2}(([35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193, 161], [29, 31, 116, 39, 46, 40, 30, 35, 186, 47, 197, 41, 22, 48, 185, 34, 184, 25, 38, 37, 229, 32, 45, 3, 33, 44, 237, 274, 19, 10, 42, 24, 15, 59, 43, 27, 275, 61, 115, 23, 71, 26, 113, 49, 268, 236, 213, 117, 20, 36, 9])),
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
    InflationFixedExclusionCPI{2}(([35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193, 161], [29, 31, 116, 39, 46, 40, 30, 35, 186, 47, 197, 41, 22, 48, 185, 34, 184, 25, 38, 37, 229, 32, 45, 3, 33, 44, 237, 274, 19, 10, 42, 24, 15, 59, 43, 27, 275, 61, 115, 23, 71, 26, 113, 49, 268, 236, 213, 117, 20, 36, 9])),
    InflationCoreMai(MaiFP([0.0, 0.2672442881778741, 0.473091342209772, 0.7479902174123896, 1.0])),
    InflationCoreMai(MaiF([0.0, 0.3049173169194217, 0.48316073418620653, 0.7527851981524679, 1.0])),
    InflationCoreMai(MaiG([0.0, 0.2751703195250005, 0.3747402369144304, 0.6046948092173894, 0.8095453414573179, 1.0]))
]


c1 = CombinationFunction(
    ENSEMBLE1...,
    w_00
)

c2= CombinationFunction(
    ENSEMBLE2..., 
    w_10
)

optcorr2024 = Splice([c1,c2]; dates=nothing, name="Subyacente Óptima CORR 2024", tag="SubOptCORR_2024")

#Evaluación considerando peso de Exclusión Fija en Base 00
# ┌──────────────────────────────┬─────────────┬───────────────┬─────────────┬───────────────┬──────────┐
# │                         name │ gt_b00_corr │ gt_t0010_corr │ gt_b10_corr │ gt_b2020_corr │     corr │
# │                       String │    Float32? │      Float32? │    Float32? │      Float32? │ Float32? │
# ├──────────────────────────────┼─────────────┼───────────────┼─────────────┼───────────────┼──────────┤
# │      Percentil Equiponderado │    0.975754 │     -0.479533 │    0.944824 │       0.92603 │  0.82705 │
# │          Percentil Ponderado │    0.938791 │      0.957443 │    0.842637 │      0.800629 │ 0.976889 │
# │ Media Truncada Equiponderada │    0.978948 │      0.972422 │    0.948786 │      0.931147 │ 0.991767 │
# │     Media Truncada Ponderada │    0.952713 │      0.972248 │    0.856049 │      0.816701 │ 0.980153 │
# │           Exclusion Dinámica │     0.95092 │      0.384818 │    0.900138 │       0.86652 │ 0.921108 │
# │               Exclusion Fija │     0.94211 │       0.96306 │    0.770841 │      0.692913 │ 0.973427 │
# │                       Mai FP │    0.975217 │      0.978015 │    0.935511 │      0.916071 │ 0.986009 │
# │                        Mai F │    0.975133 │      0.978349 │    0.935396 │      0.915787 │  0.98599 │
# │                        Mai G │    0.939986 │      0.973632 │    0.828343 │      0.787338 │ 0.970782 │
# │  Subyacente Óptima CORR 2024 │    0.979825 │      0.970921 │    0.948675 │      0.931004 │ 0.991251 │
# └──────────────────────────────┴─────────────┴───────────────┴─────────────┴───────────────┴──────────┘