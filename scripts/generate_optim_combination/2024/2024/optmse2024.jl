# Función de combinación lineal óptima MSE 2024

w_00 = [1.98704f-6  7.14895f-8  0.734157  5.54051f-8  1.17602f-7  0.177736  2.30696f-7  0.0881041  6.04563f-8][:]
w_10 = [0.567942  7.08302f-7  0.0393877  1.0627f-6  0.0581664  0.0  0.0929947  0.241507  1.0365f-7][:]

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

c1 = CombinationFunction(
    ENSEMBLE1...,
    w_00
)

c2= CombinationFunction(
    ENSEMBLE2..., 
    w_10
)

optmse2024 = Splice([c1,c2,c2]; dates=nothing, name="Subyacente Óptima MSE 2024", tag="SubOptMSE_2024")

optmse2024_ci = DataFrame(
    period = ["Base 2000", "Transición 2000-2010", "Base 2010"], 
    evalperiod = [GT_EVAL_B00, GT_EVAL_T0010, EvalPeriod(Date(2011, 12), Date(2023,12), "upd23")], 
    inf_limit = Float32[-0.777876, -0.589717, -0.442684], 
    sup_limit = Float32[ 0.926477,  0.711042,  0.649089]
)

#Evaluación considerando peso de Exclusión Fija en Base 00

# ┌──────────────────────────────┬────────────┬──────────────┬────────────┬──────────────┬───────────┐
# │                         name │ gt_b00_mse │ gt_t0010_mse │ gt_b10_mse │ gt_b2020_mse │       mse │
# │                       String │   Float32? │     Float32? │   Float32? │     Float32? │  Float32? │
# ├──────────────────────────────┼────────────┼──────────────┼────────────┼──────────────┼───────────┤
# │      Percentil Equiponderado │   0.198929 │      0.13699 │  0.0716826 │    0.0617605 │  0.129344 │
# │          Percentil Ponderado │    0.38762 │     0.229226 │    0.16323 │     0.149672 │  0.262773 │
# │ Media Truncada Equiponderada │   0.171876 │     0.126962 │     0.0611 │    0.0422035 │  0.111689 │
# │     Media Truncada Ponderada │    0.30943 │     0.188247 │   0.151998 │     0.141188 │    0.2214 │
# │           Exclusion Dinámica │   0.306323 │     0.208572 │   0.107959 │    0.0882536 │  0.197794 │
# │               Exclusion Fija │   0.831064 │     0.884405 │   0.454582 │     0.431349 │   0.63547 │
# │                       Mai FP │   0.240007 │     0.517885 │    1.35368 │      1.37794 │  0.837538 │
# │                        Mai F │   0.215187 │     0.124751 │   0.114631 │     0.110408 │  0.158393 │
# │                        Mai G │   0.848804 │      0.43127 │   0.361576 │      0.32134 │  0.574519 │
# │   Subyacente Óptima MSE 2024 │   0.135299 │    0.0930298 │  0.0538267 │    0.0407097 │ 0.0906318 │
# └──────────────────────────────┴────────────┴──────────────┴────────────┴──────────────┴───────────┘