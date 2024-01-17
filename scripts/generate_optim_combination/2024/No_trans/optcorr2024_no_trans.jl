# Subyacente Óptima CORR NO Transable 2024
w_00 = [0.0256201  0.157065  0.372671  0.216616  0.192648  0.0353789][:]
w_10 = [0.111993  0.0520926  0.649841  0.0312274  0.154828  0.0][:]


ENSEMBLE1 = [
    InflationPercentileEq(0.89f0),
    InflationPercentileWeighted(0.82f0),
    InflationTrimmedMeanEq(63.0f0, 96.0f0),
    InflationTrimmedMeanWeighted(52.0f0, 97.0f0),
    InflationDynamicExclusion(0.8f0, 2.4f0),
    InflationFixedExclusionCPI{2}(([32], [28, 42]))
]

ENSEMBLE2 = [
    InflationPercentileEq(0.86f0),
    InflationPercentileWeighted(0.88f0),
    InflationTrimmedMeanEq(77.0f0, 93.0f0),
    InflationTrimmedMeanWeighted(78.0f0, 97.0f0),
    InflationDynamicExclusion(0.5f0, 1.7f0),
    InflationFixedExclusionCPI{2}(([32], [28, 42]))
]

c1 = CombinationFunction(
    ENSEMBLE1...,
    w_00
)

c2= CombinationFunction(
    ENSEMBLE2..., 
    w_10
)

optcorr2024_no_trans = Splice([c1,c2]; dates=nothing, name="Subyacente Óptima CORR No Transable 2024", tag="SubOptCORR_2024_NoTrans")


# ┌──────────────────────────────────────────┬─────────────┬───────────────┬─────────────┬───────────────┬──────────┐
# │                                     name │ gt_b00_corr │ gt_t0010_corr │ gt_b10_corr │ gt_b2020_corr │     corr │
# │                                   String │    Float32? │      Float32? │    Float32? │      Float32? │ Float32? │
# ├──────────────────────────────────────────┼─────────────┼───────────────┼─────────────┼───────────────┼──────────┤
# │                  Percentil Equiponderado │    0.865004 │      0.978975 │    0.829436 │      0.787508 │  0.97707 │
# │                      Percentil Ponderado │    0.843673 │      0.864051 │    0.649442 │      0.590779 │ 0.947842 │
# │             Media Truncada Equiponderada │    0.889519 │      0.945808 │    0.843442 │      0.803853 │ 0.975644 │
# │                 Media Truncada Ponderada │    0.876994 │      0.799852 │    0.700334 │      0.644639 │ 0.945173 │
# │                       Exclusion Dinámica │    0.871463 │      0.976091 │    0.710567 │       0.65531 │ 0.977173 │
# │                           Exclusion Fija │     0.81635 │      0.851208 │    0.506346 │      0.419585 │ 0.929513 │
# │ Subyacente Óptima CORR 2024 No Transable │    0.905868 │      0.940527 │    0.848451 │      0.809982 │ 0.974891 │
# └──────────────────────────────────────────┴─────────────┴───────────────┴─────────────┴───────────────┴──────────┘
