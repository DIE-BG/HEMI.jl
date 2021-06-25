pargentrayinfl() -> Generar trayectorias de inflación
evalinfl() -> Evaluar medida de inflación

# pargentrajinfl
# parallel_trajectory_generate


# Nombres sugeridos para tipos de funciones de inflación 

InflationTotalCPI
InflationTotalCPIRebase

Percentil => InflationPercentileEq
InflationPercentileWeighted

InflationTrimmedMeanEq
InflationTrimmedMeanWeighted

InflationFixedExclusionCPI
InflationInflationDynamicExclusionCPI

InflationWeightedMean
InflationSimpleMean

InflationCoreMai

# Posibilidad de crear alias para las medidas

const IPEQ = InflationPercentileEq


# Funciones de remuestreo
ResampleSBB
ResampleGSBB

# Funciones de tendencia
TrendRandomWalk
TrendNoTrend
TrendExp

# Periodos para evaluación 
PeriodBase2010
PeriodBase2000
PeriodComplete
PeriodTrans0010
PeriodTrans1022

# Parámetro 
ParamTotalCPIRebase
ParamTotalCPI
ParamWeightedMean



# Tipo para representar parámetros de simulación y evaluación

# Parámetros de simulación 
simparams = SimParams(
	resample = ResampleSBB(25), 
	period = PeriodBaseComplete(), 
	trend = TrendRand(), 
	numsims = 125_000, 
	parameter = ParamTotalCPIRebase(), 
	finaldate = Date(2020,12,1)
	) 

# Función de inflación 
totalfn = InflTotalCPI() 

# Generamos trayectorias 
tray_infl = pargentrayinfl(totalfn, simparams)

# Evaluamos trayectorias 
results = evalinfl(tray_infl, simparams) # Obtener parámetro y computar métricas de evaluación

# Guardar resultados en tablas
# ...

# Graficar resultados (barras, etc) 

# Graficar trayectorias promedio ... 


