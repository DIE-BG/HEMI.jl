using DrWatson
@quickactivate :HEMI
using InflationFunctions

simplemeanfn = InflationSimpleMean()
simplemeanfn(gt10)
tray_infl_gt = totalfn(gtdata)

