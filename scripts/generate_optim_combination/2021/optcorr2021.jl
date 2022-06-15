# Función de combinación lineal óptima CORR 2021

# Definir la subyacente MAI óptima, calibrada con datos hasta 2018
optmai_corr2021 = let 
    # Componentes metodologías MAI 
    maifns = [
        InflationCoreMai(MaiF(0:1/4:1)),
        InflationCoreMai(MaiG(0:1/4:1)),
        InflationCoreMai(MaiF(0:1/5:1)),
        InflationCoreMai(MaiG(0:1/5:1)),  
        InflationCoreMai(MaiF(0:1/10:1)),
        InflationCoreMai(MaiG(0:1/10:1)),    
        InflationCoreMai(MaiF(0:1/20:1)),
        InflationCoreMai(MaiG(0:1/20:1)), 
        InflationCoreMai(MaiF(0:1/40:1)),
        InflationCoreMai(MaiG(0:1/40:1)),                   

    ]

    # Ponderaciones MAI 
    mai_weights = Float32[0.39292914, 0.0010296146, -0.12367518, -0.020025676, 0.089189611, -0.00080909702, -0.021402787, 0.020015646, 0.081670269, 0.012343562]

    # Subyacente óptima MAI por método CORR 
    optmai = CombinationFunction(
        maifns..., 
        mai_weights, 
        "MAI óptima CORR"
    )

    optmai
end

# Definir la función de exclusión fija
optfx_corr2021 = InflationFixedExclusionCPI(
    [35,30,190,36,37,40,31,104,162,32,33,159,193,161], 
    [29,31,116,39,46,40,30,35,186,47,197,41,22,48,185,34,184]
)

# Definir la combinación óptima CORR 2021.
optcorr2021 = let 
    # Componentes de inflación subyacente 
    components = [
        InflationPercentileEq(80), 
        InflationPercentileWeighted(80), 
        InflationTrimmedMeanEq(57.5, 92), 
        InflationTrimmedMeanWeighted(52.5, 97), 
        InflationDynamicExclusion(0.3590, 2.5004), 
        optfx_corr2021,
        optmai_corr2021 
    ]

    # Ponderaciones de las demás componentes 
    corr_weights = Float32[
    0.11271564, 
    2.3623791e-06, 
    0.15484397, 
    1.1524639e-05, 
    3.9541479e-08,    
    0.15967090,  
    0.57275558]

    # Subyacente óptima CORR v2021
    optcorr2021 = CombinationFunction(
        components...,
        corr_weights, 
        "Subyacente óptima CORR 2021"
    )

    optcorr2021
end

@info "Definición de funciones óptimas CORR" optmai_corr2021 optfx_corr2021 optcorr2021 