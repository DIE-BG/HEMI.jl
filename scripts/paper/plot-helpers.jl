
using DataFrames
using Chain
using PrettyTables
using CSV
using Plots

# Function to get matrix of inflation trajectories
function get_realizations(df_results, measure_tag)
    # Get inflation trajectories from df_results obtained with DrWatson
    tray_infl = @chain df_results begin
        transform!(:path => ByRow(basename) => :name)
        subset(:name => ByRow(s -> contains(s, measure_tag)))
        getindex(1, 1)
        reshape(_, :, size(_, 3))
    end

    return tray_infl
end

# Function to plot cloud trajectories 
function cloudplot(tray_infl, trend_infl, alldates, measure_name, period; sample_size=500, ylims=:auto)

    # Get a mask for the desired evaluation periods
    periods_mask = eval_periods(data, period)

    dates = alldates[periods_mask]
    yearstep = period == CompletePeriod() ? 24 : 12
    date_ticks = first(dates):Month(yearstep):last(dates)
    date_str = Dates.format.(date_ticks, dateformat"Y-m")

    # Get a sample of the trajectories 
    K = size(tray_infl, 2)
    sample = rand(1:K, sample_size)
    sample_traj = tray_infl[periods_mask, sample]

    # Create base plot with cloud trajectories
    bp = plot(
        dates,
        sample_traj[:, 2:end];
        label=false,
        ylims=ylims,
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
function savecloudplot(
    cplot, measure_tag, period, savepath; pdf_size=(800, 600), png_size=(1200, 800)
)
    pdf_filename = savename(
        "cloud_trajectories", (measure=measure_tag, period=period_tag(period)), "pdf"
    )
    png_filename = savename(
        "cloud_trajectories", (measure=measure_tag, period=period_tag(period)), "png"
    )

    # Save as PDF file 
    plot(cplot; size=pdf_size)
    @info "Saving PDF file"
    savefig(joinpath(savepath, pdf_filename))

    # Save as a PNG file
    plot(
        cplot;
        left_margin=5 * Plots.mm,
        bottom_margin=5 * Plots.mm,
        guidefontsize=12,
        size=png_size,
    )
    @info "Saving PNG file"
    return savefig(joinpath(savepath, png_filename))
end

# Function to export a sample of realizations to CSV output file
function exportcloud(tray_infl, trend_infl, dates, measure_tag, savepath; sample_size = 500)

    # Get a sample of the trajectories 
    K = size(tray_infl, 2)
    sample = rand(1:K, sample_size)
    sample_traj = tray_infl[:, sample]

    # Population trend and dates DataFrame
    param_df = DataFrame(; dates=dates, pop_trend=trend_infl)
    # Sample of Realizations for measure of inflation
    measure_df = DataFrame(sample_traj, :auto)
    # Join the two DataFrames
    output_df = [param_df measure_df]

    output_file = joinpath(savepath, measure_tag * ".csv")
    return CSV.write(output_file, output_df)
end