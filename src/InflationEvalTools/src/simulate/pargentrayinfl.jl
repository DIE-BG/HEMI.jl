"""
Esta constante se utiliza para fijar el generador de números aleatorios en
cada proceso al generador `MersenneTwister` con semilla inicial cero. 
"""
const LOCAL_RNG = Random.MersenneTwister(0)

## Función de generación de trayectorias de inflación de simulación 
# Esta función considera como argumento la función de remuestreo para poder
# aplicar diferentes metodologías en la generación de trayectorias, así como la
# función de tendencia aplicar 

"""
    pargentrayinfl(inflfn::F, resamplefn::R, trendfn::T, csdata::CountryStructure; K = 100, rndseed = 0, showprogress = true)

Computa `K` trayectorias de inflación utilizando la función de inflación
`inflfn::`[`InflationFunction`](@ref), la función de remuestreo
`resamplefn::`[`TrendFunction`](@ref) y la función de tendencia
`trendfn::`[`TrendFunction`](@ref) especificada. Se utilizan los datos en el
`CountryStructure` dado en `csdata`.

A diferencia de la función [`gentrayinfl`](@ref), esta función implementa el
cómputo distribuido en procesos utilizando `@distributed`. Esto requiere que el
paquete haya sido cargado en todos los procesos de cómputo. Por ejemplo: 

```julia 
using Distributed
addprocs(4, exeflags="--project")
@everywhere begin
    using HEMI 
    using InflationEvalTools
end
```

Para lograr la reproducibilidad entre diferentes corridas de la función, y de
esta forma, generar trayectorias de inflación con diferentes metodologías
utilizando los mismos remuestreos, se fija la semilla de generación de acuerdo
con el número de iteración en la simulación. Para controlar el inicio de la
generación de trayectorias se utiliza como parámetro de desplazamiento el valor
`rndseed`. 
"""
function pargentrayinfl(inflfn::F, resamplefn::R, trendfn::T, 
    csdata::CountryStructure; 
    K = 100, 
    rndseed = 0, 
    showprogress = true) where {F <: InflationFunction, R <: ResampleFunction, T <: TrendFunction}

    # Cubo de trayectorias de inflación de salida
    periods = infl_periods(csdata)
    n_measures = num_measures(inflfn)
    tray_infl = SharedArray{Float32}(periods, n_measures, K)

    # Variables para el control de progreso
    progress= Progress(K, enabled=showprogress)
    channel = RemoteChannel(()->Channel{Bool}(K), 1)

    # Tarea asíncrona para actualizar el progreso
    @async while take!(channel)
        next!(progress)
    end
        
    # Tarea de cómputo de trayectorias
    @sync @distributed for k in 1:K 
        # Configurar la semilla en el proceso
        Random.seed!(LOCAL_RNG, rndseed + k)
        
        # Muestra de bootstrap de los datos 
        bootsample = resamplefn(csdata, LOCAL_RNG)
        # Aplicación de la función de tendencia 
        trended_sample = trendfn(bootsample)

        # Computar la medida de inflación 
        tray_infl[:, :, k] = inflfn(trended_sample)

        put!(channel, true)
    end 
    put!(channel, false)

    # Retornar las trayectorias
    sdata(tray_infl)
end
