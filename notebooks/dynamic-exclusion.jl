### A Pluto.jl notebook ###
# v0.15.1

using Markdown
using InteractiveUtils

# ╔═╡ 7590901e-bf3a-4d1b-8f87-307b71080703
begin
	using Pkg
	Pkg.activate("..")
end

# ╔═╡ b1224d3f-05ee-4a0d-9b07-7d100dfb3206
using DrWatson, Chain, DataFrames, Plots, HEMI, CSV, JLD2, RecipesBase

# ╔═╡ a1d0652f-b559-49eb-b985-e5430f48a787
begin
	@chain "..\\scripts\\load_data.jl" include
	@chain "..\\src\\HEMI.jl" include
end;

# ╔═╡ b3b95d20-f07d-11eb-0245-af4e7073107c
md"""
# Avances de evaluación: medida de exclusión dinámica
**Julio 2021**
"""

# ╔═╡ f96f801e-597c-403e-aa32-8f4c47b16925
md"""
## Condición de inclusión

$\bar{v}_t - (\lambda_{inf} * \sigma_t) \leq v_{x,t} \leq \bar{v}_t + (\lambda_{sup} * \sigma_t)$

Entre más grandes sean $\lambda_{inf}$ y $\lambda_{sup}$, menos gastos básicos son excluídos.
"""

# ╔═╡ 1af1cdf6-81ad-4e9a-aa61-564723bfd596
md"""
## Resumen
"""

# ╔═╡ 2cf7dcbf-6496-4850-a850-46c7914828bb
md"""
## Trayectorias observadas
"""

# ╔═╡ dda94698-e621-4a42-9ae7-f1b5efc64e6b
md"""
**Celdas para funcionaminto del cuaderno...**
"""

# ╔═╡ 6336b1e4-7c83-4736-917d-7d9a0e8d38ab
datapath = datadir("results", "dynamic-exclusion");

# ╔═╡ 21115aa4-feae-42c9-bb8f-90f3fdbbab4f
@recipe function plot(inflfn::InflationFunction, data::CountryStructure)
    
    # Computar trayectoria de inflación 
    traj_infl = inflfn(data)

    label --> measure_name(inflfn)
    legend --> :topright

    infl_dates(data), traj_infl
end

# ╔═╡ 69e1e654-1237-4812-becf-adb3d678e32a
df = DataFrame(CSV.File(datadir(datapath, "resultados_parse_2021-07-27.csv")));

# ╔═╡ 38346042-efaa-4deb-8cd6-f147ef9854d4
# Frame con datos de mínimo de grilla
df_min = df[minimum(df.mse) .== df.mse, :];

# ╔═╡ a7e9afec-1ee2-4b7a-a457-4069d2f2dbb7
md"""
## Grilla exploratoria

* La grilla exploratoria está conformada por 9903 puntos, variando los factores desde 0 hasta 3. 

* Los criterios utilizados para la evaluación fueron
	* 10,000 simulaciones.
	* Remuestreo por bloque estacionario de tamaño 36.
	* Tendencia de caminata aleatoria.
	* Periodo hasta diciembre de 2020.
	* Parámetro de inflación con cambio de base.
* El menor MSE encontrado fue $(df_min.mse[1]), el cual corresponde a los factores ( $(df_min.factor_inf[1]), $(df_min.factor_sup[1])).
"""

# ╔═╡ 58809d47-bfa7-4908-a063-087c950ec238
begin
	gr()
	plot(
		# Aes
		df.factor_inf,
		df.factor_sup,
		marker_z = 1 ./ df.mse,
		# Geom
		seriestype = :scatter,
		# Series Attributes
			label = "",
			# Marks
			markersize = 5,
			markerstrokewidth = 0,
			markershape = :rect,
			markeralpha = 0.9,
		# Subplots Attributes
			plot_title="Main title",
			title = "Inverso del MSE de evaluación\n10,000 simulaciones",
			titlefontsize = 12,
			annotations = (
				df_min.factor_inf .+ 0.6, 
				df_min.factor_sup, 
				"MSE mínimo = $(df_min.mse[1])"
			),
			annotationfontsize = 8,
			annotationcolor = RGB(0,0,0),
		xlabel = "Factor inferior",
		ylabel = "Factor superior"
	)
	plot!(df_min.factor_inf, df_min.factor_sup, markercolor = RGB(0,0,0), seriestype = :scatter, label = "")
	
