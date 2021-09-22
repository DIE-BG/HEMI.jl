# Función de combinación lineal óptima MSE 2020

# Definir la subyacente MAI óptima, calibrada con datos hasta 2018
optmai2018 = let 
    # Componentes metodologías MAI 
    maifns = [
        InflationCoreMai(MaiFP([0.0, 0.3157660216971966, 0.7047420268794217, 0.7854195537102466, 1.0])),
        InflationCoreMai(MaiF([0.0, 0.31202186036403323, 0.6974472722077761, 0.8209958044003627, 1.0])),
        InflationCoreMai(MaiG([0.0, 0.05335302029790397, 0.5771838102218124, 0.7498971844656707, 0.7756021151058752, 1.0])),
    ]

    # Ponderaciones MAI 
    mai_weights = Float32[0.7348976, 0.24734181, 0.019569023]

    # Subyacente óptima MAI por método MSE 
    optmai = CombinationFunction(
        maifns..., 
        mai_weights, 
        "MAI óptima MSE 2018"
    )

    optmai
end

# Definir la función de exclusión fija
optfx2018 = InflationFixedExclusionCPI(
    [35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193, 161], 
    [29, 116, 31, 46, 39, 40, 186, 30, 35, 185, 197, 34, 48, 184]
)

# Definir la combinación óptima MSE 2020, con componentes optimizadas hasta 2018
# y ponderadores ajustados con datos hasta 2020.
optmse2020 = let 
    # Componentes de inflación subyacente 
    components = [
        InflationPercentileEq(72.3966), 
        InflationPercentileWeighted(69.9966), 
        InflationTrimmedMeanEq(58.7573, 83.1520), 
        InflationTrimmedMeanWeighted(21.0019, 95.8886), 
        InflationDynamicExclusion(0.3158, 1.6832), 
        optfx2018,
        optmai2018 
    ]

    # Ponderaciones de las demás componentes 
    mse_weights = Float32[
        6.6092975f-6, 
        2.0135817f-6, 
        0.7225312, 
        3.1271036f-5, 
        0.022710389, 
        0,
        0.2547185
    ]

    # Subyacente óptima MSE v2020
    optmse2020 = CombinationFunction(
        components...,
        mse_weights, 
        "Subyacente óptima MSE 2020"
    )

    optmse2020
end

@info "Definición de funciones óptimas MSE" optmai2018 optfx2018 optmse2020