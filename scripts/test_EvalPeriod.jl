using DrWatson 
@quickactivate "HEMI"

using HEMI

# using InflationEvalTools

comp = CompletePeriod() 
b2010 = EvalPeriod(Date(2011,1), Date(2019,12), "b2010")

gtdata

infl_dates(gtdata)

t = InflationTotalCPI()(gtdata)

m = eval_periods(gtdata, b2010)
m = eval_periods(gtdata, comp)

t[m, :, :]


##
config = SimConfig(
    InflationTotalCPI(),
    ResampleScrambleVarMonths(), 
    TrendAnalytical(gtdata, t -> 1 + sin(2π*t/12), "Tendencia sinusoidal"), 
    InflationTotalRebaseCPI(36, 2), 
    1_000, 
    Date(2020, 12)
)

config2 = SimConfig(
    InflationTotalCPI(),
    ResampleScrambleVarMonths(), 
    TrendAnalytical(gtdata, t -> 1 + sin(2π*t/12), "Tendencia sinusoidal"), 
    InflationTotalRebaseCPI(36, 2), 
    10_000, 
    Date(2020, 12), 
    (CompletePeriod(), EvalPeriod(Date(2008,1), Date(2009,12), "crisis"))
)


gtdata19 = gtdata[Date(2019, 12)]
eval_periods(gtdata19, CompletePeriod())
eval_periods(gtdata19, GT_EVAL_B10)

eval_periods(gtdata, EvalPeriod(Date(2000,1), Date(2025,2), "custom"))
