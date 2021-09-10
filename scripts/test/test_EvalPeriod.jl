using DrWatson 
@quickactivate "HEMI"

using HEMI

# Creamos dos períodos de evaluación 
comp = CompletePeriod() 
b2010 = EvalPeriod(Date(2011,1), Date(2019,12), "b2010")

# Se obtiene una trayectoria de inflación 
t = InflationTotalCPI()(gtdata)

# Obtenemos las máscaras para evaluar sobre períodos específicos 
m = eval_periods(gtdata, b2010)
t[m, :, :]

m = eval_periods(gtdata, comp)
t[m, :, :]


## Configuraciones de prueba 

# Esto genera una configuración de períodos por defecto
config = SimConfig(
    InflationTotalCPI(),
    ResampleScrambleVarMonths(), 
    TrendAnalytical(gtdata, t -> 1 + sin(2π*t/12), "Tendencia sinusoidal"), 
    InflationTotalRebaseCPI(36, 2), 
    1_000, 
    Date(2020, 12)
)

# Esto genera una configuración de períodos específicos de evaluación
config2 = SimConfig(
    InflationTotalCPI(),
    ResampleScrambleVarMonths(), 
    TrendAnalytical(gtdata, t -> 1 + sin(2π*t/12), "Tendencia sinusoidal"), 
    InflationTotalRebaseCPI(36, 2), 
    10_000, 
    Date(2020, 12), 
    (CompletePeriod(), EvalPeriod(Date(2008,1), Date(2009,12), "crisis"))
)

# Comprobamos que la máscara funciona bien aún si los datos tienen menor rango
# de fechas 
gtdata19 = gtdata[Date(2019, 12)]
eval_periods(gtdata19, CompletePeriod())
eval_periods(gtdata19, GT_EVAL_B10)

# O si el período de evaluación dado contiene al rango de fechas de los datos
eval_periods(gtdata, EvalPeriod(Date(2000,1), Date(2025,2), "custom"))