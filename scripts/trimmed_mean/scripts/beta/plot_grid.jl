using DataFrames
using Gadfly
using Compose

"""
    plot_grid(plot_grid(dir_name::String, measure=:mse)

Grafica simulaciones en una grilla, puede graficar mse, me o corr.
para las mse y me grafica su inverso. Guarda imágenes en formato .svg
# Ejemplo: 
```
plot_grid("InflationTrimmedMeanEq\\\\Esc-B\\\\MTEq_SVM_RW_Rebase36_N10000_2020-12",:mse)
```
"""
function plot_grid(dir_name::String, measure=:mse)
            savepath    = datadir("results", dir_name)
            last_dir    = split(dir_name, "\\")[end]
            plotsave    = plotsdir("Trimmed_Mean", last_dir*"_"*string(measure)*".svg")
            condition   =  measure==:corr  
            sp          = split(last_dir,"_")
            plot_title  = join(sp,", ")
            df          = collect_results(savepath)
            if condition
                COL = measure
                txt = "máximo"
            else
                df[!,string(measure)*"⁻¹"] = 1 ./ df[:,measure]
                COL = Symbol(string(measure)*"⁻¹")
                txt = "mínimo"
            end
            df.ℓ₁       = [x[1] for x in df.params]
            df.ℓ₂       = [x[2] for x in df.params]
            sorted_df   = sort(df,measure, rev=condition)
            xmin_params = sorted_df[1,:params][1]
            ymin_params = sorted_df[1,:params][2]
            min_measure     = round(sorted_df[1,measure];digits=3)

            layer1 = Gadfly.layer(x=[xmin_params], y=[ymin_params], Gadfly.Geom.point,
                Gadfly.Theme(default_color="black", highlight_width = 0pt))
                
            layer2 = Gadfly.layer(df, x=:ℓ₁, y=:ℓ₂, color=COL, Gadfly.Geom.rectbin)

            p = Gadfly.plot(layer1,layer2,
                Gadfly.Guide.title(plot_title),
                Gadfly.Coord.cartesian(xmin=minimum(df.ℓ₁), xmax=maximum(df.ℓ₁),
                ymin=minimum(df.ℓ₂), ymax=maximum(df.ℓ₂)
                ),
                Gadfly.Guide.annotation(compose(context(),
                text(minimum(df.ℓ₁), minimum(df.ℓ₂), "$txt en: \n ($xmin_params, $ymin_params) \n"*string(measure)*" = $min_measure"))
                ),
                Gadfly.Guide.xlabel("ℓ₁"),
                Gadfly.Guide.ylabel("ℓ₂"),
                Gadfly.Theme(background_color="white",
                major_label_font="CMU Serif", 
                minor_label_font="CMU Serif",
                key_label_font="CMU Serif",
                key_title_font="CMU Serif"),
                )
            img = SVG(plotsave, 7.5inch, 5inch)
            draw(img, p)
            println(last_dir*"_"*string(measure)*".svg   guardado en:")   
            println(plotsdir("Trimmed_Mean"))      
end
