### A Pluto.jl notebook ###
# v0.15.1

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : missing
        el
    end
end

# ╔═╡ 3b23d3a0-15cf-11ec-2c2f-9547a14aff74
begin 
	import Pkg
	Pkg.activate("..")
	
	using PlutoUI
	using Revise
	using DrWatson, HEMI, Plots
	
	using InflationFunctions: ObservationsDistr, WeightsDistr, AccumulatedDistr
	using InflationFunctions: _get_vstar, _get_wstar
	using InflationFunctions: V
end

# ╔═╡ 0f48a6bf-e5c8-462f-b7f6-9a81aca6f6a5
md"""
# Remuestreo y distribución de largo plazo
"""

# ╔═╡ cfc3ff77-b2a0-41da-bff4-e3c9637cc070
resamplefn = ResampleSBB(36)
# resamplefn = ResampleScrambleVarMonths()

# ╔═╡ df7a60f1-1e1c-4d1a-b862-8adf633db005
# Calibrada con ResampleSBB(36)
# inflfn = InflationCoreMai(MaiF([0, 0.2917, 0.7782, 0.9817, 1]))

# Calibradas con ScrambleVarMonths
inflfn = InflationCoreMai(MaiFP([0, 0.27, 0.72, 0.77, 1]))
# inflfn = InflationCoreMai(MaiF([0, 0.22, 0.64, 0.86, 1]))
# inflfn = InflationCoreMai(MaiG([0, 0.06, 0.27, 0.36, 0.67, 0.67, 0.68, 0.7194, 0.7247, 0.73, 1]))

# ╔═╡ dfeabb05-b09a-4f7f-bbdd-faf656d240ba
trendfn = TrendRandomWalk()

# ╔═╡ c65ebbb9-bc2a-4df2-9a64-67cadd7b2341
@bind YEAR Slider(2001:2020, show_value=true)

# ╔═╡ d9feae29-ba59-4092-87ea-cb79f7a2a139
evaldata = gtdata[Date(YEAR, 12)]

# ╔═╡ 662eb1ca-0430-4544-9d3c-ccf0224ba88a
@bind go Button("Remuestrear!")

# ╔═╡ 8f5bc18c-78fa-4d79-bba9-d1a8eaf36c99
begin
	go
	bootsample = evaldata |> resamplefn |> trendfn
end

# ╔═╡ 0c2acac7-3810-4fdd-b8e1-81df33210cdf
begin
	plot(InflationTotalCPI(), bootsample)
	plot!(inflfn, bootsample)
end

# ╔═╡ e13fdb43-6bdc-447f-aa44-2c98285dcfbc
function distrlp(cs)
	vstar = _get_vstar(cs) 
	wstar = _get_wstar(cs) 
	flp = ObservationsDistr(vstar, V)
	glp = WeightsDistr(vstar, wstar, V)
	flp, glp
end

# ╔═╡ db89b4c9-bc4b-4614-9437-621911f5fb1a
# Estructura original
begin
	flp_obs, glp_obs = distrlp(evaldata)
	FLP_obs = cumsum(flp_obs) 
	GLP_obs = cumsum(glp_obs)
end;

# ╔═╡ 70f884a2-4f00-487f-9c82-5db58db082bc
# Estructura remuestreada
begin
	flp_boot, glp_boot = distrlp(bootsample)
	FLP_boot = cumsum(flp_boot) 
	GLP_boot = cumsum(glp_boot)
end;

# ╔═╡ 916a8ee1-40f1-49ea-9953-5675629adfc0
begin
	plot(flp_obs, 
		xlims=(-2.5,2.5), ylims=(0,0.15), 
		label="flp",
		alpha=0.7, linewidth=2)
	plot!(flp_boot, 
		xlims=(-2.5,2.5), ylims=(0,0.15), 
		label="flp remuestreada", 
		color=:red, alpha=1)
end

# ╔═╡ Cell order:
# ╟─0f48a6bf-e5c8-462f-b7f6-9a81aca6f6a5
# ╠═3b23d3a0-15cf-11ec-2c2f-9547a14aff74
# ╠═d9feae29-ba59-4092-87ea-cb79f7a2a139
# ╠═cfc3ff77-b2a0-41da-bff4-e3c9637cc070
# ╠═df7a60f1-1e1c-4d1a-b862-8adf633db005
# ╠═dfeabb05-b09a-4f7f-bbdd-faf656d240ba
# ╟─8f5bc18c-78fa-4d79-bba9-d1a8eaf36c99
# ╟─c65ebbb9-bc2a-4df2-9a64-67cadd7b2341
# ╟─662eb1ca-0430-4544-9d3c-ccf0224ba88a
# ╟─0c2acac7-3810-4fdd-b8e1-81df33210cdf
# ╟─916a8ee1-40f1-49ea-9953-5675629adfc0
# ╠═e13fdb43-6bdc-447f-aa44-2c98285dcfbc
# ╠═db89b4c9-bc4b-4614-9437-621911f5fb1a
# ╠═70f884a2-4f00-487f-9c82-5db58db082bc
