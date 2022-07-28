### A Pluto.jl notebook ###
# v0.19.10

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ d722fbf0-eb4f-11eb-2fef-b19a7566ba31
begin
	import Pkg
	Pkg.activate("..")
	
	using PlutoUI
	using Revise
	using DrWatson, HEMI, Plots
	using LaTeXStrings
	
	using InflationFunctions: ObservationsDistr, WeightsDistr, AccumulatedDistr
	using InflationFunctions: vposition, get_segments_list, renormalize!, renorm_g_glp, renorm_f_flp
	using InflationFunctions: V
end

# ╔═╡ ec957b42-5a6f-46be-986d-e7b99cfda80d
md"""
# Método de muestra ampliada implícitamente (MAI) 

Aspectos conceptuales y procedimiento de cómputo.

"""

# ╔═╡ 0f5e97c1-2125-4766-99fc-fda1f71bb391
PlutoUI.TableOfContents(aside=true, title="Contenido", depth=2)

# ╔═╡ 4b605b91-44df-49cf-8c0c-8566e30cc598
md"""
## Objetivos

- Conocer los aspectos conceptuales acerca de la medida de inflación subyacente MAI.
- Involucrarse en el proceso técnico de implementación de los algoritmos en el lenguaje de programación Julia.
- Aplicar la metodología de evaluación de la HEMI sobre este estimador muestral de inflación. 
- Que los participantes presenten resultados al aplicar la metodología de la HEMI a otros estimadores muestrales.
"""

# ╔═╡ 928289db-c42e-4a55-bb04-bac4b33ae379
md"""
## Otra visión de la inflación

- La inflación es un fenómeno no observable que varía en el tiempo.
- Mes a mes, el INE toma una muestra de precios de diferentes rubros y en diferentes puntos del país, con el objetivo de estimar el nivel de precios en la economía.
- En este sentido, las medidas de inflación derivadas del IPC son estadísticos de las muestras recolectadas por el INE.
- Existen diferentes tipos de estadísticos (estimadores muestrales): la variación interanual del IPC, medias truncadas, percentiles, medias móviles, métodos de exclusión fija, etc.
- En esta visión de la inflación, existe una literatura de medidas de inflación que presentan mejores propiedades estadísticas en la estimación de la inflación (no observable).

"""

# ╔═╡ 137b9a66-66fb-467a-a3af-20572f5286c2
md"""
## Introducción 

- Medida de inflación derivada del análisis de la distribución de variaciones intermensuales de índices de precios en el IPC de Guatemala.
- Procedimiento estadístico que utiliza una “muestra grande” de observaciones históricas.
- No elimina variaciones intermensuales atípicamente altas o bajas, sino que las transforma.
- Esta modificación neutraliza los efectos de valores atípicos (subyacente).
- La sustitución de “muestra ampliada implícitamente” permite mantener las propiedades estadísticas de la distribución de largo plazo de las variaciones intermensuales de índices de precios.

"""

# ╔═╡ 1d59e61c-4cdf-43c6-970f-868beaeffe9b
md"""
## Utilización

- Utilizada en el DIE para el análisis de presiones inflacionarias.
- Insumo para el modelo macroeconómico semiestructural.
- Conceptualizada como un estadístico (estimador) de la inflación intermensual e interanual.
> Podría pensarse que es un estadístico “con memoria” debido a que utiliza información histórica para obtener la inflación intermensual.

"""

# ╔═╡ 0d1bf735-062f-44d7-bd70-2c25f16e8f59
md"""
# Aspectos conceptuales

A continuación, se describen algunos aspectos conceptuales y definiciones matemáticas que permiten formalizar el cómputo de la inflación subyacente MAI de un período particular.

"""

# ╔═╡ 96e18948-5150-4193-bc93-b78daf87f067
md"""
## El IPC de Guatemala

- El INE publica mensualmente cada uno de los índices de precios correspondientes a un conjunto representativo de los bienes y servicios de consumo de la economía guatemalteca.
- En los años 2000, los índices fueron publicados por el INE utilizando como mes de referencia diciembre de 2000.
- Actualmente, los índices de precios en el IPC se encuentran publicados utilizando como referencia el mes de diciembre de 2010, en el cual todos los índices de precios toman un valor de 100.
"""

# ╔═╡ 535f144b-02fa-47b2-9990-9b8c033c42cb
md"""
## Matriz de índices de precios

Sea $b \in \left\lbrace 2000, 2010 \right\rbrace$ el índice utilizado para referirse a cada una de las bases de datos de índices de precios al consumidor de la canasta representativa de la economía guatemalteca.
"""

# ╔═╡ 793cabab-c5d4-4ad3-bf22-fb1bef99aad1
md"""
Sea $IPC^{(b)}$ la matriz de índices de precios para cada uno de los gastos y servicios de la base $b$.

$$IPC^{(b)} = \left [ 
\begin{array}{cccc}
i_{0,1}^{(b)} & i_{0,2}^{(b)} & \ldots & i_{0,N_b}^{(b)} \\
i_{1,1}^{(b)} & i_{1,2}^{(b)} & \ldots & i_{1,N_b}^{(b)} \\
i_{2,1}^{(b)} & i_{2,2}^{(b)} & \ldots & i_{2,N_b}^{(b)} \\
\vdots & \vdots & \ddots & \vdots \\
i_{T_b,1}^{(b)} & i_{T_b,2}^{(b)} & \ldots & i_{T_b,N_b}^{(b)} \\
\end{array} 
\right ] = \left ( i_{t, x}^{(b)} \right ) \in \mathbb{R}^{(T_b+1) \times N_b}$$
	
	
Donde $t$ y $x$ indexan las observaciones temporales y los gastos, respectivamente. $T_b$ representa el número total de observaciones para la base $b$, y $N_b$ el número total de gastos básicos de la base $b$.
	Finalmente, notar que $i_{0,x}^{(b)}$ representa el índice de precios base del gasto básico $x$. Así, $i_{0,x}^{(b)} = 100 \;\forall\, x \in \lbrace 1, 2, \ldots, N_b \rbrace$. 
"""

# ╔═╡ 3d5c920b-964d-4755-8867-96bddbe5d83d
capitalize(gt00.v)

# ╔═╡ e1387332-9b1e-4358-8fac-1de63a7f1e92
md"""
Para la base 2000 del IPC, $T_b = 120$ y $N_b = 218$. El período de observaciones de índices de precios está comprendido desde enero de 2001 hasta diciembre de 2010 y hay un total de 218 gastos básicos considerados en el cálculo del IPC. Por otro lado, para la base 2010 del IPC, $T_b$ es variable y $N_b = 279$. 

En la base 2010 del IPC, el período de observaciones de índices de precios está comprendido desde enero de 2011, hasta la fecha, y además, hay un total de 279 gastos básicos considerados en el cálculo del IPC. Como referencia, $T_b = 120$ en diciembre de 2020 y así sucesivamente, hasta la fecha actual.
"""

# ╔═╡ e083e30b-b6c9-4655-90f6-a7ac5f71704b
md"""

## Variaciones intermensuales

Sea $V^{(b)}$ la matriz de variaciones intermensuales de índices de precios de cada uno de los gastos básicos de la base $b$. 
	
$$V^{(b)} = \left [
\begin{array}{cccc}
v_{1,1}^{(b)} & v_{1,2}^{(b)} & \ldots & v_{1,N_b}^{(b)} \\
v_{2,1}^{(b)} & v_{2,2}^{(b)} & \ldots & v_{2,N_b}^{(b)} \\
\vdots & \vdots & \ddots & \vdots \\
v_{T_b,1}^{(b)} & v_{T_b,2}^{(b)} & \ldots & v_{T_b,N_b}^{(b)} \\
\end{array} 
\right ] = \left ( v_{t,x}^{(b)} \right ) \in {\mathbb{R}}^{T_b \times N_b}$$
	
Donde $v_{t,x}^{(b)}$ es la variación intermensual del gasto básico $x$ en el mes $t$, expresada como porcentaje. Cada variación intermensual $v_{t,x}^{(b)}$ se computa a partir del cambio porcentual en el índice de precios del gasto básico $x$, respecto al período anterior, obtenido de la matriz $IPC^{(b)}$ como sigue: 

$$v_{t,x}^{(b)} = 100 \left ( \frac{i_{t,x}^{(b)} - i_{t-1,x}^{(b)}}{i_{t-1,x}^{(b)}} \right ), \quad t = 1, 2, \ldots, T_b \, ; \, x = 1, 2, \ldots, N_b$$ 
"""

# ╔═╡ 605481ae-77ee-4628-a19c-324307ae5eac
gt00.v

# ╔═╡ da808075-4dec-4426-947e-0e1292947288
gt10.v

# ╔═╡ 3ceec3c2-3bac-4276-8bb7-072c433fe61a
md"""
## Ponderaciones

Cada uno de los gastos básicos en la matriz de índice de precios $IPC^{(b)}$ posee una ponderación que sirve para computar el IPC como un promedio ponderado de los índice de precios de los gastos básicos.

Sea $W^{(b)}$ el vector fila de ponderaciones correspondientes a cada uno de los gastos básicos de la matriz de índice de precios $IPC^{(b)}$. El vector está conformado como sigue: 

$$W^{(b)} = \left[ 
\begin{array}{cccc}
w^{(b)}_1 & w^{(b)}_2 & \ldots & w^{(b)}_{N_b} \\
\end{array}
\right]$$ 

donde la suma de todas las ponderaciones es igual a 1, esto es: $$\sum_{x} w^{(b)}_x = 1$$
"""

# ╔═╡ ebd08f30-0617-4ff7-b07c-da446bb2745d
gt10.w

# ╔═╡ ab127c7b-e1d4-4b92-aad7-6790bbfabb99
size(gt10.w)

# ╔═╡ 7c894360-bae4-4827-b26b-536d05f15338
sum(gt10.w)

# ╔═╡ ead7a6c4-c632-41e2-beb4-8ee1303fca74
md"""
## Ventanas mensuales

Para llevar a cabo el cómputo de inflación intermensual, considere la "ventana" o muestra pequeña de variaciones intermensuales. 

Sea $V^{(b)}_{t}$ la ventana mensual de variaciones intermensuales de índices de precios de la base $b$ en el período $t$, representada como un vector fila y obtenida como una submatriz de $1 \times N_b$ de la matriz de variaciones $V^{(b)}$: 
	
$$V^{(b)}_{t} = V^{(b)}\left [t; 1,2,\;\ldots\;,N_b \right ] = \left ( v_{t,x}^{(b)} \right ) \in {\mathbb{R}}^{1 \times N_b}$$
	
en donde $t$ representa la fila de la matriz de variaciones $V^{(b)}$, tomando todos los gastos básicos de la matriz, es decir, las columnas $1, 2, \ldots, N_b$.
"""

