using Gadfly
using DataFrames
using Colors

inflfn1    = InflationTrimmedMeanEq(57.5, 84)
inflfn2    = InflationTrimmedMeanWeighted(15,97) 

dir_list = [datadir("results", string(typeof(inflfn1)),"Esc-A"), datadir("results", string(typeof(inflfn2)),"Esc-A")]


dates    = infl_dates(gtdata)   
LEN      = length(infl_dates(gtdata))
vec_name = [measure_tag(InflationTotalCPI()) for i in 1:LEN]
vec_val  = InflationTotalCPI()(gtdata)

DF0 = DataFrame(inflfn = vec_name, fecha = dates, π = vec_val)

for x in dir_list
    df = collect_results(x)
    vec_name = [measure_tag(df.inflfn[1]) for i in 1:LEN]
    vec_val  = df.inflfn[1](gtdata)
    DF1 = DataFrame(inflfn = vec_name, fecha = dates, π = vec_val)
    DF0 = vcat(DF0,DF1)
end

lay1 = layer(DF0, x =:fecha , y=:π , color =:inflfn, Geom.line)
lay0 = layer(x=dates, y=[4.0 for x in dates] , Geom.line, Theme(default_color="black"))
lay2 = layer(x=[dates[1],dates[1],dates[end],dates[end]], 
            y=[3.0,5.0,5.0,3.0], Geom.polygon(preserve_order=true, fill=true), 
            color=[RGB(.0, .1, .25)], alpha=[0.5])


plot(lay0,lay1, lay2, 

    Guide.colorkey(title="" , pos = [0.0mm, 2.50cm]),
    Guide.yticks(ticks = -1:15),
    Guide.xlabel(""),
    Guide.ylabel(""),
    Scale.y_continuous,
    Coord.cartesian(xmin=minimum(DF0.fecha), xmax=maximum(DF0.fecha),
                    ymin=minimum(DF0.π)-1, ymax=maximum(DF0.π)+1),
    
    Theme(background_color="white", 
        major_label_font="CMU Serif", 
        minor_label_font="CMU Serif",
        key_label_font="CMU Serif",
        key_title_font="CMU Serif"),    

)

