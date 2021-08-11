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

# ╔═╡ 50cbe724-1bbe-4e3f-ae1a-6ae5929723ca
using Plots

# ╔═╡ e6ab155f-8696-4f11-b189-7c8421a31cc1
using PlutoUI

# ╔═╡ ae3be1ce-505a-4546-9835-743c86a5396f
#=begin 
	import Pkg 
	Pkg.activate("..")
	
	using DrWatson
end
=#

# ╔═╡ d88d8512-202f-4b5d-9109-827e6df844f9
# @everywhere Pkg.activate($(projectdir()))

# ╔═╡ 968d6513-01b8-41c0-a0c9-2a2cf66d9c1e
# @everywhere using HEMI 

# ╔═╡ 365e11bb-c3ca-4a5f-b0f8-545399cb2706
md"""
### Percentiles
 $q_1=$ $(@bind q1 Slider(0:0.01:0.5, show_value=true)) 
 
 $q_2=$ $(@bind q2 Slider(0.5:0.01:1, show_value=true))
"""

# ╔═╡ 9ea71b7f-ab2f-498d-83ed-97e64218a63a
inflfn = InflationCoreMai(MaiFP([0, q1, q2, 1]))

# ╔═╡ be8af195-dece-4e2f-8e56-bd2bc003829f
begin
	plot(InflationTotalCPI(), gtdata) 
	plot!(InflationCoreMai(MaiF(5)), gtdata) 
	plot!(inflfn, gtdata) 
end

# ╔═╡ 5ee9ca00-cb68-4b19-b81a-b5faa8091dc0
begin 
	resamplefn = ResampleScrambleVarMonths() 
	trendfn = TrendRandomWalk() 
	paramfn = InflationTotalRebaseCPI(36,2) 
	
	config = SimConfig(
		inflfn, 
		resamplefn, 
		trendfn, 
		paramfn, 
		100, 
		Date(2019, 12)
	)
end

# ╔═╡ 81a28b3e-98dd-483b-ae6b-9013df6384d9
begin 
	metrics, tray_infl = evalsim(gtdata, config, short=true);
	m_tray_infl = mean(tray_infl, dims=3) |> vec 
	mse = metrics[:mse]
	
	param = InflationParameter(paramfn, resamplefn, trendfn) 
	tray_infl_param = param(gtdata[Date(2019,12)])
	plot(infl_dates(gtdata[Date(2019,12)]), [m_tray_infl tray_infl_param], 
		label=["Trayectoria promedio" "Paramétrica"])
end

# ╔═╡ cb095405-2979-4997-8480-f73bb47d19e1
mse

# ╔═╡ 6b3beffe-faa7-48ac-9823-a280073bb82f


# ╔═╡ 303e5910-f649-11eb-01e3-ffc124311469
begin
	macro everywhere(procs, ex)
		return esc(:(Main.@everywhere $procs $ex))
	end
	workers() = filter(pid -> pid != Main.myid(), Main.workers())
	macro everywhere(ex)
		# have pluto handle evaluation on workspace process
		return esc(:(@everywhere workers() $ex; eval($(Expr(:quote, ex)))))
	end
end

# ╔═╡ 3ee5e33e-157c-48b8-a4e5-09ca1693a9b4
begin
	@everywhere 1 using Distributed
	addprocs(args...; kwargs...) = @everywhere 1 addprocs($args...; $kwargs...)
	rmprocs(args...; kwargs...) = @everywhere 1 rmprocs($args...; $kwargs...)
end

# ╔═╡ 32a6d0e9-e481-4483-9947-b4329894a0f8
addprocs(4, exeflags="--project")

# ╔═╡ 7c4f09d5-c82d-4d2f-910b-c474a17581be
@everywhere 1 begin 
	import Pkg
	Pkg.activate("C:\\Users\\Rodrigo\\Documents\\Julia\\HEMI\\")
end

# ╔═╡ b5dbfc23-9b90-46f0-8e17-e727bb1ebd42
@everywhere using HEMI 

# ╔═╡ f0fab4d7-ca28-4464-951f-587394dee8bf
workers() 

# ╔═╡ Cell order:
# ╠═3ee5e33e-157c-48b8-a4e5-09ca1693a9b4
# ╠═7c4f09d5-c82d-4d2f-910b-c474a17581be
# ╠═b5dbfc23-9b90-46f0-8e17-e727bb1ebd42
# ╠═32a6d0e9-e481-4483-9947-b4329894a0f8
# ╠═f0fab4d7-ca28-4464-951f-587394dee8bf
# ╠═ae3be1ce-505a-4546-9835-743c86a5396f
# ╠═d88d8512-202f-4b5d-9109-827e6df844f9
# ╠═968d6513-01b8-41c0-a0c9-2a2cf66d9c1e
# ╠═50cbe724-1bbe-4e3f-ae1a-6ae5929723ca
# ╠═e6ab155f-8696-4f11-b189-7c8421a31cc1
# ╟─365e11bb-c3ca-4a5f-b0f8-545399cb2706
# ╠═9ea71b7f-ab2f-498d-83ed-97e64218a63a
# ╟─be8af195-dece-4e2f-8e56-bd2bc003829f
# ╠═cb095405-2979-4997-8480-f73bb47d19e1
# ╟─81a28b3e-98dd-483b-ae6b-9013df6384d9
# ╠═5ee9ca00-cb68-4b19-b81a-b5faa8091dc0
# ╠═6b3beffe-faa7-48ac-9823-a280073bb82f
# ╠═303e5910-f649-11eb-01e3-ffc124311469