# ╔═╡ 6f57de61-45b4-49e4-b189-d825a887604a
gt00.v[1, :]

# ╔═╡ 2bef3af2-964f-4731-ba6f-9b397f3a1c88
md"""
Para el resto de este cuaderno introductorio, definimos la siguiente ventana de variaciones intermensuales con su correspondiente vector de ponderaciones
"""

# ╔═╡ f7326714-1ac5-4a04-aa76-1e01679226bc
md"""
Base del IPC: $(@bind basestr Select(["gt00" => "Base 2000", "gt10" => "Base 2010"]))
"""

# ╔═╡ ddbbc8dc-9f45-4561-bbe4-026afffdfa19
md"""
 $t=$ $(@bind t Slider(basestr == "gt00" ? (1:120) : (1:132), show_value=true))
"""

# ╔═╡ a6ad31b4-5d49-4a78-8508-4628fd52b95d
begin 
	# Selección de ventana y ponderaciones
	local base = eval(Symbol(basestr))
	Vt = base.v[t, :]
	Wb = base.w
end;

# ╔═╡ 2cc3a548-0bd4-44b0-b963-cbd8782cbbd5
gt10.dates[t]

# ╔═╡ 8db73f78-82de-4b60-bdda-a526e8df1bef
gt10.dates[t]

# ╔═╡ b2708891-0e2e-47ca-bd7f-6458346b6d8b
md"""
Ventana mensual: 
"""

# ╔═╡ 30dfac77-2379-4cdf-b2f2-ff295fca0bfa
Vt

# ╔═╡ b1d815b1-36f9-4bdb-96f5-0ddfbb0e0549
md"""
Vector de ponderaciones asociado: 
"""

# ╔═╡ 4c1d468f-66cb-4d85-bcf0-2c08d4710acb
Wb

# ╔═╡ 11c25418-b567-4c9f-ada2-c0da447c8fb5
md"""
## Grilla de variaciones intermensuales

- Las variaciones intermensuales de índices de precios se ordenan agrupan en una grilla discreta. 
- Sobre esta grilla se construyen diferentes funciones de densidad de ponderaciones u ocurrencias.
- La grilla de variaciones intermensuales representa el conjunto de dominio de dichas funciones de densidad.
- Para construir la grilla se utiliza una variable de precisión $\varepsilon$ que define la distancia entre los elementos de la grilla. Típicamente, $\varepsilon = 10^{-2} = 0.01$. 

Nota: 
- *Debido a que las variaciones intermensuales están expresadas en porcentajes, estas son registradas con precisión de hasta $10^{-4}$*.
- *Históricamente, las variaciones intermensuales observadas en Guatemala desde el año 2001 se encuentran contenidas en un rango de $\left[ -100\%, 100\% \right]$. Es decir que, hasta la fecha, no se ha observado que ninguno de los gastos básicos haya duplicado su índice de precios, ni que este haya caído drásticamente hacia cero, de un mes a otro*.
"""

# ╔═╡ 5ecd2dfc-8630-45c1-b10c-fd447c108a06
md"""
Para las definiciones presentadas más adelante, considere el conjunto de variaciones intermensuales con precisión $\varepsilon$:

$$\begin{array}{c}%
V_\varepsilon = \left\lbrace v_i \;|\; v_i \in \left[-200, 200\right]; i \in \left\lbrace 1,2,\ldots, n \right\rbrace; \right.\\%
\left. v_1 = -200; (v_i-v_{i-1}) = \varepsilon \quad\forall i \geq 2 \right\rbrace \\%
\end{array}$$

donde el número de elementos $n$ del conjunto está dado por 

$$n = \frac{400}{\varepsilon} + 1$$

Además, considere el vector de grilla de variaciones intermensuales $v_{\varepsilon}$ como un vector fila con los elementos de $V_{\varepsilon}$ ordenados ascendentemente, como se describe a continuación:
   
$$v_{\varepsilon} = \left[ 
\begin{array}{ccccc}
-200 & (-200+\varepsilon) & (-200+2\varepsilon) &\ldots & 200 \\
\end{array} 
\right]$$
"""

# ╔═╡ 84804321-007b-45b6-a639-7e014a8eb94f
V

# ╔═╡ b45d7991-7384-4af9-81c8-de6ac76b84c6
collect(V)

# ╔═╡ 8b493fe6-a3c8-4c4d-9cf0-8ed09eb51a14
md"""
Por ejemplo, con $\varepsilon = 10^{-2}$, el vector de grilla de variaciones es:

$$V_{0.01} = \left[ 
\begin{array}{cccccccccc}
-200.00 & -199.99 & \ldots & -0.01 & 0.00 & 0.01 & \ldots & 199.99 & 200.00 \\
\end{array} 
\right]$$

¿Cuál es el número de posiciones en la grilla?
"""

# ╔═╡ 64b18be0-89b3-4dcc-9851-417e3dd52b85
length(V)

# ╔═╡ 4dfb444e-fb89-4d0b-bf08-fd848fed318c
md"""
## Cálculo de posiciones en la grilla

- La grilla de variaciones está indexada desde posición $1$, hasta la posición $n$, como se definió anteriormente. 

- La primera posición corresponde a la variación intermensual $-200$, y la posición $n$ a la variación $200$, es decir, $\mathtt{pos}(-200) = 1$ y $\mathtt{pos}(200) = n$.
- En algunos cálculos, es necesario conocer qué posición corresponde a una determinada variación intermensual en el vector de grilla. 

"""

# ╔═╡ 5dbf0091-a34e-4c9d-859e-3a440193cf2b
md"""
- Para esto se utiliza la siguiente ecuación: 
$$\mathtt{pos}(v) = \mathtt{pos}(0) + \left\lfloor \frac{v}{\varepsilon} \right\rceil \qquad \forall \, v \in \left [ -200, 200 \right ]$$

donde $\mathtt{pos}(0)$ representa la posición de la variación cero, calculada como 

$$\mathtt{pos}(0) = \frac{200}{\varepsilon} + 1$$

y $\lfloor \cdot \rceil$ es la función de *entero próximo*.

Como $\lfloor \frac{v}{\varepsilon} \rceil$ mantiene el signo de $v$, para computar la posición de una variación intermensual se suma o resta la posición relativa de $v$ a la posición de la variación cero, dando como resultado la posición absoluta de la variación intermensual $v$, comprendida entre $1$ y $n$. La función de entero próximo se implementa en Julia utilizando `vposition(v, vspace)` en donde `vspace` representa la grilla de variaciones.

"""

# ╔═╡ 3a3077b2-9f5b-45b2-a95f-9af623e55c81
md"""
### Ejemplo
"""

# ╔═╡ d7dd2148-de33-45f8-b765-08ff5197678e
md"""
Como ejemplo: con una precisión de $\varepsilon = 10^{-2}$ se tiene una grilla de $40001$ elementos. Si se desea calcular la posición de la variación intermensual $v= -0.130892$ entonces se procede como sigue: 

$$\mathtt{pos}(0) = \frac{200}{0.01} + 1 = 20001$$

Luego: 

$$\mathtt{pos}(v) = \mathtt{pos}(0) + \left\lfloor \frac{-0.130892}{0.01} \right\rceil = 20001 - 13 = 19988$$
"""

# ╔═╡ 187e4642-2e95-4eb8-bc19-7620bf002b2c
vposition(0, V)

# ╔═╡ b0a34f54-7369-47d5-b1be-3bcd06b2799a
round(Int, -0.130892 / 0.01) 

# ╔═╡ de137105-52b0-4b45-8a2b-81754757871a
vposition(-0.130892, V)

# ╔═╡ f86e12d5-64a2-4276-b1e9-2e14233a7e21
range(-400, 400, step=0.01f0)

# ╔═╡ e6a87aec-ce7a-4a52-90ac-a86e69a23efa
md"""
# Distribuciones muestrales de variaciones intermensuales

Para llevar a cabo el cómputo de inflación MAI se utilizan las siguientes funciones de densidad de las variaciones intermensuales de índices de precios:
    
- Distribución de frecuencias de ocurrencia de variaciones intermensuales ponderadas por las participaciones del IPC ($g_t$).
- Distribución de frecuencias de ocurrencia de variaciones intermensuales ($f_t$).
"""

# ╔═╡ 2221671b-7a6e-4dba-b7dc-80e271a5ed28
md"""
## Distribución $g_t$

- Consiste en una función discreta, definida sobre $V_\varepsilon$ y se construye a partir de la ocurrencia de las variaciones intermensuales de índices de precios, utilizando las ponderaciones de los gastos básicos en el IPC y puede interpretarse como una función de densidad de ocurrencia de los valores observados: 

$$g_{t}(v) : V_\varepsilon \rightarrow \left[0,1\right]$$

y a la vez, la suma de la densidad para todas las variaciones intermensuales es igual a 1, esto es:  

$$\sum_{v_i \in V_{\varepsilon}} g_{t}(v_i) = 1$$

- Se representa utilizando un vector disperso, con la misma dimensión que el vector de grilla.

- Para su construcción, utilizamos una ventana mensual de variaciones intermensuales $V^{(b)}_t$ y el vector de ponderaciones $W^{(b)}$ correspondiente.
"""

# ╔═╡ 99f469f5-5152-4799-a9d2-9ed77e4c57c0
md"""
### Algoritmo 

Para construir la función de densidad $g_t$ utilizamos el tipo `WeightsDistr`
"""

# ╔═╡ 8908cb22-7e0a-4a0d-86c2-af02470eab40
g = WeightsDistr(Vt, Wb, V)

# ╔═╡ dcdf8bae-c30c-4a4c-a9bb-155258da9225
# with_terminal() do 
# 	println(g)
# end

# ╔═╡ 416e4983-035f-4185-b28c-d28be1b10cae
plot(g, xlims=(-7, 7))

# ╔═╡ 0b6f340f-5007-4351-bcd8-4f280880cf16
Dump(g)

