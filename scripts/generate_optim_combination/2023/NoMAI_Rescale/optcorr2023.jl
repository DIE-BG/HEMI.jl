# Función de combinación lineal óptima CORR 2023

# Definir la subyacente MAI óptima, calibrada con datos hasta 2019
optmai2023_corr = let 
    # Componentes metodologías MAI 
    maifns = [
        InflationCoreMai(MaiFP([0.0, 0.25752, 0.506395, 0.749041, 1.0])),
        InflationCoreMai(MaiF([0.0, 0.252018, 0.502175, 0.742866, 1.0])),
        InflationCoreMai(MaiG([0.0, 0.260524, 0.503361, 0.746734, 1.0])),
    ]

    # Ponderaciones MAI 
    mai_weights = Float32[0.482018, 0.516653, 0.00132962]

    # Subyacente óptima MAI por método CORR 
    optmai = CombinationFunction(
        maifns..., 
        mai_weights, 
        "MAI óptima CORR 2023", 
        "MAIOPTCORR23",
    )

    optmai
end

# Definir la función de exclusión fija
optfx2023_corr = InflationFixedExclusionCPI(
    [35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193, 161],
    [
        29, 31, 116, 39, 46, 40, 30, 35, 186, 47, 197, 41, 22, 48, 185,
        34, 184, 25, 38, 37, 229, 32, 45, 3, 33, 44, 237, 274, 19, 10,
        42, 24, 15, 59, 43, 27, 275, 61, 115, 23, 71, 26, 113, 49, 268,
        236, 213, 117, 20, 36, 9
    ]
)

# Definir la combinación óptima CORR 2023, con componentes optimizadas hasta 2019
# y ponderadores ajustados con datos hasta 2021.
optcorr2023 = let 
    # Componentes de inflación subyacente 
    components = [
        InflationPercentileEq(0.80864954),
        InflationPercentileWeighted(0.80995136), 
        InflationTrimmedMeanEq([55.0, 92.0]),
        InflationTrimmedMeanWeighted([53.5550, 96.4679]),
        InflationDynamicExclusion([0.46, 4.97]),
        optfx2023_corr,
        optmai2023_corr 
    ]

    # Ponderaciones de las demás componentes 
    corr_weights = Float32[
        0.29121402,
        1.3041149f-6,
        0.24843463,
        0.08651825,
        0.053018685,
        0.0,
        0.320901
    ]

    # ELIMINAMOS LA MAI y RE-NORMALIZAMOS
    corr_weights[end] = 0
    corr_weights = corr_weights/sum(corr_weights)        

    # ELIMINAMOS LA MAI y RE-NORMALIZAMOS
    corr_weights[end] = 0
    corr_weights = corr_weights/sum(corr_weights)    

    # Subyacente óptima CORR v2023
    optcorr2023 = CombinationFunction(
        components...,
        corr_weights, 
        "Subyacente óptima CORR 2023",
        "OPTCORR23"
    )

    optcorr2023
end
