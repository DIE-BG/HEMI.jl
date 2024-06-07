# Subyacente Óptima MSE NO Transable 2024

w_00 = [0.041916  0.11214  0.485161  0.138114  0.0448817  0.177788][:]
w_10 = [0.0407601  3.23909f-7  0.83726  0.121979  6.83135f-8  0.0][:]

ENSEMBLE1 = [
    InflationPercentileEq(0.72f0),
    InflationPercentileWeighted(0.69f0),
    InflationTrimmedMeanEq(21.0f0, 96.0f0),
    InflationTrimmedMeanWeighted(24.0f0, 97.0f0),
    InflationDynamicExclusion(0.8f0, 3.7f0),
    InflationFixedExclusionCPI{3}(([32, 8, 35, 17, 16, 18, 33, 30, 29, 28, 41, 5, 7], [28, 42, 47, 27, 64, 26, 65, 6, 46, 32],[]))
]

ENSEMBLE2 = [
    InflationPercentileEq(0.76f0),
    InflationPercentileWeighted(0.75f0),
    InflationTrimmedMeanEq(43.0f0, 95.0f0),
    InflationTrimmedMeanWeighted(44.0f0, 97.0f0),
    InflationDynamicExclusion(0.3f0, 3.0f0),
    InflationFixedExclusionCPI{3}(([32, 8, 35, 17, 16, 18, 33, 30, 29, 28, 41, 5, 7], [28, 42, 47, 27, 64, 26, 65, 6, 46, 32],[]))
]

c1 = CombinationFunction(
    ENSEMBLE1...,
    w_00
)

c2= CombinationFunction(
    ENSEMBLE2..., 
    w_10
)

optmse2024_no_trans = Splice([c1,c2,c2]; dates=nothing, name="Subyacente Óptima MSE No Transable 2024", tag="SubOptMSE_2024_NoTrans")

optmse2024_no_trans_ci = DataFrame(
    period = ["Base 2000", "Transición 2000-2010", "Base 2010"], 
    evalperiod = [GT_EVAL_B00, GT_EVAL_T0010, EvalPeriod(Date(2011, 12), Date(2023,12), "upd23")], 
    inf_limit = Float32[-1.27184, -0.738895, -0.596058], 
    sup_limit = Float32[   1.57161,    1.2642,  0.429463 ]
)

# ┌─────────────────────────────────────────┬─────────────┬───────────────┬─────────────┬───────────────┬───────────┐
# │                                    name │ gt_b00_mse  │ gt_t0010_mse  │ gt_b10_mse  │ gt_b2020_mse  │      mse  │
# │                                  String │   Float32?  │     Float32?  │   Float32?  │     Float32?  │ Float32?  │
# ├─────────────────────────────────────────┼─────────────┼───────────────┼─────────────┼───────────────┼───────────┤
# │                 Percentil Equiponderado │   0.895777  │     0.500595  │  0.0782798  │    0.0723668  │ 0.448844  │
# │                     Percentil Ponderado │   0.882502  │     0.516457  │   0.251338  │       0.2353  │  0.53479  │
# │            Media Truncada Equiponderada │    0.49936  │     0.374291  │  0.0561285  │    0.0523266  │ 0.260919  │
# │                Media Truncada Ponderada │   0.539072  │     0.302937  │   0.123416  │     0.115473  │ 0.310298  │
# │                      Exclusion Dinámica │   0.575653  │     0.387586  │   0.212323  │     0.191696  │ 0.376476  │
# │                          Exclusion Fija │   0.707091  │     0.478594  │   0.254387  │     0.244626  │ 0.459174  │
# │ Subyacente Óptima MSE 2024 No Transable │    0.40652* │     0.246328* │  0.0547357* │    0.0511158* │ 0.214625* │
# └─────────────────────────────────────────┴─────────────┴───────────────┴─────────────┴───────────────┴───────────┘