# ╔═╡ b1974f1f-f6e1-41f3-8e79-66bc1662de6a
md"""
### Interpretación 

- Si $g_t$ se interpreta como la función muestral de densidad de ocurrencia de las variaciones intermensuales $v_{t,x}$ correspondientes a cualquier ventana $V^{(b)}_t$ de un período en particular, entonces su promedio ponderado:  

$$E(v^{(b)}_t) = g_t\,v_\varepsilon^\prime = \sum_{v_i \in V_{\varepsilon}} v_i\,g_{t}(v_i) = \sum_x w^{(b)}_x v^{(b)}_{t,x} = \mathrm{MPm}^{(b)}_t$$

En el período $t$, $E(v^{(b)}_t)$ es exactamente la media ponderada (MPm) de las variaciones intermensuales del período $t$.

- Esta media ponderada también se puede computar como el producto escalar entre el vector con la función de densidad $g_t$ y el vector de grilla de variaciones intermensuales $V_\varepsilon$.
"""

# ╔═╡ 3e46fc96-7114-431b-aed1-20f1f1252780
sum(gt00.v[1, :] .* gt00.w) / 100

# ╔═╡ 3524c263-3adb-418a-8be8-30b378445b08
mean(g) 

# ╔═╡ 748134bc-3856-44f3-9a85-f4e126ff8c0d
md"""
### Distribución acumulada
"""

# ╔═╡ 2b2638c1-a7a5-49ea-a612-979474d7d7b4
Gt = cumsum(g)

# ╔═╡ 2975fb0e-2a6f-4867-b3b0-eb69d3128a2e
plot(Gt, xlims=(-2,7))

# ╔═╡ 4a93d0d0-7b13-4220-b076-32a157606c40
md"""
## Distribución $f_t$

- La función de densidad $f_{t}: V_{\varepsilon} \rightarrow \left[0,1\right]$ se construye de forma similar a la función de densidad $g_t$.

- Se consideran idénticas todas las ponderaciones de los gastos básicos correspondientes a las variaciones intermensuales.

- Esta función de densidad se puede interpretar como una función de densidad de ocurrencia de observaciones de variaciones intermensuales.

	
- Para su cómputo, considere el algoritmo utilizado para la distribución $g_t$, considerando las ponderaciones como $w^{(b)}_{x} = 1 / N_b$.
		
- Su construcción sea equivalente a la de obtener un histograma de frecuencias normalizado de las variaciones intermensuales de índices de precios en una ventana o período.
"""

# ╔═╡ 2e2ecd5a-bfda-4b37-b26e-12293831740e
md"""
### Algoritmo 

Para construir la función de densidad $f_t$ utilizamos el tipo `ObservationsDistr`
"""

# ╔═╡ a2fca38f-8519-4956-872e-8d744ebf4d92
f = ObservationsDistr(Vt, V)

# ╔═╡ 640e9426-996a-4fac-8de4-36daacd0f5ac
plot(f, xlims=(-7, 7))

# ╔═╡ 2e28138e-b50d-4345-9e7d-ab9a5804e073
Dump(f)

# ╔═╡ 7652d811-ca5e-43ff-ae0b-ede97c7c6986
md"""
### Interpretación 

- Si la función $f_t$ se interpreta como la función muestral de densidad de probabilidad de las variaciones intermensuales, entonces su valor esperado es: 

$$E(v^{(b)}_t) = f_t\,v_\varepsilon^\prime = \sum_{v_i \in V_{\varepsilon}} v_i\,f_{t}(v_i) = \frac{1}{N_b} \sum_x v^{(b)}_{t,x} = \mathrm{MEm}^{(b)}_t$$

El promedio ponderado de las variaciones intermensuales $E(v^{(b)}_t)$ en el período $t$ es exactamente la media equiponderada (MEm) de las mismas.
- Esta media también se puede computar como el producto escalar entre el vector con la función de densidad $f_t$ y el vector de grilla de variaciones intermensuales $v_\varepsilon$.

"""

# ╔═╡ 7c5c8db1-7c27-4bd0-ac57-5613e0ac829f
mean(gt00.v[1, :])

# ╔═╡ da0dee29-0cd7-420f-a20a-768945529fa7
mean(f) 

# ╔═╡ 948d7192-facb-4e3f-80ed-fb62ab1bbc3b
md"""
### Distribución acumulada
"""

# ╔═╡ ad923e3b-92ff-4670-9dd5-25022e54df85
Ft = cumsum(f) 

# ╔═╡ 341c042d-e622-41e4-93be-62472a27efb8
plot(Ft, xlims=(-2,7)) 

# ╔═╡ 342e77e1-a763-48f8-9f83-2e4396db6656
md"""
## Distribución g de largo plazo (*glp*)

- Se construye de forma similar a la función de densidad $g_t$, considerando las ocurrencias observadas históricamente. 

- Se incluyen solamente **años completos** en la historia.

- Puede considerarse un reflejo del comportamiento histórico de las variaciones intermensuales de los índices de precios de los gastos básicos en Guatemala y por lo tanto, **no se encuentra asociada a un período en particular**.

Implementación: 
- La función de densidad *glp* se conforma utilizando todas las variaciones intermensuales de las bases 2000 y 2010 del IPC. 

- Considere una sola "ventana" $V^{*}$ que contenga todas las variaciones intermensuales de las bases del IPC 2000 y 2010, cuyas ponderaciones asociadas sean $W^{*}$.

- La función *glp* se construye utilizando el algoritmo de la distribución $g_t$, *mutatis mutandis*, con la ventana $V^{*}$ y el vector $W^{*}$ como entradas. 
"""

# ╔═╡ f71f0d24-8236-4a12-80d1-738e53ea0e12
begin
	V_star = vcat(gt00.v[:], gt10.v[1:132, :][:])
	W_star = vcat(repeat(gt00.w', 120)[:], repeat(gt10.w', 132)[:])
	glp = WeightsDistr(V_star, W_star, V)
end

# ╔═╡ 6c5bd5de-cb87-4a60-b407-fddf2c1cf931
# Número de observaciones en V_star, en la muestra ampliada
length(V_star)

# ╔═╡ d0f22c65-f172-4e83-ad79-c75d6c46d571
with_terminal() do 
	print(glp)
end

# ╔═╡ eae96716-47ae-410e-adbc-bc863b9832c9
plot(glp, xlims=(-1,2), seriestype=:bar, linealpha=0, label = "glp")

# ╔═╡ e81a2a75-373c-41b5-8a4c-57608c4b12f9
md"""
La densidad de la variación intermensual cero es: 
"""

# ╔═╡ d591df05-1ac3-4081-9261-ef9ffb7c66d3
glp(0)

# ╔═╡ 7a3b0421-5d0a-47e3-8de8-0557979f3975
md"""

De forma similar con la función $g_t$, si la función $\mathrm{glp}(v)$ se interpreta como la función de densidad de probabilidad de las variaciones intermensuales $v_{t,x}$ correspondientes a la ventana $V^{*}$ que contiene el histórico de variaciones intermensuales, entonces su valor esperado $E(v)$ es exactamente el promedio de la medias ponderadas en todos los períodos de la ventana $V^{*}$.

- Al utilizar una ventana $V^{*}$ de observaciones históricas, su valor esperado $E(v)$ es exactamente el promedio de la medias ponderadas (MPm) en todos los períodos de la ventana $V^{*}$.

$$\begin{split}
E(v) & = glp\cdot v_\varepsilon^\prime = \sum_{v_i \in V_{\varepsilon}} v_i\,glp(v_i) \\
& = \frac{1}{T_{2000} + T^*_{2010}} \sum_{b}\sum_{t=1}^{T_b}\sum_x w^{(b)}_x v^{(b)}_{t,x} \\
& = \frac{1}{T_{2000} + T^*_{2010}} \sum_{b}\sum_{t=1}^{T_b}\mathrm{MPm}^{(b)}_t
\end{split}$$

"""

# ╔═╡ e33f1222-8f29-4591-9db9-dee8938a306f
mean(glp)

# ╔═╡ 2d0aa4be-31d6-4712-b169-2ef25fa4afc2
begin
	# El valor anterior debe ser muy cercano a mpm
	mpm0 = gt00.v * gt00.w / 100
	mpm1 = gt10.v[1:120, :] * gt10.w / 100
	mpm = vcat(mpm0, mpm1)
	mean(mpm)
end

# ╔═╡ 8251b8fb-f975-45bf-bf74-7a1f037c6c13
md"""
### Distribución acumulada
"""

# ╔═╡ 7f79d6a1-9e3a-4b8e-8478-bf1bc9257241
GLP = cumsum(glp) 

# ╔═╡ 8bb62d79-96f2-4e54-b834-4cef0256c8f4
plot(GLP, xlims=(-2,5))

# ╔═╡ bf70158e-81db-49e5-96d5-ccd5ecaa381c
1 - GLP(0) 

# ╔═╡ 37d28a04-b2dc-4402-9bec-56ecc27b5550
md"""
## Distribución f de largo plazo (*flp*)

- Similar a la función de densidad $f_t$, pero considera ocurrencias de variaciones intermensuales observadas históricamente y no toma en cuenta las ponderaciones de las variaciones intermensuales en su construcción.

- Similar a la función de densidad *glp*, considera años completos en su cómputo.

- También puede considerarse un reflejo del comportamiento histórico de las variaciones intermensuales en Guatemala.

- Se obtiene el histograma normalizado de variaciones intermensuales de índices de precios de la base 2000 y 2010 del IPC.

- También sería posible, utilizar el algoritmo de la función $g_t$ con ponderaciones $w^{(b)}_{x} = 1 / N_b$ en cada una de las bases y utilizando una sola ventana $V^{*}$ con todas las variaciones intermensuales.
"""

# ╔═╡ 87b845e0-e778-4ac3-ac4f-f9e2252ea20c
flp = ObservationsDistr(V_star, V)

# ╔═╡ f7e63c15-11aa-4aa7-946f-d489c700df7f
with_terminal() do 
	println(flp)
end

# ╔═╡ a3bac26b-10a5-451a-82c2-2b730aef9346
plot(flp, xlims=(-1,2), seriestype=:bar, linealpha=0)

# ╔═╡ 1631b796-78e7-400e-9575-6494a63a7873
md"""
La densidad de la variación intermensual cero es:
"""

# ╔═╡ 9170753e-b5a3-4ee2-8e0d-b343c316a74c
flp(0)

