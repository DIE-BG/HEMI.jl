using DrWatson
@quickactivate :HEMI

using DataFrames
using PrettyTables
using Distributions
using Plots
using StatsPlots
using LaTeXStrings

## Path 
plots_savepath = mkpath(plotsdir("paper", "variance-estimators"))

N = 10 
K = 1_000_000
μ = 0
σ² = 1
DIST = Normal(μ, sqrt(σ²))

## Generate sample of estimators' distributions

# Sample distribution of biased variance estimator
ml_est = map(1:K) do _
    # Draw a sample of size N from the distribution DIST
    sample = rand(DIST, N)

    # Compute the estimator
    estimator = var(sample; corrected=false)
    estimator
end

# Sample distribution of biased variance estimator
unbiased_est = map(1:K) do _
    # Draw a sample of size N from the distribution DIST
    sample = rand(DIST, N)

    # Compute the unbiased estimator
    estimator = var(sample; corrected=true)
    estimator
end


## Asymptotic distribution of both variance estimators

unbiased_chi = @. unbiased_est * (N-1) / σ²
ml_chi = @. biased_est * (N) / σ²
histogram(unbiased_chi, label="Unbiased variance estimator", normalize=:pdf, alpha=0.3)
histogram!(ml_chi, label="ML variance estimator", normalize=:pdf, alpha=0.3)
plot!(Chisq(N-1), label="ChiSq(N-1)", c=:blue, lw=5, ls=:dot)

## Comparison of sample distribution of variance estimators

histogram(
    ml_est,
    bins=0:0.05:5, 
    label="Max. Likelihood estimator", 
    normalize = :pdf,
    alpha=0.5, 
    linewidth=0.5,
    xlabel="Variance estimate of " * L"\sigma^2",
    size=(900, 600),
)

ml_est_mean = mean(ml_est)
vline!([ml_est_mean], label="Max. Likelihood estimator mean", lw=5, ls=:dot, c=1) 
annotate!([(1.5,1,L"E[\hat{\sigma^2}]=%$(round(ml_est_mean,digits=3))")])

histogram!(
    unbiased_est,
    bins=0:0.05:5, 
    label="Unbiased estimator", 
    normalize = :pdf,
    alpha=0.5, 
    linewidth=0,
    color=2,
)

unbiased_est_mean = mean(unbiased_est)
vline!([unbiased_est_mean], label="Unbiased estimator mean", lw=5, ls=:dot, c=2) 
annotate!([(1.5, 0.8,L"E[\hat{s^2}]=%$(round(unbiased_est_mean, digits=3))")])

## Save the figure

p = current()

plot(p, 
    title="Sample distributions for variance estimators of normal distribution",
    top_margin=3*Plots.mm,
    bottom_margin=3*Plots.mm,
)

savefig(joinpath(plots_savepath, "variance_estimators_comparison.png"))

## Compute DataFrame of MSE 

stats = DataFrame(
    estimator = ["ML estimator", "Unbiased estimator"], 
    bias = [mean(ml_est) - σ², mean(unbiased_est) - σ²],
    variance = [var(ml_est), var(unbiased_est)]
)
stats[!, :mse] .= stats.bias .^2 + stats.variance
stats

pretty_table(stats, tf=tf_markdown, formatters=ft_round(3))