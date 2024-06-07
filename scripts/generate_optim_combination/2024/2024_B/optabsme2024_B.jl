# Cominación Lineal Óptim ABSME 2024 B
w_00 = [0.194062  0.162499  0.156363  0.140381  0.117709  0.100542  0.0528811  0.039761  0.0358176][:]
w_10 = [0.248181  0.163641  0.172982  0.17823  0.1171  0.0  0.0854671  0.0224189  0.0119385][:]
w_23 = [0.693705  0.298789  0.002632  0.002504  0.002368893][:]

ENSEMBLE1 = [
    InflationPercentileEq(0.72f0),
    InflationPercentileWeighted(0.69f0),
    InflationTrimmedMeanEq(63.0f0, 80.0f0),
    InflationTrimmedMeanWeighted(63.0f0, 76.0f0), 
    InflationDynamicExclusion(1.2f0, 3.6f0), 
    InflationFixedExclusionCPI{3}(([35, 30, 190, 36, 37, 40, 31, 104, 162], [29, 31, 116, 39, 46, 40],[])), 
    InflationCoreMai(MaiFP([0.0, 0.01443501550099045, 0.4054140156662617, 0.40962401341704674, 0.9926516774108755, 1.0])),
    InflationCoreMai(MaiF([0.0, 0.35859786931406085, 0.6110773114491551, 0.9199836222660053, 1.0])),
    InflationCoreMai(MaiG([0.0, 0.16666666666666666, 0.3333333333333333, 0.5, 0.6666666666666666, 0.8333333333333334, 1.0]))
] 

ENSEMBLE2 = [
    InflationPercentileEq(0.72f0),
    InflationPercentileWeighted(0.72f0),
    InflationTrimmedMeanEq(57.0f0, 83.0f0),
    InflationTrimmedMeanWeighted(67.0f0, 78.0f0),
    InflationDynamicExclusion(0.7f0, 3.0f0),
    InflationFixedExclusionCPI{3}(([35, 30, 190, 36, 37, 40, 31, 104, 162], [29, 31, 116, 39, 46, 40],[])),
    InflationCoreMai(MaiFP([0.0, 0.379280146972861, 0.4638464024329255, 0.6627648560234276, 0.9992936015281153, 1.0])),
    InflationCoreMai(MaiF([0.0, 0.3157767072323891, 0.39533970890059356, 0.5325194928987427, 0.8020712456196974, 0.9683431434693862, 1.0])),
    InflationCoreMai(MaiG([0.0, 0.3827623832395122, 0.46567742156161374, 0.7436252875246401, 1.0]))
]

ENSEMBLE3 = [
    InflationPercentileEq(0.72f0),
    InflationPercentileWeighted(0.7f0),
    InflationTrimmedMeanEq(25.0f0, 95.0f0),
    InflationTrimmedMeanWeighted(62.0f0, 78.0f0),
    InflationDynamicExclusion(2.3f0, 5.0f0)
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

optabsme2024_b = Splice([c1,c2,c3]; dates=nothing, name="Subyacente Óptima ABSME 2024 B", tag="SubOptABSME_2024_B")


optabsme2024_ci = DataFrame(
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