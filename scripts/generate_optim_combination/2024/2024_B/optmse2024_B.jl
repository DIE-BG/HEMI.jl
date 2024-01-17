# Cominación Lineal Óptim MSE 2024 B

w = [0.263375  0.116192  0.230044  0.155348  0.173277  0.0618645][:]

ensemble = [
    InflationPercentileEq(0.72f0),
    InflationPercentileWeighted(0.7f0),
    InflationTrimmedMeanEq(62.0f0, 80.0f0),
    InflationTrimmedMeanWeighted(23.0f0, 95.0f0),
    InflationDynamicExclusion(0.3f0, 1.5f0),
    InflationFixedExclusionCPI{2}(([35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193], [29, 46, 39, 31, 116, 40, 30, 186, 35, 47, 197, 41, 22, 185, 48, 34, 37, 184]))
]

optmse2024_b = CombinationFunction(
    ensemble...,
    w,
    "Subyacente Óptima MSE 2024 B",
    "SubOptMSE_2024_B"
)

optmse2023_ci = DataFrame(
    period = ["Período Completo"], 
    evalperiod = [CompletePeriod()], 
    inf_limit = Float32[ -0.685509], 
    sup_limit = Float32[ 0.982193]
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