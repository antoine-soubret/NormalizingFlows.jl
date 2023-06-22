using Distributions, Bijectors, Optimisers
using LinearAlgebra
using Random
using NormalizingFlows
using Test

@testset "learining 2d Gaussian" begin
    @testset "$T" for T in [Float32, Float64]
        μ = 10 * ones(T, 2)
        Σ = Diagonal(4 * ones(T, 2))
        target = MvNormal(μ, Σ)
        logp(z) = logpdf(target, z)

        q₀ = MvNormal(zeros(T, 2), ones(T, 2))
        flow = Bijectors.transformed(
            q₀, Bijectors.Shift(zero.(μ)) ∘ Bijectors.Scale(ones(T, 2))
        )

        sample_per_iter = 10
        flow_trained, stats, _ = train_flow(
            elbo,
            flow,
            logp,
            sample_per_iter;
            max_iters=5_000,
            optimiser=Optimisers.ADAM(0.01 * one(T)),
            show_progress=false,
        )
        θ, re = Optimisers.destructure(flow_trained)

        el_untrained = elbo(Random.default_rng(), flow, logp, 1000)
        el_trained = elbo(flow_trained, logp, 1000)

        @test all(abs.(θ[1:2] .- μ) .< 0.2)
        @test all(abs.(θ[3:4] .- 2) .< 0.2)
        @test el_trained > el_untrained
        @test el_trained > -1
    end
end