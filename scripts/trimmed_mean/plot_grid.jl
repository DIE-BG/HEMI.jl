using DrWatson
@quickactivate "HEMI"

using HEMI
using DataFrames
using Gadfly
using Compose

dir_list    = ["MTEq_SBB36_RW_N10000_Rebase(60)_2020-12",
               "MTEq_SVM_RW_N10000_Rebase(60)_2020-12",
               "MTW_SBB36_RW_N10000_Rebase(60)_2020-12",
               "MTW_SVM_RW_N10000_Rebase(60)_2020-12",
               "MTEq_SVM_RW_N10000_Rebase(36,2)_2019-12",
               "MTW_SVM_RW_N10000_Rebase(36,2)_2019-12",
]

dir = "MTEq_SVM_RW_Rebase36_N999_2019-12"

function plot_grid(dir_name::String, measure=:mse)
            savepath    = datadir("Trimmed_Mean", dir_name)
            plotsave    = plotsdir("Trimmed_Mean", dir_name*"_"*string(measure)*".svg")
            condition   =  measure==:corr  
            sp          = split(dir_name,"_")
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

            layer1 = layer(x=[xmin_params], y=[ymin_params], Geom.point,
                Theme(default_color="black", highlight_width = 0pt))
                
            layer2 = layer(df, x=:ℓ₁, y=:ℓ₂, color=COL, Geom.rectbin)

            p = plot(layer1,layer2,
                Guide.title(plot_title),
                Coord.cartesian(xmin=minimum(df.ℓ₁), xmax=maximum(df.ℓ₁),
                ymin=minimum(df.ℓ₂), ymax=maximum(df.ℓ₂)
                ),
                Guide.annotation(compose(context(),
                text(minimum(df.ℓ₁), minimum(df.ℓ₂), "$txt en: \n ($xmin_params, $ymin_params) \n"*string(measure)*" = $min_measure"))
                ),
                Guide.xlabel("ℓ₁"),
                Guide.ylabel("ℓ₂"),
                Theme(background_color="white",
                major_label_font="CMU Serif", 
                minor_label_font="CMU Serif",
                key_label_font="CMU Serif",
                key_title_font="CMU Serif"),
                )
            img = SVG(plotsave, 7.5inch, 5inch)
            draw(img, p)           
end

#Ejemplo
#plot_grid.(dir_list);