# ╔═╡ 670c5227-49ed-479f-9fa4-0ad97f87a05c
md"""

- Si la función *flp* se interpreta como la función muestral de densidad de probabilidad de las variaciones intermensuales $v_{t,x}$ correspondientes a la ventana $V^{*}$, entonces su valor esperado es el promedio de todas las $\mathrm{MEm}$.
$$\begin{split}
E(v) & = flp\cdot v_\varepsilon^\prime = \sum_{v_i \in V_{\varepsilon}} v_i\,flp(v_i) \\
& = \frac{1}{T_{2000} + T^*_{2010}} \sum_{b}\sum_{t=1}^{T_b}\sum_x (1/N_b) \, v^{(b)}_{t,x} \\
& = \frac{1}{T_{2000} + T^*_{2010}} \sum_{b}\sum_{t=1}^{T_b}\mathrm{MEm}^{(b)}_t
\end{split}$$
entonces su valor esperado $E(v)$ es exactamente el promedio de la medias equiponderadas en todos los períodos de la ventana $V^{*}$. Este promedio también se puede computar como el producto escalar entre el vector con la función de densidad *flp* y el vector de grilla de variaciones intermensuales $v_\varepsilon$.
"""

# ╔═╡ 4a7870fb-9be4-4f72-a54e-1d144f5794b2
mean(flp)

# ╔═╡ 490d77ff-3c79-4cfd-85c9-9d7688be9291
mean(V_star)

# ╔═╡ 90c5a65b-d3a6-4d60-9953-81e718524548
md"""
### Distribución acumulada
"""

# ╔═╡ 3b73f01d-ef58-4a45-8eac-1c1b8ad4c4bb
FLP = cumsum(flp) 

# ╔═╡ 2c457b05-c6ac-40df-b3aa-b9ba0f6f4171
with_terminal() do 
	println(FLP)
end

# ╔═╡ df737c62-2754-46e0-818e-2b365c6c906b
plot(FLP, xlims=(-2, 5))

# ╔═╡ 4bccbf09-7a05-444d-aa60-7ff3766748e8
md"""
## Comparación de distribuciones de largo plazo
"""

# ╔═╡ 7c755659-4209-4714-936e-28a6d8965669
begin
	plot(FLP, xlims=(-2,5), label="FLP")
	plot!(GLP, xlims=(-2,5), label="GLP")
end

# ╔═╡ 5ee20275-eecf-4738-a018-f96024bf6ba6
md"""
## Percentiles de las distribuciones

- La inflación subyacente MAI se computa utilizando diferentes cuantiles de las distribuciones $f_t$ y $g_t$, así como los percentiles de las distribuciones *flp* y *glp*. 

- En particular, es posible computar una inflación intermensual $\mathrm{MAI}_{i}$, representada por $\bar{v}_{\mathrm{MAI}, t}^{(i)}$, utilizando $i$ segmentos de las distribuciones de variaciones intermensuales de cada mes, de acuerdo con la definición siguiente.

"""

# ╔═╡ 8be9921e-4535-4cf8-b6f3-5939dbd37598
md"""
### Percentil próximo

Sea $q_{y,k}^{(i)}$ el percentil $(k/i)$ de la función de densidad $\mathbf{y}$ de variaciones intermensuales, en el cual $k = 0, 1, \ldots, i$ representa el número de percentil, e $i$ el número de segmentos en que se particiona el vector $\mathbf{y}$. Dicho percentil verifica que en la función de densidad acumulada $\mathbf{Y}$, obtenida a partir de $\mathbf{y}$, se acumule una densidad aproximada a $(k/i)$, correspondiente  un percentil teórico, de tal forma que:

$$q_{y,k}^{(i)}  \triangleq \arg\min_{v_j \in V_\varepsilon} |\mathbf{Y}(v_j) - k/i|$$
"""

# ╔═╡ 272d4be4-33af-44df-a313-befb89cb4515
md"""
### Implementación

- En Julia, extendemos el método `Statistics.quantile`.
"""

# ╔═╡ e0047781-6cb3-4cee-a894-78acc5f33fb5
which(quantile, (AccumulatedDistr, Real))

# ╔═╡ 88acf18f-7709-4ba0-b6bf-da77f032dedd
quantile(FLP, 0.5) 

# ╔═╡ 566dc8c2-7010-49a2-b9f6-958bc55e8778
0:0.2:1 |> collect

# ╔═╡ 99dd9a8f-2266-4ab9-94d9-61043811fabd
q_flp = quantile(FLP, 0:0.2:1)

# ╔═╡ 39f116e8-e5c1-439b-9cf9-f15a50d15cb6
md"""

- Note que $q_{y,0}^{(i)}$ representa el percentil $0$, que corresponde a la mínima variación intermensual en el dominio de la función de densidad $\mathbf{y}$. Similarmente, $q_{y,i}^{(i)}$ corresponde a la máxima variación intermensual en el dominio de la función de densidad $\mathbf{y}$.  


- En la función de densidad acumulada $\mathbf{Y}$, permiten que 

$$Y \left( q_{y,0}^{(i)} - \varepsilon \right) = 0, \quad Y \left( q_{y,i}^{(i)} \right) = 1,$$
"""

# ╔═╡ 2f18642b-a8e8-47de-a549-428953baf704
FLP(q_flp[1] - 0.01), FLP(q_flp[end])

# ╔═╡ da1a532c-58c9-42fc-b112-a4baa23848e6
FLP(q_flp[1] - 0.01)

# ╔═╡ c215620e-a5ea-47bd-b49b-8d8d89ed659c
md"""
# Cómputo de inflación MAI

- La inflación subyacente MAI se obtiene a través de un proceso estadístico que involucra a las distribuciones $f_t$ y $g_t$, así como a las distribuciones de largo plazo *flp* y *glp*.  


- Dicho proceso permite **reponderar las variaciones intermensuales de un determinado período**, tomando en cuenta la baja ocurrencia histórica de los valores extremos.
		
- De esta manera, suaviza variaciones intermensuales asociadas a una ventana, obteniendo una versión suavizada (*filtrada*) del ritmo inflacionario.
"""

# ╔═╡ 8446f083-253a-4e1e-9ad4-58932d4ca102
md"""
- El cómputo utiliza como *parámetro* el número de percentiles $i$ de las distribuciones muestrales $f_t$ y $g_t$. Así como la distribución, o posiciones, de los cuantiles utilizados también podrían considerarse como parámetros.


- La inflación intermensual $\mathrm{MAI}_{i}$, representada por $\bar{v}_{\mathrm{MAI}, t}^{(i)}$, divide las distribuciones $f_t$ y $g_t$ en $i$ segmentos, indicados por los percentiles $q_{f_{t},k}^{(i)}$ y $q_{g_{t},k}^{(i)}$, definidos anteriormente.


- Por ejemplo, la inflación intermensual MAI de cuartiles $\bar{v}_{\mathrm{MAI}, t}^{(4)}$ se obtiene a través de los cuartiles de las distribuciones de las distribuciones $f_t$ y $g_t$, así como de las distribuciones de largo plazo. 
"""

# ╔═╡ 62076d20-0fa4-42ed-97cb-a4b693074786
md"""
### Ritmo inflacionario 

- En cada período, la inflación intermensual $\mathrm{MAI}_{i}$ se obtiene como:

$$\bar{v}_{\mathrm{MAI}, t}^{(i)} = (1-\alpha)\,\bar{v}_{\mathrm{MAI}, f,t}^{(i)} + \alpha\,\bar{v}_{\mathrm{MAI}, f,t}^{(i)}$$
		
- El componente $\bar{v}_{\mathrm{MAI}, f,t}^{(i)}$ se obtiene a través de la distribución $f_t$ normalizada con las distribuciones LP.
		
- El componente $\bar{v}_{\mathrm{MAI}, g,t}^{(i)}$ se obtiene a través de la distribución $g_t$ normalizada con las distribuciones LP.
	
- Para computar el ritmo inflacionario, se encadena el resumen intermensual y se computa el estimador de inflación MAI en versión interanual obteniendo la variación interanual:

$$\begin{split}
\pi_{\mathrm{MAI}, t} = & \frac{I_{\mathrm{MAI},t} - I_{\mathrm{MAI},t-1}}{I_{\mathrm{MAI},t-1}} \\
= & \prod_{j=t-11}^{t} \left(1 + \bar{v}_{\mathrm{MAI}, j}\right)  - 1
\end{split}$$
"""

# ╔═╡ c9270e0a-9248-4e36-bafa-af51dda1a166
md"""
Del año 2018 a 2020 se utilizó $\alpha = \frac{1}{2}$ e $i \in \left\lbrace 4,5,10,20,40\right\rbrace$. Es decir, un promedio simple de las medidas basadas en cuartiles, quintiles, deciles, en porciones de densidad del $5\%$ y en porciones de densidad del $2.5\%$.
"""

# ╔═╡ da9539eb-ecf3-415b-8add-8bcb6414561d
md"""

### Combinación lineal de variantes

A partir del año 2021 se utiliza una combinación lineal de las variantes en términos de ritmo inflacionario: 

$$\begin{aligned}
  \pi_{\text{MAI},t} = \, & a_{f,4}\pi_{\text{MAI},f,4,t} + a_{f,5}\pi_{\text{MAI},f,5,t} + a_{f,10}\pi_{\text{MAI},f,10,t} + a_{f,20}\pi_{\text{MAI},f,20,t} + a_{f,40}\pi_{\text{MAI},f,40,t} \\
  ~ & \; + a_{g,4}\pi_{\text{MAI},f,4,t} + a_{g,5}\pi_{\text{MAI},f,5,t} + a_{g,10}\pi_{\text{MAI},f,10,t} + a_{g,20}\pi_{\text{MAI},f,20,t} + a_{g,40}\pi_{\text{MAI},f,40,t}
\end{aligned}$$

Los ponderadores $\mathbf{a}$ se encuentran con la metodología de la HEMI. Esto lo veremos con detalle más adelante. Primero necesitamos construir el estimador interanual.
"""

# ╔═╡ d6d13501-4b14-40e4-bcb3-1c16843eef20
md"""
## Inflación intermensual MAI-G

- Se obtiene como un promedio ponderado de la función de densidad de largo plazo *glp* renormalizada. 
		
- A partir de la imposición de los $i$ percentiles de la función de densidad $g_t$ del mes $t$.
		
- A la función de densidad *glp* renormalizada la llamaremos $glp_{t}$.
		
- Esta función de densidad de las variaciones intermensuales será proporcional, por segmentos, a la distribución de largo plazo *glp* y será consistente con las condiciones inflacionarias representadas por los percentiles de la función de densidad $g_t$.
		
- Los percentiles caracterizan el posicionamiento de la distribución de las variaciones intermensuales de precios del mes $t$, sin verse fuertemente afectados por los valores atípicamente extremos que tienen una influencia excesiva en las distribuciones mensuales de variaciones intermensuales de precios $f_t$ y $g_t$, debido a que estas se generan a partir de muestras relativamente pequeñas.
"""

