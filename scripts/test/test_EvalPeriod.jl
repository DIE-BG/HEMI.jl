using DrWatson 
@quickactivate "HEMI"

using HEMI
using Test 

@testset "Pruebas de EvalPeriod" begin

# Creamos dos períodos de evaluación 
comp = CompletePeriod() 
b2010 = EvalPeriod(Date(2011,1), Date(2019,12), "b2010")

# Se obtiene una trayectoria de inflación 
t = InflationTotalCPI()(GTDATA)

# Obtenemos las máscaras para evaluar sobre períodos específicos 
m = eval_periods(GTDATA, b2010)
@test m isa BitVector
t[m, :, :]

m = eval_periods(GTDATA, comp)
@test m isa AbstractRange
t[m, :, :]


## Configuraciones de prueba 

# Esto genera una configuración de períodos por defecto
config = SimConfig(
    InflationTotalCPI(),
    ResampleScrambleVarMonths(), 
    TrendAnalytical(GTDATA, t -> 1 + sin(2π*t/12), "Tendencia sinusoidal"), 
    InflationTotalRebaseCPI(36, 2), 
    1_000, 
    Date(2020, 12)
)

# Esto genera una configuración de períodos específicos de evaluación
config2 = SimConfig(
    InflationTotalCPI(),
    ResampleScrambleVarMonths(), 
    TrendAnalytical(GTDATA, t -> 1 + sin(2π*t/12), "Tendencia sinusoidal"), 
    InflationTotalRebaseCPI(36, 2), 
    10_000, 
    Date(2020, 12), 
    (CompletePeriod(), EvalPeriod(Date(2008,1), Date(2009,12), "crisis"))
)

@test config isa SimConfig 
@test config2 isa SimConfig 

# Comprobamos que la máscara funciona bien aún si los datos tienen menor rango
# de fechas 
gtdata19 = GTDATA[Date(2019, 12)]
@test eval_periods(gtdata19, CompletePeriod()) isa AbstractRange
@test eval_periods(gtdata19, GT_EVAL_B10) isa BitVector

# O si el período de evaluación dado contiene al rango de fechas de los datos
m = eval_periods(GTDATA, EvalPeriod(Date(2000,1), Date(2025,2), "custom"))

@test length(m) == infl_periods(GTDATA)
@test all(m) 


end 