### A Pluto.jl notebook ###
# v0.17.7

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

# ╔═╡ 97cd2a90-a47f-11ec-1a1f-63e464a95fa7
begin
	import Pkg
	Pkg.activate("..")
	Pkg.status()
	using DrWatson
	using DataFrames
	using HEMI
	using Plots
	using PlutoUI

	# Load optimal mse combination measures
	include(scriptsdir("mse-combination-2019", "optmse2019.jl"))
	include(scriptsdir("mse-combination", "optmse2022.jl"))
end

# ╔═╡ baf02c1f-5b89-4d7a-8da3-c0ee74e2399a
begin
	# Change between :b00, :b10 and :b0010
	PERIOD = :b0010
	USE_OPTIMALS = true
	const PARAM_INFLFN = InflationTotalCPI() 
end

# ╔═╡ f6d981a9-2d09-4dd7-875f-a791543520e4
begin
	# Calibration data used 
	period1 = EvalPeriod(Date(2001,1), Date(2005,12), "b00_5y")
	period2 = EvalPeriod(Date(2011,12), Date(2015,12), "b10_5y")
	
	if PERIOD == :b00 
	    evaldata = UniformCountryStructure(GTDATA[1]) # CPI 2000 base 
	    mask1 = eval_periods(evaldata, period1)
	    evalmask = mask1
	elseif PERIOD == :b10 
	    evaldata = UniformCountryStructure(GTDATA[2]) # CPI 2010 base 
	    mask2 = eval_periods(evaldata, period2)
	    evalmask = mask2
	else
	    # All available data 
	    evaldata = GTDATA[Date(2021,12)]
	    mask1 = eval_periods(evaldata, period1)
	    mask2 = eval_periods(evaldata, period2)
	    evalmask = mask1 .| mask2 
	end
	evaldata
end

# ╔═╡ 9f2ffb0f-bcf7-4eb6-994b-d2b4cc28e24b
begin
	# Depending on the single period selected (:b00 or :b10), these functions select the appropriate exclusion specifications for the fixed exclusion methods
	function food_energy_specs(period)
	    if period == :b00 
	        return [23:41..., 104, 159]
	    elseif period == :b10 
	        return [22:48..., 116, 184:186...]
	    else
	        return [23:41..., 104, 159], [22:48..., 116, 184:186...]
	    end
	end
	
	function energy_specs(period)
	    if period == :b00 
	        return [104, 159]
	    elseif period == :b10 
	        return [116, 184:186...]
	    else
	        return [104, 159], [116, 184:186...]
	    end
	end
	
	# Fixes exclusion specs for the InflationFixedExclusionCPI included in the combination ensemble combfn, using specs for period specified.
	function cmb_specs(combfn, period)
	    fns = [combfn.ensemble.functions...]
	    f = [fn isa InflationFixedExclusionCPI for fn in fns]
	
	    exc_specs = fns[f][].v_exc
	    if period == :b00 
	        specs = exc_specs[1]
	    elseif period == :b10 
	        specs = exc_specs[2]
	    else
	        specs = exc_specs
	    end
	    fxfn = InflationFixedExclusionCPI(specs)
	    fns[.!f]..., fxfn
	end

	f_nooptimals = BitVector(Bool[1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1])
	
	infl_measures = [
	    InflationTotalCPI(), 
	    InflationWeightedMean(), 
	    optmse2019,
	    optmse2022,
	    cmb_specs(optmse2022, PERIOD)..., 
	    # Other measures used in DIE-BG 
	    InflationTrimmedMeanEq(8,92), 
	    InflationTrimmedMeanEq(6,94),
	    InflationDynamicExclusion(2,2),
	    InflationFixedExclusionCPI(food_energy_specs(PERIOD)), # Food & energy 
	    InflationFixedExclusionCPI(energy_specs(PERIOD)), # Energy exclusion 
	    # Central banks measures
	    InflationTrimmedMeanWeighted(8,92),
	    InflationTrimmedMeanEq(24,69),
	    InflationTrimmedMeanWeighted(24,69),
	    InflationPercentileEq(50), # Fed Cleveland
	    InflationPercentileWeighted(50), # Fed Cleveland & Bank of Canada
		#InflationPercentileEq(80), # Fed Cleveland
	    #InflationPercentileWeighted(80) # Fed Cleveland & Bank of Canada
	]