# ╔═╡ 4e9d615c-f16d-42d7-a798-b95156a28559
md"""
La proporcionalidad de $glp_{t}$ respecto a *glp* implica que los valores atípicamente extremos no tienen ponderaciones desproporcionadas, propias de su ocurrencia en muestras pequeñas.

Por el contrario, **tienen más bien ponderaciones consistentes con su frecuencia de ocurrencia de largo plazo**. Es decir, sus ponderaciones son consistentes con su frecuencia de ocurrencia en una muestra grande, y por lo tanto, tienen efectos moderados sobre la medición de inflación resultante.

Por lo tanto, $glp_{t}$ es: 

- Consistente con las condiciones inflacionarias prevalecientes del período $t$.

- Y a la vez, es consistente con una muestra grande de observaciones de variaciones intermensuales.
"""

# ╔═╡ 41a183d6-5db7-4854-9bd6-c388f033e2f7
md"""
### Algoritmo de cómputo
"""

# ╔═╡ ce5d1861-c998-4b85-8fec-ee7c9132fbf4
md"""
Escogemos el número de segmentos a utilizar para el proceso de normalización: 
"""

# ╔═╡ 84902e13-3c42-4d69-af7d-8531d6352991
md"""
También escogemos las posiciones a utilizar para renormalizar las funciones de densidad. Por ahora, utilizamos los que dividen en partes iguales el espacio de cuantiles $[0,1]$. 
"""

# ╔═╡ 2b78811f-d59e-4ac3-9dee-a0c07cb44731
md"""
**Paso 1.** De los $i$ percentiles en la distribución *glp*, se deben encontrar los dos que rodean la variación intermensual cero.
		
- Sean $q_{glp, \underline{k}}^{(i)}$ y $q_{glp, \overline{k}}^{(i)}$ los percentiles más cercanos a la variación cero.
		
- Formalmente:
$$\begin{split}
\underline{k} = & \arg\max_k \,q_{glp,k}^{(i)} \,, \quad \text{sujeto a} \quad q_{glp,k}^{(i)} < 0 \\
\overline{k} = & \arg\min_k \,q_{glp,k}^{(i)} \,, \quad \text{sujeto a} \quad q_{glp,k}^{(i)} > 0
\end{split}$$ 
"""

# ╔═╡ afdbff35-7d0d-4d48-bcb5-66e422352d2c
md"""
**Paso 2.** En la función de densidad $g_{t}$ del período $t$, se deben encontrar también los percentiles que rodean a la variación intermensual cero.
		
- Sean $q_{g_{t}, \underline{s}}^{(i)}$ y $q_{g_{t}, \overline{s}}^{(i)}$ los percentiles más cercanos a cero.
		
- De tal forma que:
$$\begin{split}
\underline{s} = & \,\arg\max_s \,q_{g_{t},s}^{(i)} \,, \quad \text{sujeto a} \quad q_{g_{t},s}^{(i)} < 0 \\
\overline{s} = & \,\arg\min_s \,q_{g_{t},s}^{(i)} \,, \quad \text{sujeto a} \quad q_{g_{t},s}^{(i)} > 0
\end{split}$$
"""

# ╔═╡ 2d7fc594-f3ca-4fc4-8b20-efd5d5925ff9
md"""
**Paso 3.** Para el proceso de normalización de *glp* utilizando los  percentiles de $g_{t}$ se deben considerar el mismo número de segmentos. 
	
- Por lo que se define un segmento especial que rodea a la variación cero, con números de percentiles $\overline{r}$ y $\underline{r}$, dados por:
$$\begin{split}
\overline{r} = & \max \left\lbrace \overline{k}, \overline{s} \right\rbrace \\
\underline{r} = & \min \left\lbrace \underline{k}, \underline{s} \right\rbrace
\end{split}$$
"""

# ╔═╡ b2744061-113e-4348-b7bb-efcc0bb01de8
md"""
**Paso 4.** Ahora se definirá un conjunto de segmentos sobre los cuales se debe aplicar una constante de proporcionalidad (o escalamiento) para obtener la función de densidad $glp_{t}$.
	
- Considere el conjunto de segmentos $I = \left\lbrace0, 1, \ldots, \underline{r}, \ldots, \overline{r}, \ldots, i\right\rbrace$. 
- Y sea el conjunto de segmentos contenidos en el segmento especial $R = \left\lbrace \underline{r}+1, \ldots, \overline{r}-1 \right\rbrace$, definido alrededor de la variación intermensual cero.
- Entonces, el conjunto de segmentos a normalizar está dado por: 

$$I-R = \left\lbrace0, 1, \ldots, \underline{r}, \overline{r}, \ldots, i\right\rbrace$$ 
"""

# ╔═╡ 0fdf271c-b7ad-482f-affc-0845049c4f8f
md"""
**Paso 5.** Para todos los segmentos $k \in I-R$ (excepto para $k = 0$ o $k = \overline{r}$) la función de densidad $glp_{t}$ en el segmento $k$ estaría dada por:

$$glp_{t}(v) = glp\left(v\right) \, \frac{G_t\left(q_{g_{t}, k}^{\left(i\right)}\right) - G_t\left(q_{g_{t}, k-1}^{\left(i\right)}\right)}{GLP\left(q_{g_{t}, k}^{\left(i\right)}\right) - GLP\left(q_{g_{t}, k-1}^{\left(i\right)}\right)}, \quad q_{g_{t}, k-1}^{\left(i\right)} < v \leq q_{g_{t}, k}^{\left(i\right)}.$$ 

- En el segmento especial ($k = \overline{r}$), la normalización se hace sobre todo el segmento indicado por los percentiles $\underline{r}$ y $\overline{r}$:

$$glp_{t}(v) = glp\left(v\right) \, \frac{G_t\left(q_{g_{t}, \overline{r}}^{\left(i\right)}\right) - G_t\left(q_{g_{t}, \underline{r}}^{\left(i\right)}\right)}{GLP\left(q_{g_{t}, \overline{r}}^{\left(i\right)}\right) - GLP\left(q_{g_{t}, \underline{r}}^{\left(i\right)}\right)}, \quad q_{g_{t}, \underline{r}}^{\left(i\right)} < v \leq q_{g_{t}, \overline{r}}^{\left(i\right)}.$$

Note que en el primer y último segmento, las expresiones requerirán evaluar las funciones de densidad cuando $k=0$ y $k=i$, y por lo tanto, se debe garantizar que las funciones de densidad acumulada correspondan a la evaluación de los valores mínimo y máximo en el conjunto $V_\varepsilon$.
"""

# ╔═╡ b95b2374-9cd1-4583-bbfb-b02ec7e251e9
md"""
Notar que si $k=0$ o $k=i$, los límites del intervalo de normalización deben modificarse apropiadamente: 
- Si $k=0$: 
$$q_{g,0}^{(i)} \triangleq \min(q_{g,0}^{(i)}, q_{glp,0}^{(i)})$$

- Si $k=i$: 
$$q_{g,i}^{(i)} \triangleq \max(q_{g,k}^{(i)}, q_{glp,k}^{(i)})$$
"""

# ╔═╡ e870fbb6-a0e4-4374-bfd3-0da630cbc596
md"""

### Ejemplo de renormalización

A continuación se lleva a cabo la renormalización del primer segmento de la distribución. *Nota: esto podría incluir al segmento especial, dependiendo del valor de $n$*.
"""

# ╔═╡ f47dd797-8d70-436f-8075-8b133f5137c8
md"""
Ahora, renormalizamos la distribución hasta el segundo segmento.
"""

# ╔═╡ 80482a7e-eaa1-499f-b14d-266be0b8867a
md"""
Y continuamos de esta forma hasta renormalizar toda la distribución. 
"""

# ╔═╡ 7424f3cd-94fc-46ba-a3b1-8fe74c5f5935
md"""
### Renormalización automática $glp_t$

Este proceso de renormalización es automatizado con la función `renorm_g_glp`. *Nota: También existe una función de mayor desempeño, utilizada en la definición de `InflationCoreMai`*.

Veamos cómo cambia la distribución $glp_t$ al renormalizar con diferentes números de segmentos.

 $n=$ $(@bind n Slider(3:40, default=5, show_value=true))
"""

# ╔═╡ a01d5d57-e7c4-4d03-bf77-16bd0ae12dc6
p = (0:n) / n

# ╔═╡ 289ec238-0633-4f1d-bc98-3494265a9570
collect(p)

# ╔═╡ e615d881-4a52-4943-8138-17b399ef35f1
q_glp = quantile(GLP, p) 

# ╔═╡ fc22f2da-59c6-440f-aa2a-059f27f9e470
q_g = quantile(Gt, p) 

# ╔═╡ cd48716e-4892-436c-a38e-ac487597c652
print(q_g)

# ╔═╡ 8226ffbb-802e-4577-9ecd-57875dd395bd
segments = get_segments_list(q_g, q_glp, n) 

# ╔═╡ 9dc6d27b-5571-4023-b05b-50e43f90e585
segments

# ╔═╡ cc17dfa5-8302-49b2-ae4f-26f84e05ded3
# Renormalizar el primer segmento 
begin
	local k = segments[2] 
	local k₋₁ = segments[1]
	
	glpt_1 = deepcopy(glp) 
	q_g0 = min(q_g[k₋₁], q_glp[k₋₁])
	
	# Constante de normalización
	local c_norm = (Gt(q_g[k]) - Gt(q_g0)) / (GLP(q_g[k]) - GLP(q_g0))
	renormalize!(glpt_1, q_g0, q_g[k], c_norm)
	c_norm
end

# ╔═╡ 96586a48-e779-4ba0-91d7-35f3aeb67666
begin
	GLPt_1 = cumsum(glpt_1)
	plot(Gt, label=L"G_t")
	plot!(GLP, label=L"G_L")
	plot!(GLPt_1, label=L"G_{Lt}", xlims=(-5, 5))
	scatter!([q_g[segments[2]]], [Gt(q_g[segments[2]])], label="First normalization step")
	hline!([p[segments[2]]], linealpha=0.5, color=:black, label=false)
	# xlims!(-0.1, 0.7)
end

# ╔═╡ 4f37b238-3aa2-4e00-9faf-b26d61917d3e
let
	GLPt_1 = cumsum(glpt_1)
	plot(Gt, label=L"G_t")
	plot!(GLP, label=L"G_L")
	plot!(GLPt_1, label=L"G_{Lt}", xlims=(-5, 5))
	hline!([p[segments[2]]], linealpha=0.5, color=:black, label=false)
	scatter!([q_g[segments[2]]], [Gt(q_g[segments[2]])], label="First normalization step")
	savefig("first_normalization_step.pdf")