end

# ╔═╡ 9578b661-6bde-4774-a396-913f6f2af28a
begin
	optim_result = JLD2.load(datadir(datapath, "optimization", "optres_dynEx.jld2"));
	optim_result = optim_result["optres"];
end;

# ╔═╡ f693de28-471d-440d-9c1e-4c846d6d7a27
md"""
## Ejercicios de optimización

* Algoritmo interativo (Nelder-Mead).

* Los criterios utilizados para la evaluación fueron
	* 125,000 simulaciones.
	* Remuestreo por bloque estacionario de tamaño 36.
	* Tendencia de caminata aleatoria.
	* Periodo hasta diciembre de 2020.
	* Parámetro de inflación con cambio de base.
* El menor MSE encontrado es $(convert(Float64, optim_result.minimum)), el cual corresponde a los factores ( $(convert(Float64, optim_result.minimizer[1])), $(convert(Float64, optim_result.minimizer[2]))).
"""

# ╔═╡ f3add5e9-14ab-409e-b4f0-93133b468cb2
begin
	infFn_df = DataFrame()
	infFn_df.description = [
		"Inflación total",
		"Óptima GSBB CPIRebase 2020 Julia",
		"Óptima SVM Legacy 2019 MATLAB",
		"Óptima SVM CPIRebase 2020 Julia",
		"Óptima SVM Legacy 2019 Julia"
	]
	
	infFn_df.factor_inf = [NaN, optim_result.minimizer[1], 0.3222, 0.28, 0.27]
	infFn_df.factor_sup = [NaN, optim_result.minimizer[2], 1.7283, 2.37, 1.93]
	
	fun_dict = Dict{Any, Any}()
	fun_dict[1] = [infFn_df.description[1], InflationTotalCPI()]
	for i in 2:size(infFn_df)[1]
		fun_dict[i] = [
			infFn_df.description[i],
			InflationDynamicExclusion(
				infFn_df.factor_inf[i],
				infFn_df.factor_sup[i]
			)
		]
	end
	fun_dict
end

# ╔═╡ 3b0f419f-bd16-4aec-ac34-9baf557c67cf
begin
	infFn_df."MSE en Julia" = [
		NaN,
		convert(Float64, optim_result.minimum),
		0.88526, 
		0.5729,
		0.8852
	]
	infFn_df."MSE en MATLAB" = [
		NaN,
		NaN,
		0.29, 
		NaN,
		NaN
	]
	infFn_df
end

# ╔═╡ 2e46e241-f279-43e9-8c8c-d5f8dea03ff3
begin
	plotlyjs()
	p = plot(fun_dict[1][2], gtdata)
	for i in 2:size(infFn_df)[1]
		p = p; plot!(fun_dict[i][2], gtdata, label = fun_dict[i][1])
	end
	p
end

# ╔═╡ Cell order:
# ╟─b3b95d20-f07d-11eb-0245-af4e7073107c
# ╟─f96f801e-597c-403e-aa32-8f4c47b16925
# ╟─a7e9afec-1ee2-4b7a-a457-4069d2f2dbb7
# ╟─58809d47-bfa7-4908-a063-087c950ec238
# ╟─f693de28-471d-440d-9c1e-4c846d6d7a27
# ╟─1af1cdf6-81ad-4e9a-aa61-564723bfd596
# ╟─3b0f419f-bd16-4aec-ac34-9baf557c67cf
# ╟─2cf7dcbf-6496-4850-a850-46c7914828bb
# ╠═2e46e241-f279-43e9-8c8c-d5f8dea03ff3
# ╟─dda94698-e621-4a42-9ae7-f1b5efc64e6b
# ╠═6336b1e4-7c83-4736-917d-7d9a0e8d38ab
# ╠═b1224d3f-05ee-4a0d-9b07-7d100dfb3206
# ╠═21115aa4-feae-42c9-bb8f-90f3fdbbab4f
# ╠═38346042-efaa-4deb-8cd6-f147ef9854d4
# ╠═7590901e-bf3a-4d1b-8f87-307b71080703
# ╠═69e1e654-1237-4812-becf-adb3d678e32a
# ╠═9578b661-6bde-4774-a396-913f6f2af28a
# ╠═a1d0652f-b559-49eb-b985-e5430f48a787
# ╠═f3add5e9-14ab-409e-b4f0-93133b468cb2