end

# ╔═╡ 46d7a2e0-e057-4cb6-a0da-f8064a909201
@bind p Slider(0:0.05:1, default=0.5, show_value=true)

# ╔═╡ 77ee5d5a-6d1c-430b-baaa-55477f452ce2
@bind fns MultiCheckBox(infl_measures, 
	default=infl_measures[f_nooptimals], 
	select_all=true
)

# ╔═╡ e666b429-b53e-457b-b841-676b0aa87186
begin
	resamplefn = ResampleScrambleTrended(p)
	param = InflationParameter(PARAM_INFLFN, resamplefn, TrendIdentity())
	tray_infl_param = param(evaldata)

	param_data_fn = get_param_function(resamplefn)
    param_data = param_data_fn(evaldata)
	
	dates = infl_dates(evaldata)
	p1 = plot(dates, tray_infl_param, 
		label="Trayectoria paramétrica p=$(round(p,digits=5))",
		linewidth = 2,
		alpha = evalmask, 
		ylims = (-1, 14),
		size = (800, 600)
	)

	vline!(p1, [Date(2001,12), Date(2005,12), Date(2011,12), Date(2015,12)], 
		label = "Períodos de evaluación", 
		linestyle = :dash, 
		linealpha = 0.85,
		color = :gray
	)

	for fn in fns
		plot!(p1, fn, param_data, alpha=evalmask, legend=:outerbottom)
	end
	p1
end

# ╔═╡ 3dc10ca1-1633-4c6c-9d38-7866323222dc
mses = map(fns) do inflfn 
	# Compute the historic trajectory 
	tray_infl = inflfn(evaldata)
	# Compute the MSE against the parametric trajectory 
	mean(x -> x^2, tray_infl[evalmask] - tray_infl_param[evalmask])
end

# ╔═╡ 47981e4d-d280-4a81-869d-0a6f242238db
md"""
Mínimo, mediana, máximo:
"""

# ╔═╡ 98fad0ee-9c6d-4c38-95ca-33b6893239a1
(min=minimum(mses), median=median(mses), max=maximum(mses), range=maximum(mses)-minimum(mses))

# ╔═╡ 71450683-c4ce-4a56-881b-cf9e9f4b4f7c
begin
	p2 = plot(dates, tray_infl_param, 
		label="Trayectoria paramétrica p=$(round(p,digits=5))",
		linewidth = 2,
		alpha = evalmask, 
		ylims = (-1, 14),
		size = (800, 600)
	)

	vline!(p2, [Date(2001,12), Date(2005,12), Date(2011,12), Date(2015,12)], 
		label = "Períodos de evaluación", 
		linestyle = :dash, 
		linealpha = 0.85,
		color = :gray
	)

	for fn in fns
		plot!(p2, fn, evaldata, alpha=evalmask, legend=:outerbottom)
	end
	p2
end

# ╔═╡ Cell order:
# ╠═97cd2a90-a47f-11ec-1a1f-63e464a95fa7
# ╠═baf02c1f-5b89-4d7a-8da3-c0ee74e2399a
# ╟─f6d981a9-2d09-4dd7-875f-a791543520e4
# ╟─9f2ffb0f-bcf7-4eb6-994b-d2b4cc28e24b
# ╟─46d7a2e0-e057-4cb6-a0da-f8064a909201
# ╟─77ee5d5a-6d1c-430b-baaa-55477f452ce2
# ╟─e666b429-b53e-457b-b841-676b0aa87186
# ╟─3dc10ca1-1633-4c6c-9d38-7866323222dc
# ╟─47981e4d-d280-4a81-869d-0a6f242238db
# ╟─98fad0ee-9c6d-4c38-95ca-33b6893239a1
# ╟─71450683-c4ce-4a56-881b-cf9e9f4b4f7c