end

# ╔═╡ 2efdd051-3847-4fae-a24b-7a8d87cbbd97
segments

# ╔═╡ 3e9ef9dd-7b52-4429-a8f0-12f77b91d341
# Renormalizar el segundo segmento 
begin
	local k = segments[3] # 4
	local k₋₁ = segments[2] # 3
	
	glpt_2 = deepcopy(glpt_1); 

	# Constante de normalización
	local c_norm = (Gt(q_g[k]) - Gt(q_g[k₋₁])) / (GLP(q_g[k]) - GLP(q_g[k₋₁]))
	renormalize!(glpt_2, q_g[k₋₁], q_g[k], c_norm)
	c_norm
end

# ╔═╡ 1c432a8a-e83c-430e-a1ea-cda63206df44
begin
	GLPt_2 = cumsum(glpt_2)
	plot(Gt, label=L"G_t")
	plot!(GLP, label=L"G_L")
	plot!(GLPt_2, label=L"G_{Lt}", xlims=(-5, 5))
	hline!([p[segments[3]]], linealpha=0.5, color=:black, label=false)
	scatter!([q_g[segments[3]]], [Gt(q_g[segments[3]])], label="Second normalization step")
end

# ╔═╡ 19a4b029-6abe-45c8-99bb-48dad7893934
let
	GLPt_2 = cumsum(glpt_2)
	plot(Gt, label=L"G_t")
	plot!(GLP, label=L"G_L")
	plot!(GLPt_2, label=L"G_{Lt}", xlims=(-5, 5))
	hline!([p[segments[3]]], linealpha=0.5, color=:black, label=false)
	scatter!([q_g[segments[3]]], [Gt(q_g[segments[3]])], label="Second normalization step")
	savefig("second_normalization_step.pdf")
end

# ╔═╡ 585c4ec5-b880-4e9f-be45-b9c86d891d78
begin
	glpₜ = renorm_g_glp(Gt, GLP, glp, n)
	
	GLPt = cumsum(glpₜ) 
	plot(Gt, label=L"Gt")
	plot!(GLP, label=L"G_L")
	plot!(GLPt, label=L"G_{Lt}", lw=2, xlims=(-5,5))
end

# ╔═╡ 5c766faa-65bb-486c-969b-2ef909e14686
let
	glpₜ = renorm_g_glp(Gt, GLP, glp, n)
	
	GLPt = cumsum(glpₜ) 
	plot(Gt, label=L"Gt")
	plot!(GLP, label=L"G_L")
	plot!(GLPt, label=L"G_{Lt}", lw=2, xlims=(-5, 5))
	savefig("last_normalization_step.pdf")
end

# ╔═╡ 081602ca-82cc-4072-a34a-0fd326d2d37a
q_glp

# ╔═╡ 9456a534-d6b4-4a8d-8d52-d5fa64c41c15
q_g

# ╔═╡ 6c5c71da-c68b-4bad-8146-2aa17ba13432
segments

# ╔═╡ 4d336858-d661-46f5-8927-c9901d2eef3f
md"""
**Paso 6.** La inflación intermensual $\mathrm{MAI}_{i,g}$ de $i$ segmentos está dada como el promedio ponderado de $glp_{t}$. Esto es:

$$\overline{v}_{\mathrm{MAI}, g, t}^{(i)} = glp_{t}\cdot v_\varepsilon^\prime = \sum_{v_i \in V_{\varepsilon}} v_i\,glp_{t}(v_i).$$

Como resultado de este proceso de normalización, los percentiles de la función de densidad de largo plazo normalizada son iguales a los de la función de densidad $g_t$, esto es: $q_{glp_{t}, k}^{(i)} = q_{g_{t}, k}^{(i)}$.
"""

# ╔═╡ 662a3104-9f4f-4547-acc9-2c1782da499e
mean(glpₜ) 

# ╔═╡ ce56fd18-c13c-41fe-8354-4966f30b3c7f
md"""
Como referencia, comparamos este resumen intermensual contra la media ponderada del mes: 

$$\mathrm{MPm}_t = \sum_x w_x v_{t,x} =$$
"""

# ╔═╡ efe07e03-c5eb-4d22-be91-badd67fe8b33
sum(Vt .* Wb) / 100

# ╔═╡ 0edcdd2e-8b00-4c15-8076-8be69e83d1d4
md"""
## Inflación intermensual MAI-F

- Se obtiene como un promedio simple de la función de densidad de largo plazo *glp* renormalizada. 
		
- A partir de la imposición de los $i$ percentiles de la función de densidad $f_t$ del mes $t$.
		
- A la función de densidad *glp* renormalizada la llamaremos $flp_{t}$.
		
- Esta función de densidad de las variaciones intermensuales será proporcional, por segmentos, a la distribución de largo plazo *glp* y será consistente con las condiciones inflacionarias representadas por los percentiles de la función de densidad $g_t$.
		
- A pesar de que los percentiles utilizados para la imposición y renormalización provienen de las distribuciones $f_t$, se utiliza la función de densidad *glp* para obtener la $flp_{t}$ **debido a que esta considera las ponderaciones asociadas a los gastos básicos en el IPC**.
"""

# ╔═╡ f6b5ce08-4bb1-42ab-9272-42790b33704e
md"""
Nuevamente, la proporcionalidad de $flp_{t}$ respecto a *glp* implica que los valores atípicamente extremos no tienen ponderaciones desproporcionadas, propias de su ocurrencia en muestras pequeñas.

Por lo tanto, $flp_{t}$ es: 
		
- Consistente con las condiciones inflacionarias prevalecientes del período $t$ de acuerdo a los percentiles de ocurrencias.

- Y a la vez, es consistente con una muestra grande (de largo plazo) de observaciones de variaciones intermensuales.

"""

# ╔═╡ 4ebb2e7e-95c9-4ba5-a4f7-344f7f2e706c
md"""
### Algoritmo de cómputo

**Paso 1.** De los $i$ percentiles en la distribución *glp*, se deben encontrar los dos que rodean la variación intermensual cero.
		
**Paso 2.** En la función de densidad $f_{t}$ del período $t$, se deben encontrar también los percentiles que rodean a la variación intermensual cero.$q_{f_{t}, \underline{s}}^{(i)}$ y $q_{f_{t}, \overline{s}}^{(i)}$. 
		 
**Paso 3.** Encontramos los números de percentiles comunes: $\overline{r}$ y $\underline{r}$.
	
**Paso 4.** Definimos el conjunto de segmentos $I-R$ sobre los cuales normalizar.

"""

# ╔═╡ 957b95ff-6a71-4fc0-84c7-ef26a25cf51f
md"""
**Paso 5.** Renormalizar todos los segmentos indicados por el conjunto $I-R$.
	
- Para todos los segmentos $k \in I-R$ (excepto para $k = 0$ o $k = \overline{r}$) la función de densidad $flp_{t}$ en el segmento $k$ estaría dada por:

$$flp_{t}(v) =   glp\left(v\right) \, \frac{GLP\left(q_{flp, k}^{\left(i\right)}\right) - GLP\left(q_{flp, k-1}^{\left(i\right)}\right)}{GLP\left(q_{f_{t}, k}^{\left(i\right)}\right) - GLP\left(q_{f_{t}, k-1}^{\left(i\right)}\right)}, \quad q_{f_{t}, k-1}^{\left(i\right)} < v \leq q_{f_{t}, k}^{\left(i\right)}.$$
- En el segmento especial, en el cual $k = \overline{r}$, la normalización se hace sobre todo el segmento indicado por los percentiles $\underline{r}$ y $\overline{r}$, esto es:

$$flp_{t}(v) =   glp\left(v\right) \, \frac{GLP\left(q_{flp, \overline{r}}^{\left(i\right)}\right) - GLP\left(q_{flp, \underline{r}}^{\left(i\right)}\right)}{GLP\left(q_{f_{t}, \overline{r}}^{\left(i\right)}\right) - GLP\left(q_{f_{t}, \underline{r}}^{\left(i\right)}\right)}, \quad q_{f_{t}, \underline{r}}^{\left(i\right)} < v \leq q_{f_{t}, \overline{r}}^{\left(i\right)}.$$
"""

# ╔═╡ eece39ce-8282-4c3b-a5e8-882b2fd111e4
md"""
Notar que si $k=0$ o $k=i$, los límites del intervalo de normalización deben modificarse apropiadamente: 
- Si $k=0$: 
$$q_{g,0}^{(i)} \triangleq \min(q_{g,0}^{(i)}, q_{glp,0}^{(i)})$$

- Si $k=i$: 
$$q_{g,i}^{(i)} \triangleq \max(q_{g,k}^{(i)}, q_{glp,k}^{(i)})$$
"""

# ╔═╡ 3e47548d-2cf9-4840-ba22-0e0c168f7851
md"""
En este caso, normalizar utilizando los percentiles de la distribución de ocurrencias $f_t$ y la función de densidad *glp*, permite que la densidad acumulada en la distribución normalizada $flp_{t}$ en el segmento $k$ sea la acumulada por la densidad acumulada $GLP$ en el segmento indicado por los percentiles de la función de densidad de ocurrencias de largo plazo, esto es:

$$FLP_t(q_{f_{t}, k}^{(i)}) - FLP_t(q_{f_{t}, k-1}^{(i)}) = GLP(q_{flp, k}^{(i)}) - GLP(q_{flp, k-1}^{(i)})$$
"""

# ╔═╡ c6b1a8ce-451d-4b55-9e3f-7e981620538b
md"""
### Ejemplo de renormalización 
"""

# ╔═╡ f2a71207-971e-49a8-b753-42df3c8b1ad6
begin
	flpₜ = renorm_f_flp(Ft, FLP, GLP, glp, n)
	
	FLPt = cumsum(flpₜ) 
	plot(Ft, label="Ft")
	plot!(FLP, label="FLP")
	plot!(FLPt, label="FLPt", xlims=(-5,5))
end

# ╔═╡ 550e5092-dc74-457b-9b24-8d514d1aa59f
mean(flpₜ)

# ╔═╡ f6ab278a-a298-46fd-9593-74021119ef18
md"""
## Función de inflación de la HEMI

Se introduce a continuación la función de inflación (`InflationFunction`) desarrollada en la HEMI.

Construimos una función de inflación para computar con metodología de renormalización F y **cuartiles** de la distribución de variaciones intermensuales => MAI (F, 4)
"""

