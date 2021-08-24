using DrWatson
@quickactivate "HEMI"
using Plots
using DataFrames
using Chain
using PrettyTables


## Cargar el módulo de Distributed para computación paralela
using Distributed
# Agregar procesos trabajadores
addprocs(4, exeflags="--project")

# Cargar los paquetes utilizados en todos los procesos
@everywhere using HEMI

# Cargar scripts auxiliares para optimización
include(scriptsdir("trimmed_mean","scripts","grid_batch.jl"))
include(scriptsdir("trimmed_mean","scripts","grid_optim.jl"))

# Definimos directorios donde se guardan y recolectan datos de este script
# NOTA: no es necesario incluir datadir(), las funciones grid_batch() y grid_optim()
# automáticamente incluyen datadir().
save_dirs = [joinpath("results","InflationTrimmedMeanEq","Esc-C"),
             joinpath("results","InflationTrimmedMeanWeighted","Esc-C")
]


## SIMULACION DE GRILLA ---------------------------------------------------------------
# Simulamos nuestras funciones en un grilla donde el eje X es un rango de valores
# para el límite inferior l1 y el eje Y es un rango de valores para elel límite 
# superior l2 en las funciones de Media Truncada. El objetivo de la grilla es 
# encontrar un punto de arranque para la optimización, debido a que esta utiliza
# un número mucho mayor de simulaciones que la grilla y puede ser muy tardada si no
# le proporcionamos un valor inicial que sea cercano al verdadero óptimo.

grid_batch(gtdata,InflationTrimmedMeanEq, ResampleScrambleVarMonths(),
            TrendRandomWalk(),10_000, 45:75, 70:100,InflationTotalRebaseCPI(60),
            Date(2019,12);save_dir = save_dirs[1]
)

grid_batch(gtdata,InflationTrimmedMeanWeighted, ResampleScrambleVarMonths(),
            TrendRandomWalk(),10_000, 5:35, 70:100,InflationTotalRebaseCPI(60),
            Date(2019,12);save_dir = save_dirs[2]
)

## OPTIMIZACION ----------------------------------------------------------------------------
# definimos los directorios donde se encuentran los resultados de la grilla
dir_list = [joinpath(save_dirs[1],"MTEq_SVM_RW_Rebase60_N10000_2019-12"), 
            joinpath(save_dirs[2],"MTW_SVM_RW_Rebase60_N10000_2019-12")
]

# corremos el script para optimizar, es decir encontrar el punto mínimo para cada
# función, en donde el punto de arranque es el mínimo de la grilla. 
grid_optim(dir_list[1],gtdata,125_000,7 ; save_dir = save_dirs[1])
grid_optim(dir_list[2],gtdata,125_000,7 ; save_dir = save_dirs[2])


## GRAFICACION ------------------------------------------------------------------------------------
# definimos los directorios donde se encuentran los resultados de la optimización.
dirs = [joinpath(save_dirs[1],"optim"),
        joinpath(save_dirs[2],"optim")
]

# cargamos los datos
df1 = collect_results(datadir("results",dirs[1]))
df2 = collect_results(datadir("results",dirs[2]))
df3 = vcat(df1,df2)

# filtramos datos basandonos en una condición
cond = (df3[:,:traindate].== Date(2019,12))
df = DataFrame(df3[cond,:])

# Graficamos
p = plot(InflationTotalCPI(), gtdata, fmt = :svg)
plot!(df.inflfn[1], gtdata, fmt = :svg)
plot!(df.inflfn[2], gtdata, fmt = :svg)

# guardamos la imágen en el siguiente directorio
plotpath = joinpath("docs", "src", "eval", "EscC", "images", "trimmed_mean")
Plots.svg(p, joinpath(plotpath, "trayectorias_MT2019"))

## ----------------------------------------------------------------------------------------------
# ESTO NO ES PARTE DEL SCRIPT. SE UTILIZA UNICAMENTE PARA ELABORAR LAS TABLAS EN LA PAGINA HEMI

#=
df.tag = measure_tag.(df.inflfn)

res1 = @chain df begin 
    select(:tag, :mse, :mse_std_error)
    sort(:mse)
    filter(r -> r.mse < 1, _)
    filter(:tag => s -> !occursin("FP",s), _)
end

res2 = @chain df begin 
    select(:tag, :mse, r"^mse_[bvc]")
    sort(:mse)
    filter(r -> r.mse < 1, _)
    filter(:tag => s -> !occursin("FP",s), _)
end

res3 = @chain df begin 
    select(:tag, :rmse, :me, :mae, :huber, :corr)
    sort(:rmse)
    filter(r -> r.rmse < 1, _)
    filter(:tag => s -> !occursin("FP",s), _)
end

tab1 = pretty_table(res1, tf=tf_markdown, formatters=ft_round(4))
tab2 = pretty_table(res2, tf=tf_markdown, formatters=ft_round(4))
tab3 = pretty_table(res3, tf=tf_markdown, formatters=ft_round(4))
=#