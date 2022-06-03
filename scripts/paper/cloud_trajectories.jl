using DrWatson
@quickactivate :HEMI

using DataFrames, Chain, PrettyTables
using CSV
using Plots

## Path 
plots_savepath = mkpath(plotsdir("paper"))

## TIMA settings 

# Resampling technique, parametric inflation formula and trend function 
paramfn = InflationTotalRebaseCPI(60)
resamplefn = ResampleScrambleVarMonths()
trendfn = TrendRandomWalk()

# CPI data
data = GTDATA[Date(2020, 12)]

# Population trend inflation series
param = InflationParameter(paramfn, resamplefn, trendfn)
trend_infl = param(data)

## Load simulated inflation trajectories
savepath = datadir("results", "paper-assessment", "tray_infl")
df_results = collect_results(savepath)
transform!(df_results, :path => ByRow(basename) => :name)

headline_cpi_infl = @chain df_results begin
    subset(:name => ByRow(s -> contains(s, "Total")))
    getindex(1, 1)
    reshape(_, :, size(_, 3))
end

## Plot trajectory cloud

periods = [
    CompletePeriod(),
    EvalPeriod(Date(2001, 12), Date(2010, 12), "gt_b00"),
    EvalPeriod(Date(2011, 01), Date(2020, 12), "gt_b10"),
]

alldates = infl_dates(data)

# Select CPI dataset period to plot 
period = periods[1]

function cloudplot(
    measure_tag, measure_name, period; df_results=df_results, alldates=alldates, sample_size=500
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

    # Create base plot with cloud trajectories
    bp = plot(
        dates,
        sample_traj[:, 2:end];
        label=false,
        ylims=(-50, 100),
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

headline_cpi_00 = cloudplot("Total", "Headline CPI inflation", periods[2])


# Plot with different sizes/resolution

function savecloudplot(cplot, measure_tag, period) 

    pdf_filename = savename(
        "cloud_trajectories", 
        (measure=measure_tag, period=period_tag(period),), 
        "pdf"
    )
    png_filename = savename(
        "cloud_trajectories_cpi_headline", 
        (measure=measure_tag, period=period_tag(period),),
        "png"
    )
    
    # Save as PDF file 
    plot(bp; size=(800, 600))
    @info "Saving PDF file"
    savefig(joinpath(plots_savepath, pdf_filename))
    
    # Save as a PNG file
    NegraMilu+502*
    plot(
        bp;
        left_margin=5 * Plots.mm,
        bottom_margin=5 * Plots.mm,
        guidefontsize=12,
        size=(1200, 800),
    )
    @info "Saving PNG file"
    savefig(joinpath(plots_savepath, png_filename))
end


## Export data

headline_df = DataFrame(sample_traj, :auto)
param_df = DataFrame(; dates=dates, pop_trend=trend_infl)
output_df = [param_df headline_df]

output_file = datadir("results", "paper-assessment", "clouds", "headline_cpi.csv")
CSV.write(output_file, output_df)