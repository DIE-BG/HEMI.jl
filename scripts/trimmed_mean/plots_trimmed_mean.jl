using Base: parameter_upper_bound
using DrWatson
@quickactivate "HEMI"

using HEMI

using Optim
using LaTeXStrings
using CSV
using DataFrames
using Gadfly
using Compose

gtdata_eval         = gtdata[Date(2020, 12)]
gtdata_eval_legacy  = gtdata[Date(2019, 12)]
Dates_gtdata        = Date("2001-12-01"):Month(1):Date("2021-06-01")
Dates_eval          = Date("2001-12-01"):Month(1):Date("2020-12-01")
Dates_legacy        = Date("2001-12-01"):Month(1):Date("2019-12-01")
N_iter_1 = 10_000
N_iter_2 = 125_000
trendfn = TrendRandomWalk()

LIST = [[gtdata_eval, InflationTrimmedMeanEq, ResampleSBB(36), N_iter_1, ParamTotalCPIRebase, LinRange(25,65,41), LinRange(70,100,31)],
        [gtdata_eval, InflationTrimmedMeanEq, ResampleScrambleVarMonths(), N_iter_1, ParamTotalCPIRebase, LinRange(25,65,41), LinRange(70,100,31)],
        [gtdata_eval, InflationTrimmedMeanWeighted, ResampleSBB(36), N_iter_1, ParamTotalCPIRebase, LinRange(18,58,41), LinRange(70,100,31)],
        [gtdata_eval, InflationTrimmedMeanWeighted, ResampleScrambleVarMonths(), N_iter_1, ParamTotalCPIRebase, LinRange(10,50,41), LinRange(70,100,31)],
        [gtdata_eval_legacy, InflationTrimmedMeanEq, ResampleScrambleVarMonths(), N_iter_1, ParamTotalCPILegacyRebase, LinRange(25,65,41), LinRange(70,100,31)],
        [gtdata_eval_legacy, InflationTrimmedMeanWeighted, ResampleScrambleVarMonths(), N_iter_1, ParamTotalCPILegacyRebase,  LinRange(0,40,41), LinRange(70,100,31)]
]

NAMES = []
for k in 1:length(LIST)
    savepath   = datadir("Trimmed_Mean",string(LIST[k][2]),string(LIST[k][3]),string(LIST[k][4]),string(LIST[k][5]))
    plotname   = string(LIST[k][2])*"_"*string(LIST[k][3])*"_"*string(LIST[k][4])*"_"*string(LIST[k][5])*".png"
    plotname2  = string(LIST[k][2])*"_"*string(LIST[k][3])*"_"*string(LIST[k][4])*"_"*string(LIST[k][5])*".svg"
    plottitle  = string(LIST[k][2])*", "*string(LIST[k][3])*"\n N="*string(LIST[k][4])*", "*string(LIST[k][5])
    plotsave   = plotsdir("Trimmed_Mean", plotname)
    plotsave2  = plotsdir("Trimmed_Mean", plotname2)
    push!(NAMES,[savepath,plotsave,plotsave2,plottitle,plotname,plotname2])
end

k=4
curr = "C:\\Users\\DJGM\\Documents\\GitHub\\HEMI\\data\\Trimmed_Mean\\Nuevo"

df          = collect_results(curr)
df.mse⁻¹    = 1 ./ df.mse
df.ℓ₁       = [x[1] for x in df.params]
df.ℓ₂       = [x[2] for x in df.params]
sorted_df   = sort(df, "mse")
xmin_params = sorted_df[1,:params][1]
ymin_params = sorted_df[1,:params][2]
min_mse     = round(sorted_df[1,:mse];digits=3)

layer1 = layer(x=[xmin_params], y=[ymin_params], Geom.point,
                Theme(default_color="black", highlight_width = 0pt)
)

layer2 = layer(df, x=:ℓ₁, y=:ℓ₂, color=:mse⁻¹, Geom.rectbin)

p = plot(layer1,layer2,
    Guide.title(NAMES[k][4]),
    Coord.cartesian(xmin=minimum(df.ℓ₁), xmax=maximum(df.ℓ₁),
    ymin=minimum(df.ℓ₂), ymax=maximum(df.ℓ₂)
    ),
    Guide.annotation(compose(context(),
        text(xmin_params-6, ymin_params-4, "($xmin_params, $ymin_params) \n mse = $min_mse"))
    ),
    Guide.xlabel("ℓ₁"),
    Guide.ylabel("ℓ₂")
)

img = SVG(NAMES[k][3], 6inch, 4inch)
draw(img, p)

OPTIM  = [(61.0f0, 76.0f0), (56.94879f0, 88.43475f0), (38.60325f0, 86.02319f0), (17.221561f0, 97.95325f0), (62.0f0, 84.0f0), (17.23389f0, 97.624054f0)]
OPTIM2 = [(round(Float64(x[1]);digits=2),round(Float64(x[2]),digits=2)) for x in OPTIM]

lay1 = layer(x=Dates_gtdata, y=InflationTotalCPI()(gtdata), Geom.line, Theme(default_color="green"))
lay2 = layer(x=Dates_gtdata, y=InflationTrimmedMeanEq(OPTIM[1])(gtdata), Geom.line, Theme(default_color="blue"))
lay3 = layer(x=Dates_gtdata, y=InflationTrimmedMeanEq(OPTIM[2])(gtdata), Geom.line, Theme(default_color="red"))
lay4 = layer(x=Dates_gtdata, y=InflationTrimmedMeanWeighted(OPTIM[3])(gtdata), Geom.line, Theme(default_color="orange"))
lay5 = layer(x=Dates_gtdata, y=InflationTrimmedMeanWeighted(OPTIM[4])(gtdata), Geom.line, Theme(default_color="purple"))

plot(lay1,lay2, lay3, lay4, lay5,
    Coord.cartesian(xmin=Dates_gtdata[1], xmax=Dates_gtdata[end]),
    Guide.xlabel(""),
    Guide.ylabel("π"),
    Guide.manual_color_key("", 
        ["π total", 
        "Eq"*string(OPTIM2[1]),
        "Eq"*string(OPTIM2[2]),
        "W"*string(OPTIM2[3]),
        "W"*string(OPTIM2[4]),
        ], 
        ["green", "blue", "red", "orange", "purple"])
)