# ╔═╡ 23f0267f-9d06-4cc8-a993-850f4c6392b7
inflfn = InflationCoreMai(MaiF(4))

# ╔═╡ 78db08b1-09c8-46c0-8c15-20121b944a25
InflationCoreMaiF(4)

# ╔═╡ f2522946-2628-4ea3-82e2-8b32ed9caab9
md"""
Para computar la trayectoria de inflación, aplicamos directamente sobre `CountryStructure`
"""

# ╔═╡ d3362097-7398-4f93-aa3e-36a20a7e96ef
tray_infl = inflfn(gtdata)

# ╔═╡ f1a142c8-55f1-4ed9-af01-bd79be1d9482
md"""
Para graficar las trayectorias, podemos utilizar esta receta: 
"""

# ╔═╡ 17a9a9a6-1afd-4eaa-a4a7-dbc73045ff89
# plot(inflfn, gtdata, legend=:topright)

# ╔═╡ 206ab3a9-d9d9-4815-9eaf-91e3fa32843a
md"""
Veamos las variantes de inflación subyacente MAI por método y número de segmentos: 
"""

# ╔═╡ 1adce1ea-8ef0-4509-ad05-d93b1ece4d47
begin
	methods = vcat(
		[MaiF(i) for i in (4, 5, 10, 20, 40)], 
		[MaiG(i) for i in (4, 5, 10, 20, 40)])
	
	inflfns = InflationCoreMai.(methods)
	
	plt1 = plot()
	for fn in inflfns
		plot!(plt1, fn, gtdata, legend=:topright)
	end
	plt1
end

# ╔═╡ 2b7406a1-92ba-4c80-8764-5a0be165149a
cpidata = GTDATA[Date(2020,12)]

# ╔═╡ 0d33c681-4ef6-43be-8e70-64e6300235a1
begin
	plot(InflationTotalCPI(), cpidata, label="Headline CPI inflation")
	plot!(inflfn, cpidata, label="HES-F core inflation")
	savefig("hesf_example.pdf")
end


# ╔═╡ 2f27877d-8ff8-4d7e-b50f-d33ddbaba7dc
pwd()

# ╔═╡ b860dc45-8921-4183-85c6-44599892cbe0
md"""
## Optimización de la combinación lineal de trayectorias con la HEMI 

$$\begin{aligned}
  \text{MAI}_{t} = \, & a_{f,4}\text{MAI}_{f,4,t} + a_{f,5}\text{MAI}_{f,5,t} + a_{f,10}\text{MAI}_{f,10,t} + a_{f,20}\text{MAI}_{f,20,t} + a_{f,40}\text{MAI}_{f,40,t} \\
  ~ & \; + a_{g,4}\text{MAI}_{f,4,t} + a_{g,5}\text{MAI}_{f,5,t} + a_{g,10}\text{MAI}_{f,10,t} + a_{g,20}\text{MAI}_{f,20,t} + a_{g,40}\text{MAI}_{f,40,t}
\end{aligned}$$

Con la trayectoria combinada $\text{MAI}_{t}$, se plantea un problema de optimización libre con respecto al $\overline{\text{MSE}}$ promedio obtenido del proceso de evaluación con criterios básicos. Para la combinación anterior, se puede notar que, dadas las realizaciones de las trayectorias, el estadístico de error cuadrático medio es función de los ponderadores de la combinación lineal:

$$\overline{\text{MSE}}(\mathbf{a}) = \frac{1}{T\,K}\sum_{k=1}^{K}\sum_{t=1}^{T} \left( \text{MAI}_{t}^{(k)}(\mathbf{a}) - \pi_t \right)^2$$ 

en donde: 
- el vector $\mathbf{a}$ representa las ponderaciones para cada una de las variantes de las medidas MAI. En particular, se utiliza el siguiente ordenamiento para los ponderadores: 

$$\mathbf{a} = \left[ a_{f,4}, a_{g,4}, a_{f,5}, a_{g,5}, a_{f,10}, a_{g,10}, a_{f,20}, a_{g,20}, a_{f,40}, a_{g,40}\right]^T$$

- El índice $k$ representa el número de realización en el ejercicio de simulación, respecto de un total de $K$ realizaciones.

- Y $\pi_t$ representa la trayectoria de inflación paramétrica en el período $t$. El total de períodos está dado por $T$.

La función que representa el valor esperado del error cuadrático medio $\overline{\text{MSE}}(\mathbf{a})$, es estrictamente convexa en los ponderadores $a_{f,i}$ y $a_{g,i}$, y por lo tanto, se deriva analíticamente una solución global, dada por la solución al sistema de ecuaciones obtenido a través de las condiciones de primer orden: 

$$\left[\begin{matrix}
\overline{\text{MAI}_{f,4}^{2}} & \overline{\text{MAI}_{f,4}\,\text{MAI}_{g,4}} & \ldots & \overline{\text{MAI}_{f,4}\,\text{MAI}_{g,40}} \\
\overline{\text{MAI}_{f,4}\,\text{MAI}_{g,4}} & \overline{\text{MAI}_{g,4}^{2}} & \ldots & \overline{\text{MAI}_{g,4}\,\text{MAI}_{g,40}} \\
\vdots & \vdots & \ddots  & \vdots \\
\overline{\text{MAI}_{f,4}\,\text{MAI}_{g,40}} & \overline{\text{MAI}_{g,4}\,\text{MAI}_{g,40}} & \ldots & \overline{\text{MAI}_{g,40}^{2}}
\end{matrix}\right] 
\left[\begin{matrix} 
a_{f,4} \\ 
a_{g,4} \\
\vdots \\
a_{f,40} \\
a_{g,40} \\
\end{matrix}\right] = 
\left[\begin{matrix} 
\overline{\pi\,\text{MAI}_{f,4}} \\ 
\overline{\pi\,\text{MAI}_{g,4}} \\ 
\vdots \\ 
\overline{\pi\,\text{MAI}_{f,40}} \\ 
\overline{\pi\,\text{MAI}_{g,40}} \\ 
\end{matrix}\right]$$

en donde, por ejemplo, $\overline{\text{MAI}_{f,4}\,\text{MAI}_{g,4}}$ representa el promedio a través del tiempo y realizaciones del producto de las trayectorias de inflación subyacente MAI con cuartiles que utilizan la distribución de ocurrencias y con la distribución ponderada de ocurrencias, es decir: 

$$\overline{\text{MAI}_{f,4}\,\text{MAI}_{g,4}} = \frac{1}{T\,K}\sum_{k=1}^{K}\sum_{t=1}^{T} \text{MAI}_{f,4,t}^{(k)}\,\text{MAI}_{g,4,t}^{(k)}$$
"""

# ╔═╡ c51b6e67-06ec-4e54-930c-5abc956bf237
md"""
## Discusión 

- Ventajas y desventajas del procedimiento expuesto.
		
- ¿Qué efecto podría tener computar la inflación subyacente MAI solamente con la base 2010 del IPC?
		
- Para llevar a cabo el cómputo, ¿sería posible utilizar percentiles no igualmente espaciados entre sí?
"""

# ╔═╡ dcee00f6-c94a-4e9f-ba27-b61e09097bea
md"""
#### Funciones y utilidades

Se configuran opciones para mostrar este cuaderno. 
"""

