# Subyacente Óptima ABSME NO Transable 2024
w_00 = [0.0334445  0.229912  0.0846386  0.14619  0.231975  0.273933][:]
w_10 = [0.999751  6.51575e-5  1.54983e-7  8.08151e-5  3.17083e-6  0.0][:]


ENSEMBLE1 = [
    InflationPercentileEq(0.72f0),
    InflationPercentileWeighted(0.69f0),
    InflationTrimmedMeanEq(47.0f0, 89.0f0),
    InflationTrimmedMeanWeighted(48.0f0, 89.0f0),
    InflationDynamicExclusion(2.0f0, 4.9f0),
    InflationFixedExclusionCPI{2}(([32, 8, 35, 17], [28]))
]

ENSEMBLE2 = [
    InflationPercentileEq(0.76f0),
    InflationPercentileWeighted(0.75f0),
    InflationTrimmedMeanEq(76.0f0, 77.0f0),
    InflationTrimmedMeanWeighted(66.0f0, 88.0f0),
    InflationDynamicExclusion(0.3f0, 3.8f0),
    InflationFixedExclusionCPI{2}(([32, 8, 35, 17], [28]))
]

c1 = CombinationFunction(
    ENSEMBLE1...,
    w_00
)

c2= CombinationFunction(
    ENSEMBLE2..., 
    w_10
)

optabsme2024_no_trans = Splice([c1,c2]; dates=nothing, name="Subyacente Óptima ABSME No Transable 2024", tag="SubOptABSME_2024_NoTrans")

optabsme2024_no_trans_ci = DataFrame(
    period = ["Base 2000", "Transición 2000-2010", "Base 2010"], 
    evalperiod = [GT_EVAL_B00, GT_EVAL_T0010, EvalPeriod(Date(2011, 12), Date(2023,12), "upd23")], 
    inf_limit = Float32[-1.84894, -1.35007, -0.687575], 
    sup_limit = Float32[1.64192,   1.1431,  0.576568]
)

# ┌──────────────────────────────┬──────────────┬────────────────┬──────────────┬────────────────┬───────────┐
# │                         name │ gt_b00_absme │ gt_t0010_absme │ gt_b10_absme │ gt_b2020_absme │     absme │
# │                       String │     Float32? │       Float32? │     Float32? │       Float32? │  Float32? │
# ├──────────────────────────────┼──────────────┼────────────────┼──────────────┼────────────────┼───────────┤
# │      Percentil Equiponderado │     0.136008 │       0.450985 │    0.0335151 │      0.0397933 │ 0.0566069 │
# │          Percentil Ponderado │    0.0756432 │       0.101324 │     0.169452 │       0.171871 │ 0.0608958 │
# │ Media Truncada Equiponderada │   0.00247808 │       0.389971 │     0.125841 │       0.128893 │  0.050266 │
# │     Media Truncada Ponderada │   0.00046241 │       0.100216 │     0.161393 │       0.163815 │  0.089001 │
# │           Exclusion Dinámica │   0.00169049 │       0.270622 │     0.251607 │       0.234534 │  0.144762 │
# │               Exclusion Fija │    0.0427078 │       0.124941 │    0.0500076 │      0.0850925 │  0.013321 │
# │ Subyacente Óptima ABSME 2024 │   6.87607e-7 │      0.0280824 │    0.0332901 │      0.0395762 │ 0.0187216 │
# └──────────────────────────────┴──────────────┴────────────────┴──────────────┴────────────────┴───────────┘