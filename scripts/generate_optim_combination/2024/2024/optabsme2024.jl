# Función de combinación lineal óptima ABSME 2024

w_00 = [0.194062  0.162499  0.156363  0.140381  0.117709  0.100542  0.0528811  0.039761  0.0358176][:]
w_10 = [0.248181  0.163641  0.172982  0.17823  0.1171  0.0  0.0854671  0.0224189  0.0119385][:]

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


c1 = CombinationFunction(
    ENSEMBLE1...,
    w_00
)

c2= CombinationFunction(
    ENSEMBLE2..., 
    w_10
)

optabsme2024 = Splice([c1,c2,c2]; dates=nothing, name="Subyacente Óptima ABSME 2024", tag="SubOptABSME_2024")


optabsme2024_ci = DataFrame(
    period = ["Base 2000", "Transición 2000-2010", "Base 2010"], 
    evalperiod = [GT_EVAL_B00, GT_EVAL_T0010, EvalPeriod(Date(2011, 12), Date(2023,12), "upd23")], 
    inf_limit = Float32[-0.892216, -0.717366, -0.530732], 
    sup_limit = Float32[  1.12877,  0.778449,  0.753939]
)

#Evaluación considerando peso de Exclusión Fija en Base 00
# ┌──────────────────────────────┬──────────────┬────────────────┬──────────────┬────────────────┬────────────┐
# │                         name │ gt_b00_absme │ gt_t0010_absme │ gt_b10_absme │ gt_b2020_absme │      absme │
# │                       String │     Float32? │       Float32? │     Float32? │       Float32? │   Float32? │
# ├──────────────────────────────┼──────────────┼────────────────┼──────────────┼────────────────┼────────────┤
# │      Percentil Equiponderado │    0.0456552 │       0.244838 │    0.0967062 │       0.136627 │  0.0205229 │
# │          Percentil Ponderado │    0.0721927 │      0.0765473 │     0.128889 │       0.167715 │   0.033325 │
# │ Media Truncada Equiponderada │   0.00251127 │       0.282779 │   0.00754266 │      0.0360675 │  0.0151779 │
# │     Media Truncada Ponderada │    0.0030833 │      0.0172904 │      0.16029 │        0.19793 │  0.0848399 │
# │           Exclusion Dinámica │   0.00195156 │      0.0665947 │    0.0298573 │      0.0705278 │  0.0177504 │
# │               Exclusion Fija │     0.109512 │       0.692522 │      0.43262 │      0.0628707 │   0.304715 │
# │                       Mai FP │     0.172513 │       0.493511 │     0.933218 │       0.894912 │   0.586366 │
# │                        Mai F │    0.0359054 │       0.207425 │     0.321304 │       0.273245 │   0.162456 │
# │                        Mai G │     0.542008 │       0.141714 │     0.263287 │        0.22687 │   0.101267 │
# │ Subyacente Óptima ABSME 2024 │  0.000648471 │       0.068929 │   1.28217e-5 │      0.0379159 │ 0.00326955 │
# └──────────────────────────────┴──────────────┴────────────────┴──────────────┴────────────────┴────────────┘