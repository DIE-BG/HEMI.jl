using DrWatson
@quickactivate :HEMI

using DataFrames, Chain, PrettyTables
using CSV
using Plots

## Path 
plots_savepath = mkpath(plotsdir("paper"))
csv_output = datadir("results", "paper-assessment", "clouds")

## TIMA settings 

# Resampling technique, parametric inflation formula and trend function 
paramfn = InflationTotalRebaseCPI(60)
resamplefn = ResampleScrambleVarMonths()
trendfn = TrendRandomWalk()

# CPI data
data = GTDATA[Date(2020, 12)]
alldates = infl_dates(data)

# Population trend inflation series
param = InflationParameter(paramfn, resamplefn, trendfn)
trend_infl = param(data)

## Load simulated inflation trajectories
savepath = datadir("results", "paper-assessment", "tray_infl")
df_results = collect_results(savepath)
transform!(df_results, :path => ByRow(basename) => :name)


## Helper functions

function cloudplot(
    measure_tag, 
    measure_name, 
    period; 
    df_results=df_results, 
    alldates=alldates, 
    sample_size=500
)

    # Get inflation trajectories from df_results obtained with DrWatson
    measure_infl = @chain df_results begin
        subset(:name => ByRow(s -> contains(s, measure_tag)))
        getindex(1, 1)
        reshape(_, :, size(_, 3))
    end

    # Get a mask for the desired evaluation periods
    periods_mask = eval_periods(data, period)

    dates = alldates[periods_mask]
    yearstep = period == CompletePeriod() ? 24 : 12
    date_ticks = first(dates):Month(yearstep):last(dates)
    date_str = Dates.format.(date_ticks, dateformat"Y-m")

    # Get a sample of the trajectories 
    K = size(measure_infl, 2)
    sample = rand(1:K, sample_size)
    sample_traj = measure_infl[periods_mask, sample]

    custom_ylims = contains(measure_tag, "Total") ? (-50, 100) : :auto 

    # Create base plot with cloud trajectories
    bp = plot(
        dates,
        sample_traj[:, 2:end];
        label=false,
        ylims=custom_ylims,
        ylabel="% change, year-on-year",
        alpha=0.3,
        palette=:grays,
        guidefontsize=8,
        xticks=(date_ticks, date_str),
        xrotation=45,
    )

    # Add a first trajectory to show legend
    plot!(
        bp,
        dates,
        sample_traj[:, 1];
        label="Realizations of $(measure_name)",
        legend=:topright,
        color=:gray,
    )

    # Add the population trend inflation
    plot!(
        bp,
        dates,
        trend_infl[periods_mask];
        label="Population trend inflation",
        color=:blue,
        linewidth=4,
        guidefontsize=8,
        xticks=(date_ticks, date_str),
        xrotation=45,
    )

    return bp
end

# Plot with different sizes/resolution
function savecloudplot(cplot, measure_tag, period, savepath) 

    pdf_filename = savename(
        "cloud_trajectories", 
        (measure=measure_tag, period=period_tag(period),), 
        "pdf"
    )
    png_filename = savename(
        "cloud_trajectories", 
        (measure=measure_tag, period=period_tag(period),),
        "png"
    )
    
    # Save as PDF file 
    plot(cplot; size=(800, 600))
    @info "Saving PDF file"
    savefig(joinpath(savepath, pdf_filename))
    
    # Save as a PNG file
    plot(
        cplot;
        left_margin=5 * Plots.mm,
        bottom_margin=5 * Plots.mm,
        guidefontsize=12,
        size=(1200, 800),
    )
    @info "Saving PNG file"
    savefig(joinpath(savepath, png_filename))
end

function exportcloud(
    measure_tag, 
    savepath,
    df_results=df_results, 
    alldates=alldates, 
    sample_size=500,
)

    # Get inflation trajectories from df_results obtained with DrWatson
    measure_infl = @chain df_results begin
        subset(:name => ByRow(s -> contains(s, measure_tag)))
        getindex(1, 1)
        reshape(_, :, size(_, 3))
    end

    # Get a sample of the trajectories 
    K = size(measure_infl, 2)
    sample = rand(1:K, sample_size)
    sample_traj = measure_infl[:, sample]

    # Population trend and dates DataFrame
    param_df = DataFrame(dates=alldates, pop_trend=trend_infl)
    # Sample of Realizations for measure of inflation
    measure_df = DataFrame(sample_traj, :auto)
    # Join the two DataFrames
    output_df = [param_df measure_df]

    output_file = joinpath(savepath, measure_tag * ".csv")
    CSV.write(output_file, output_df)

end


## Plot trajectory cloud

periods = [
    EvalPeriod(Date(2001, 12), Date(2010, 12), "gt_b00"),
    EvalPeriod(Date(2011, 01), Date(2020, 12), "gt_b10"),
    CompletePeriod(),
]


# CPI Headline inflation cloudplots

headline_cpi_00 = cloudplot("Total", "Headline CPI inflation", periods[1])
headline_cpi_10 = cloudplot("Total", "Headline CPI inflation", periods[2])
headline_cpi_0010 = cloudplot("Total", "Headline CPI inflation", periods[3])

savecloudplot(headline_cpi_00, "Total", periods[1], plots_savepath)
savecloudplot(headline_cpi_10, "Total", periods[2], plots_savepath)
savecloudplot(headline_cpi_0010, "Total", periods[3], plots_savepath)

# CPI Headline inflation cloudplots

wt70_00 = cloudplot("PerW-70.0", "70th Weighted Percentile", periods[1])
wt70_10 = cloudplot("PerW-70.0", "70th Weighted Percentile", periods[2])
wt70_0010 = cloudplot("PerW-70.0", "70th Weighted Percentile", periods[3])

savecloudplot(wt70_00, "WT70", periods[1], plots_savepath)
savecloudplot(wt70_10, "WT70", periods[2], plots_savepath)
savecloudplot(wt70_0010, "WT70", periods[3], plots_savepath)

## Anonymous plot for presentation
est1_0010 = cloudplot("Total", "inflation Estimator 1", periods[3])
est2_0010 = cloudplot("PerW-70.0", "inflation Estimator 2", periods[3])
savecloudplot(est1_0010, "InflEst1", periods[3], plots_savepath)
savecloudplot(est2_0010, "InflEst2", periods[3], plots_savepath)

## Export data

exportcloud("Total", csv_output)
exportcloud("PerW-70.0", csv_output)