# ╔═╡ Cell order:
# ╟─ec957b42-5a6f-46be-986d-e7b99cfda80d
# ╠═0f5e97c1-2125-4766-99fc-fda1f71bb391
# ╟─4b605b91-44df-49cf-8c0c-8566e30cc598
# ╟─928289db-c42e-4a55-bb04-bac4b33ae379
# ╟─137b9a66-66fb-467a-a3af-20572f5286c2
# ╟─1d59e61c-4cdf-43c6-970f-868beaeffe9b
# ╟─0d1bf735-062f-44d7-bd70-2c25f16e8f59
# ╟─96e18948-5150-4193-bc93-b78daf87f067
# ╟─535f144b-02fa-47b2-9990-9b8c033c42cb
# ╟─793cabab-c5d4-4ad3-bf22-fb1bef99aad1
# ╠═3d5c920b-964d-4755-8867-96bddbe5d83d
# ╟─e1387332-9b1e-4358-8fac-1de63a7f1e92
# ╟─e083e30b-b6c9-4655-90f6-a7ac5f71704b
# ╠═605481ae-77ee-4628-a19c-324307ae5eac
# ╠═da808075-4dec-4426-947e-0e1292947288
# ╟─3ceec3c2-3bac-4276-8bb7-072c433fe61a
# ╠═ebd08f30-0617-4ff7-b07c-da446bb2745d
# ╠═ab127c7b-e1d4-4b92-aad7-6790bbfabb99
# ╠═7c894360-bae4-4827-b26b-536d05f15338
# ╟─ead7a6c4-c632-41e2-beb4-8ee1303fca74
# ╠═6f57de61-45b4-49e4-b189-d825a887604a
# ╟─a6ad31b4-5d49-4a78-8508-4628fd52b95d
# ╟─2bef3af2-964f-4731-ba6f-9b397f3a1c88
# ╠═f7326714-1ac5-4a04-aa76-1e01679226bc
# ╠═2cc3a548-0bd4-44b0-b963-cbd8782cbbd5
# ╠═ddbbc8dc-9f45-4561-bbe4-026afffdfa19
# ╠═8db73f78-82de-4b60-bdda-a526e8df1bef
# ╟─b2708891-0e2e-47ca-bd7f-6458346b6d8b
# ╠═30dfac77-2379-4cdf-b2f2-ff295fca0bfa
# ╟─b1d815b1-36f9-4bdb-96f5-0ddfbb0e0549
# ╠═4c1d468f-66cb-4d85-bcf0-2c08d4710acb
# ╟─11c25418-b567-4c9f-ada2-c0da447c8fb5
# ╟─5ecd2dfc-8630-45c1-b10c-fd447c108a06
# ╠═84804321-007b-45b6-a639-7e014a8eb94f
# ╠═b45d7991-7384-4af9-81c8-de6ac76b84c6
# ╟─8b493fe6-a3c8-4c4d-9cf0-8ed09eb51a14
# ╠═64b18be0-89b3-4dcc-9851-417e3dd52b85
# ╟─4dfb444e-fb89-4d0b-bf08-fd848fed318c
# ╟─5dbf0091-a34e-4c9d-859e-3a440193cf2b
# ╟─3a3077b2-9f5b-45b2-a95f-9af623e55c81
# ╟─d7dd2148-de33-45f8-b765-08ff5197678e
# ╠═187e4642-2e95-4eb8-bc19-7620bf002b2c
# ╠═b0a34f54-7369-47d5-b1be-3bcd06b2799a
# ╠═de137105-52b0-4b45-8a2b-81754757871a
# ╠═f86e12d5-64a2-4276-b1e9-2e14233a7e21
# ╟─e6a87aec-ce7a-4a52-90ac-a86e69a23efa
# ╟─2221671b-7a6e-4dba-b7dc-80e271a5ed28
# ╟─99f469f5-5152-4799-a9d2-9ed77e4c57c0
# ╠═8908cb22-7e0a-4a0d-86c2-af02470eab40
# ╠═dcdf8bae-c30c-4a4c-a9bb-155258da9225
# ╠═416e4983-035f-4185-b28c-d28be1b10cae
# ╠═0b6f340f-5007-4351-bcd8-4f280880cf16
# ╟─b1974f1f-f6e1-41f3-8e79-66bc1662de6a
# ╠═3e46fc96-7114-431b-aed1-20f1f1252780
# ╠═3524c263-3adb-418a-8be8-30b378445b08
# ╟─748134bc-3856-44f3-9a85-f4e126ff8c0d
# ╠═2b2638c1-a7a5-49ea-a612-979474d7d7b4
# ╠═2975fb0e-2a6f-4867-b3b0-eb69d3128a2e
# ╟─4a93d0d0-7b13-4220-b076-32a157606c40
# ╟─2e2ecd5a-bfda-4b37-b26e-12293831740e
# ╠═a2fca38f-8519-4956-872e-8d744ebf4d92
# ╠═640e9426-996a-4fac-8de4-36daacd0f5ac
# ╠═2e28138e-b50d-4345-9e7d-ab9a5804e073
# ╟─7652d811-ca5e-43ff-ae0b-ede97c7c6986
# ╠═7c5c8db1-7c27-4bd0-ac57-5613e0ac829f
# ╠═da0dee29-0cd7-420f-a20a-768945529fa7
# ╟─948d7192-facb-4e3f-80ed-fb62ab1bbc3b
# ╠═ad923e3b-92ff-4670-9dd5-25022e54df85
# ╠═341c042d-e622-41e4-93be-62472a27efb8
# ╟─342e77e1-a763-48f8-9f83-2e4396db6656
# ╠═f71f0d24-8236-4a12-80d1-738e53ea0e12
# ╠═6c5bd5de-cb87-4a60-b407-fddf2c1cf931
# ╠═d0f22c65-f172-4e83-ad79-c75d6c46d571
# ╠═eae96716-47ae-410e-adbc-bc863b9832c9
# ╟─e81a2a75-373c-41b5-8a4c-57608c4b12f9
# ╠═d591df05-1ac3-4081-9261-ef9ffb7c66d3
# ╟─7a3b0421-5d0a-47e3-8de8-0557979f3975
# ╠═e33f1222-8f29-4591-9db9-dee8938a306f
# ╠═2d0aa4be-31d6-4712-b169-2ef25fa4afc2
# ╟─8251b8fb-f975-45bf-bf74-7a1f037c6c13
# ╠═7f79d6a1-9e3a-4b8e-8478-bf1bc9257241
# ╠═8bb62d79-96f2-4e54-b834-4cef0256c8f4
# ╠═bf70158e-81db-49e5-96d5-ccd5ecaa381c
# ╟─37d28a04-b2dc-4402-9bec-56ecc27b5550
# ╠═87b845e0-e778-4ac3-ac4f-f9e2252ea20c
# ╠═f7e63c15-11aa-4aa7-946f-d489c700df7f
# ╠═a3bac26b-10a5-451a-82c2-2b730aef9346
# ╟─1631b796-78e7-400e-9575-6494a63a7873
# ╠═9170753e-b5a3-4ee2-8e0d-b343c316a74c
# ╟─670c5227-49ed-479f-9fa4-0ad97f87a05c
# ╠═4a7870fb-9be4-4f72-a54e-1d144f5794b2
# ╠═490d77ff-3c79-4cfd-85c9-9d7688be9291
# ╟─90c5a65b-d3a6-4d60-9953-81e718524548
# ╠═3b73f01d-ef58-4a45-8eac-1c1b8ad4c4bb
# ╠═2c457b05-c6ac-40df-b3aa-b9ba0f6f4171
# ╠═df737c62-2754-46e0-818e-2b365c6c906b
# ╟─4bccbf09-7a05-444d-aa60-7ff3766748e8
# ╟─7c755659-4209-4714-936e-28a6d8965669
# ╟─5ee20275-eecf-4738-a018-f96024bf6ba6
# ╟─8be9921e-4535-4cf8-b6f3-5939dbd37598
# ╟─272d4be4-33af-44df-a313-befb89cb4515
# ╠═e0047781-6cb3-4cee-a894-78acc5f33fb5
# ╠═88acf18f-7709-4ba0-b6bf-da77f032dedd
# ╠═566dc8c2-7010-49a2-b9f6-958bc55e8778
# ╠═99dd9a8f-2266-4ab9-94d9-61043811fabd
# ╟─39f116e8-e5c1-439b-9cf9-f15a50d15cb6
# ╠═2f18642b-a8e8-47de-a549-428953baf704
# ╠═da1a532c-58c9-42fc-b112-a4baa23848e6
# ╟─c215620e-a5ea-47bd-b49b-8d8d89ed659c
# ╟─8446f083-253a-4e1e-9ad4-58932d4ca102
# ╟─62076d20-0fa4-42ed-97cb-a4b693074786
# ╟─c9270e0a-9248-4e36-bafa-af51dda1a166
# ╟─da9539eb-ecf3-415b-8add-8bcb6414561d
# ╟─d6d13501-4b14-40e4-bcb3-1c16843eef20
# ╟─4e9d615c-f16d-42d7-a798-b95156a28559
# ╟─41a183d6-5db7-4854-9bd6-c388f033e2f7
# ╟─ce5d1861-c998-4b85-8fec-ee7c9132fbf4
# ╟─84902e13-3c42-4d69-af7d-8531d6352991
# ╠═a01d5d57-e7c4-4d03-bf77-16bd0ae12dc6
# ╠═289ec238-0633-4f1d-bc98-3494265a9570
# ╟─2b78811f-d59e-4ac3-9dee-a0c07cb44731
# ╠═e615d881-4a52-4943-8138-17b399ef35f1
# ╠═cd48716e-4892-436c-a38e-ac487597c652
# ╟─afdbff35-7d0d-4d48-bcb5-66e422352d2c
# ╠═fc22f2da-59c6-440f-aa2a-059f27f9e470
# ╟─2d7fc594-f3ca-4fc4-8b20-efd5d5925ff9
# ╟─b2744061-113e-4348-b7bb-efcc0bb01de8
# ╠═8226ffbb-802e-4577-9ecd-57875dd395bd
# ╟─0fdf271c-b7ad-482f-affc-0845049c4f8f
# ╟─b95b2374-9cd1-4583-bbfb-b02ec7e251e9
# ╟─e870fbb6-a0e4-4374-bfd3-0da630cbc596
# ╠═9dc6d27b-5571-4023-b05b-50e43f90e585
# ╠═cc17dfa5-8302-49b2-ae4f-26f84e05ded3
# ╠═96586a48-e779-4ba0-91d7-35f3aeb67666
# ╠═4f37b238-3aa2-4e00-9faf-b26d61917d3e
# ╟─f47dd797-8d70-436f-8075-8b133f5137c8
# ╠═2efdd051-3847-4fae-a24b-7a8d87cbbd97
# ╠═3e9ef9dd-7b52-4429-a8f0-12f77b91d341
# ╠═1c432a8a-e83c-430e-a1ea-cda63206df44
# ╠═19a4b029-6abe-45c8-99bb-48dad7893934
# ╟─80482a7e-eaa1-499f-b14d-266be0b8867a
# ╟─7424f3cd-94fc-46ba-a3b1-8fe74c5f5935
# ╠═585c4ec5-b880-4e9f-be45-b9c86d891d78
# ╠═5c766faa-65bb-486c-969b-2ef909e14686
# ╠═081602ca-82cc-4072-a34a-0fd326d2d37a
# ╠═9456a534-d6b4-4a8d-8d52-d5fa64c41c15
# ╠═6c5c71da-c68b-4bad-8146-2aa17ba13432
# ╟─4d336858-d661-46f5-8927-c9901d2eef3f
# ╠═662a3104-9f4f-4547-acc9-2c1782da499e
# ╟─ce56fd18-c13c-41fe-8354-4966f30b3c7f
# ╠═efe07e03-c5eb-4d22-be91-badd67fe8b33
# ╟─0edcdd2e-8b00-4c15-8076-8be69e83d1d4
# ╟─f6b5ce08-4bb1-42ab-9272-42790b33704e
# ╟─4ebb2e7e-95c9-4ba5-a4f7-344f7f2e706c
# ╟─957b95ff-6a71-4fc0-84c7-ef26a25cf51f
# ╟─eece39ce-8282-4c3b-a5e8-882b2fd111e4
# ╟─3e47548d-2cf9-4840-ba22-0e0c168f7851
# ╟─c6b1a8ce-451d-4b55-9e3f-7e981620538b
# ╠═f2a71207-971e-49a8-b753-42df3c8b1ad6
# ╠═550e5092-dc74-457b-9b24-8d514d1aa59f
# ╟─f6ab278a-a298-46fd-9593-74021119ef18
# ╠═23f0267f-9d06-4cc8-a993-850f4c6392b7
# ╠═78db08b1-09c8-46c0-8c15-20121b944a25
# ╟─f2522946-2628-4ea3-82e2-8b32ed9caab9
# ╠═d3362097-7398-4f93-aa3e-36a20a7e96ef
# ╟─f1a142c8-55f1-4ed9-af01-bd79be1d9482
# ╠═17a9a9a6-1afd-4eaa-a4a7-dbc73045ff89
# ╟─206ab3a9-d9d9-4815-9eaf-91e3fa32843a
# ╟─1adce1ea-8ef0-4509-ad05-d93b1ece4d47
# ╠═2b7406a1-92ba-4c80-8764-5a0be165149a
# ╠═0d33c681-4ef6-43be-8e70-64e6300235a1
# ╠═2f27877d-8ff8-4d7e-b50f-d33ddbaba7dc
# ╟─b860dc45-8921-4183-85c6-44599892cbe0
# ╟─c51b6e67-06ec-4e54-930c-5abc956bf237
# ╟─dcee00f6-c94a-4e9f-ba27-b61e09097bea
# ╠═d722fbf0-eb4f-11eb-2fef-b19a7566ba31
