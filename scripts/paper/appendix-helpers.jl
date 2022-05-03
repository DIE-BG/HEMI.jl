function get_ci(df_obs_optmse, df_optmse_ci)
    dates = df_obs_optmse.dates
    tray_infl_optmse = df_obs_optmse.a_optmse

    inf_limit = Vector{Union{Missing, Float32}}(undef, length(dates))
    sup_limit = Vector{Union{Missing, Float32}}(undef, length(dates))
    for t in 1:length(dates)
        for r in eachrow(df_optmse_ci)
            period = r.evalperiod
            if period.startdate <= dates[t] <= period.finaldate
                inf_limit[t] = tray_infl_optmse[t] + r.inf_limit
                sup_limit[t] = tray_infl_optmse[t] + r.sup_limit
            end
        end
    end

    hcat(df_obs_optmse, DataFrame(
        inf_limit = inf_limit, sup_limit = sup_limit
    ))
end