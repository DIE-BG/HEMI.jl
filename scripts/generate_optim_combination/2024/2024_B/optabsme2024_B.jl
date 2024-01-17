# Cominación Lineal Óptim ABSME 2024 B

w = [0.692375  0.298216  0.00262721  0.0024997  0.00236435  0.00181805][:]

ensemble = [
    InflationPercentileEq(0.72f0),
    InflationPercentileWeighted(0.7f0),
    InflationTrimmedMeanEq(25.0f0, 95.0f0),
    InflationTrimmedMeanWeighted(62.0f0, 78.0f0),
    InflationDynamicExclusion(2.3f0, 5.0f0),
    InflationFixedExclusionCPI{2}(([35, 30, 190, 36, 37, 40, 31], [29, 46, 39, 31, 116, 40]))
]

optabsme2024_b = CombinationFunction(
    ensemble...,
    w,
    "Subyacente Óptima ABSME 2024 B",
    "SubOptABSME_2024_B"
)

optabsme2023_ci = DataFrame(
    period = ["Período Completo"], 
    evalperiod = [CompletePeriod()], 
    inf_limit = Float32[ -0.78318], 
    sup_limit = Float32[ 0.973525]
)

# ┌─────────────────────────────────────────────┬──────────────┬────────────────┬──────────────┬────────────────┬─────────────┐
# │                                        name │ gt_b00_absme │ gt_t0010_absme │ gt_b10_absme │ gt_b0820_absme │       absme │
# │                                      String │     Float32? │       Float32? │     Float32? │       Float32? │    Float32? │
# ├─────────────────────────────────────────────┼──────────────┼────────────────┼──────────────┼────────────────┼─────────────┤
# │                Percentil equiponderado 72.0 │    0.0456552 │       0.244838 │    0.0967062 │       0.109643 │   0.0205229 │
# │                    Percentil ponderado 70.0 │     0.268304 │       0.174206 │     0.298182 │      0.0251735 │   0.0487327 │
# │   Media Truncada Equiponderada (25.0, 95.0) │     0.473779 │        0.32802 │     0.220536 │    0.000866812 │    0.102446 │
# │       Media Truncada Ponderada (62.0, 78.0) │     0.237734 │       0.201376 │     0.320162 │    0.000841053 │   0.0746387 │
# │  Inflación de exclusión dinámica (2.3, 5.0) │     0.166354 │       0.155558 │    0.0274009 │     0.00136838 │   0.0505026 │
# │ Exclusión fija de gastos básicos IPC (7, 6) │     0.303826 │        1.00973 │      0.43262 │      0.0408153 │    0.402223 │
# │              Subyacente óptima ABSME 2024 B │     0.047155 │       0.221235 │    0.0217087 │      0.0829893 │ 0.000715202 │
# └─────────────────────────────────────────────┴──────────────┴────────────────┴──────────────┴────────────────┴─────────────┘