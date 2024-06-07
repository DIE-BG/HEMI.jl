# Función de combinación lineal óptima CORR 2022

# Definir la subyacente MAI óptima, calibrada con datos hasta 2018
optmai2018_corr = let 
    # Componentes metodologías MAI 
    maifns = [
        InflationCoreMai(MaiG([0.0, 0.3231946132649845, 0.7717202163095981, 1.0])),
        InflationCoreMai(MaiFP([0.0, 0.3353888879842171, 0.6564704398723811, 0.7811211272248946, 0.8605862966662162, 1.0])),
        InflationCoreMai(MaiF([0.0, 0.3184050564725187, 0.6564814400376782, 0.7772641818257944, 0.871023576880708, 1.0])),
    ]

    # Ponderaciones MAI 
    mai_weights = Float32[0.0058168247, 0.434901, 0.5593101]

    # Subyacente óptima MAI por método CORR 
    optmai = CombinationFunction(
        maifns..., 
        mai_weights, 
        "MAI óptima CORR 2018"
    )

    optmai
end

# Definir la función de exclusión fija
optfx2018_corr = InflationFixedExclusionCPI{3}((
    [35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159], 
    [29, 116, 31, 46, 39, 40, 186, 30, 35, 185, 197, 34, 
        48, 184, 41, 47, 37, 22, 25, 229, 38, 32, 274, 3, 
        45, 44, 33, 237, 19, 10, 24, 275, 115, 15, 59, 42, 
        61, 43, 113, 49, 27, 71, 23, 268, 9, 36, 236, 78, 
        20, 213, 273, 26
    ],
    []
))

# Definir la combinación óptima CORR 2022, con componentes optimizadas hasta 2018
# y ponderadores ajustados con datos hasta 2020.
optcorr2022 = let 
    # Componentes de inflación subyacente 
    components = [
        InflationPercentileEq(0.7725222f0), 
        InflationPercentileWeighted(0.809557f0), 
        InflationTrimmedMeanEq(55.90512f0, 92.17767f0), 
        InflationTrimmedMeanWeighted(46.443233f0, 98.54608f0), 
        InflationDynamicExclusion(0.4683226f0, 4.9745145f0), 
        optfx2018_corr,
        optmai2018_corr 
    ]

    # Ponderaciones de las demás componentes 
    corr_weights = Float32[
        0.19322012,
        3.930421f-5, 
        0.46787307,
        0.0,
        0.0019428643, 
        0.0,  
        0.3369246, 
    ]

    # Subyacente óptima CORR v2022
    optcorr2022 = CombinationFunction(
        components...,
        corr_weights, 
        "Subyacente óptima CORR 2022"
    )

    optcorr2022
end

@info "Definición de funciones óptimas CORR" optmai2018_corr optfx2018_corr optcorr2022 
