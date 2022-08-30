using DrWatson
@quickactivate "HEMI"
using HEMI
using CSV
using DataFrames

savedir = datadir("results","CSV","fx-exc")
mkpath(savedir)

GB_dir = datadir("guatemala")

include(scriptsdir("generate_optim_combination","2022","optmse2022.jl"))
include(scriptsdir("generate_optim_combination","2022","optabsme2022.jl"))
include(scriptsdir("generate_optim_combination","2022","optcorr2022.jl"))

include(scriptsdir("generate_optim_combination","2023","optmse2023.jl"))
include(scriptsdir("generate_optim_combination","2023","optabsme2023.jl"))
include(scriptsdir("generate_optim_combination","2023","optcorr2023.jl"))

GB00 = DataFrame(CSV.File(joinpath(GB_dir,"Guatemala_GB_2000.csv")))
GB00[!,:desv] = vec(std(GT00.v |> capitalize |> varinteran, dims=1))
GB00[!, :ine] = 1:nrow(GB00)

GB10 = DataFrame(CSV.File(joinpath(GB_dir,"Guatemala_GB_2010.csv")))
GB10[!,:desv] = vec(std(GT10.v |> capitalize |> varinteran, dims=1))
GB10[!, :ine] = 1:nrow(GB10)

opt_vec = [optmse2023, optabsme2023, optcorr2023]

V = []
for elem in opt_vec
    a = map(x->isa(x,InflationFixedExclusionCPI), elem.ensemble.functions) |> findall
    b = elem.ensemble.functions[a][1].v_exc
    append!(V,b)
end

df_mse_00 = GB00[V[1],[:ine,:GoodOrService,:desv,:Weight]]
df_mse_10 = GB10[V[2],[:ine,:GoodOrService,:desv,:Weight]]
df_absme_00 = GB00[V[3],[:ine,:GoodOrService,:desv,:Weight]]
df_absme_10 = GB10[V[4],[:ine,:GoodOrService,:desv,:Weight]]
df_corr_00 = GB10[V[5],[:ine,:GoodOrService,:desv,:Weight]]
df_corr_10 = GB10[V[6],[:ine,:GoodOrService,:desv,:Weight]]

CSV.write(joinpath(savedir,"df_mse_00.csv"), df_mse_00)
CSV.write(joinpath(savedir,"df_mse_10.csv"), df_mse_10)
CSV.write(joinpath(savedir,"df_absme_00.csv"), df_absme_00)
CSV.write(joinpath(savedir,"df_absme_10.csv"), df_absme_10)
CSV.write(joinpath(savedir,"df_corr_00.csv"), df_corr_00)
CSV.write(joinpath(savedir,"df_corr_10.csv"), df_corr_10)

DF = DataFrame()
for elem in [optmse2022, optmse2023, optabsme2022, optabsme2023, optcorr2022, optcorr2023]
    a = map(x->isa(x,InflationFixedExclusionCPI), elem.ensemble.functions) |> findall
    b = elem.ensemble.functions[a][1]
    DF[!,measure_name(b)*" - "*measure_name(elem)] = b(GTDATA)
end

CSV.write(joinpath(savedir,"tray_fx-exc.csv"), DF)