# Cominación Lineal Óptim MSE 2024 B
# Función de combinación lineal óptima MSE 2024

w_00 = [1.98704f-6  7.14895f-8  0.734157  5.54051f-8  1.17602f-7  0.177736  2.30696f-7  0.0881041  6.04563f-8][:]
w_10 = [0.567942  7.08302f-7  0.0393877  1.0627f-6  0.0581664  0.0  0.0929947  0.241507  1.0365f-7][:]
w_23 = [0.263375  0.116192  0.230044  0.155348  0.173277][:]

ENSEMBLE1 = [
    InflationPercentileEq(0.72f0), 
    InflationPercentileWeighted(0.69f0), 
    InflationTrimmedMeanEq(52.0f0, 87.0f0), 
    InflationTrimmedMeanWeighted(34.0f0, 92.0f0), 
    InflationDynamicExclusion(0.3f0, 1.5f0),
    InflationFixedExclusionCPI{3}(([35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193, 161], [29, 31, 116, 39, 46, 40, 30, 35, 186, 47, 197, 41, 22, 48, 185, 34, 184],[])), 
    InflationCoreMai(MaiFP([0.0, 0.006287041634702409, 0.4763169240418438, 0.8411085012613978, 1.0])),
    InflationCoreMai(MaiF([0.0, 0.30007700254937775, 0.3806979438933833, 0.6592801609973685, 0.8572920039185152, 1.0])), 
    InflationCoreMai(MaiG([0.0, 0.2658236991960707, 0.5601153961330196, 0.8278967604925729, 1.0])),
]

ENSEMBLE2 = [
    InflationPercentileEq(0.72f0), 
    InflationPercentileWeighted(0.72f0), 
    InflationTrimmedMeanEq(52.0f0, 86.0f0), 
    InflationTrimmedMeanWeighted(60.0f0, 83.0f0), 
    InflationDynamicExclusion(0.3f0, 1.6f0), 
    InflationFixedExclusionCPI{3}(([35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193, 161], [29, 31, 116, 39, 46, 40, 30, 35, 186, 47, 197, 41, 22, 48, 185, 34, 184],[])), 
    InflationCoreMai(MaiFP([0.0, 0.5284098303517797, 0.5601390976116516, 0.8452089641556906, 0.9993493866637225, 1.0])), 
    InflationCoreMai(MaiF([0.0, 0.31862161044309834, 0.4455906849926661, 0.8172109274523476, 1.0])), 
    InflationCoreMai(MaiG([0.0, 0.42007669750748233, 0.5, 0.7913978925837042, 1.0]))
]

ENSEMBLE3 = [
    InflationPercentileEq(0.72f0),
    InflationPercentileWeighted(0.7f0),
    InflationTrimmedMeanEq(62.0f0, 80.0f0),
    InflationTrimmedMeanWeighted(23.0f0, 95.0f0),
    InflationDynamicExclusion(0.3f0, 1.5f0),
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


optmse2024_b = Splice([c1,c2,c3]; dates=nothing, name="Subyacente Óptima MSE 2024 B", tag="SubOptMSE_2024_B")

# optmse2024_ci = DataFrame(
#     period = ["Período Completo"], 
#     evalperiod = [CompletePeriod()], 
#     inf_limit = Float32[ -0.685509], 
#     sup_limit = Float32[ 0.982193]
# )

optmse2024_ci = DataFrame(
    period = ["Base 2000", "Transición 2000-2010", "Base 2010", "Base 2023"], 
    evalperiod = [GT_EVAL_B00, GT_EVAL_T0010, GT_EVAL_B10 ,EvalPeriod(Date(2024, 01), Date(2030,12), "B23") ], 
    inf_limit = Float32[ -0.7402978062629693,  -0.35994996428489634,  -0.4897407382726664,  -1.0186314582824707], 
    sup_limit = Float32[ 1.1579384922981262,  0.8217230200767517,  0.723473072052002, 1.1901130676269531]
)

# ┌───────────────────────────────────────────────┬────────────┬──────────────┬────────────┬──────────────┬──────────┐
# │                                          name │ gt_b00_mse │ gt_t0010_mse │ gt_b10_mse │ gt_b0820_mse │      mse │
# │                                        String │   Float32? │     Float32? │   Float32? │     Float32? │ Float32? │
# ├───────────────────────────────────────────────┼────────────┼──────────────┼────────────┼──────────────┼──────────┤
# │                  Percentil equiponderado 72.0 │   0.198929 │      0.13699 │  0.0716826 │    0.0931889 │ 0.129344 │
# │                      Percentil ponderado 70.0 │   0.449025 │     0.262252 │   0.235587 │      0.28721 │ 0.328702 │
# │     Media Truncada Equiponderada (62.0, 80.0) │   0.206065 │     0.175873 │  0.0616246 │    0.0764381 │ 0.128821 │
# │         Media Truncada Ponderada (23.0, 95.0) │   0.322878 │      0.20989 │   0.161363 │     0.172707 │ 0.233058 │
# │    Inflación de exclusión dinámica (0.3, 1.5) │   0.306323 │     0.225251 │   0.117095 │     0.156506 │ 0.203323 │
# │ Exclusión fija de gastos básicos IPC (13, 18) │   0.840445 │     0.922123 │   0.460784 │     0.523076 │ 0.644412 │
# │                  Subyacente óptima MSE 2024 B │   0.182145 │     0.129534 │  0.0722566 │    0.0874996 │  0.12209 │
# └───────────────────────────────────────────────┴────────────┴──────────────┴────────────┴──────────────┴──────────┘