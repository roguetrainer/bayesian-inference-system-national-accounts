# Comparison utilities for RAS vs Gen.jl balancing methods
# 
# This module provides functions to:
# - Run both methods on the same data
# - Compare results quantitatively
# - Visualize differences

using Gen
using LinearAlgebra
using Printf
using Statistics

"""
    compare_balancing_methods(prior_matrix, target_rows, target_cols, 
                              row_sigmas, col_sigmas)

Run both RAS and Gen.jl on the same data and compare results.

Returns a Dict with comparison metrics.
"""
function compare_balancing_methods(
    prior_matrix::Matrix{Float64},
    target_rows::Vector{Float64},
    target_cols::Vector{Float64},
    row_sigmas::Vector{Float64},
    col_sigmas::Vector{Float64};
    verbose::Bool = true
)
    
    if verbose
        println("\n" * "="^70)
        println("Comparing RAS vs Gen.jl Balancing Methods")
        println("="^70 * "\n")
    end
    
    # Run Gen.jl balancing
    if verbose
        println("Running Gen.jl probabilistic balancing...")
    end
    gen_result, gen_trace = gen_balance_with_trace(
        prior_matrix, target_rows, target_cols,
        row_sigmas, col_sigmas
    )
    
    # For comparison with RAS, we need to run RAS-style balancing
    # (This would typically call Python, but we'll implement a simple version)
    if verbose
        println("Running RAS-style balancing (equal weights)...")
    end
    ras_result = simple_ras_balance(prior_matrix, target_rows, target_cols)
    
    # Calculate comparison metrics
    metrics = Dict{String, Any}()
    
    # 1. Constraint satisfaction
    gen_row_errors = sum(gen_result, dims=2)[:] .- target_rows
    gen_col_errors = sum(gen_result, dims=1)[:] .- target_cols
    ras_row_errors = sum(ras_result, dims=2)[:] .- target_rows
    ras_col_errors = sum(ras_result, dims=1)[:] .- target_cols
    
    metrics["gen_max_row_error"] = maximum(abs.(gen_row_errors))
    metrics["gen_max_col_error"] = maximum(abs.(gen_col_errors))
    metrics["ras_max_row_error"] = maximum(abs.(ras_row_errors))
    metrics["ras_max_col_error"] = maximum(abs.(ras_col_errors))
    
    # 2. Divergence from prior
    metrics["gen_total_adjustment"] = sum(abs.(gen_result .- prior_matrix))
    metrics["ras_total_adjustment"] = sum(abs.(ras_result .- prior_matrix))
    
    # 3. Difference between methods
    metrics["method_difference"] = sum(abs.(gen_result .- ras_result))
    metrics["method_difference_pct"] = 100 * metrics["method_difference"] / sum(abs.(ras_result))
    
    # 4. Weighted constraint satisfaction (Gen's advantage)
    weighted_row_errors = gen_row_errors ./ row_sigmas
    weighted_col_errors = gen_col_errors ./ col_sigmas
    metrics["gen_weighted_row_error"] = norm(weighted_row_errors)
    metrics["gen_weighted_col_error"] = norm(weighted_col_errors)
    
    if verbose
        println("\n" * "="^70)
        println("Comparison Metrics")
        println("="^70)
        println("\nConstraint Satisfaction (Max Absolute Error):")
        @printf("  Gen Row Errors:  %.6f\n", metrics["gen_max_row_error"])
        @printf("  Gen Col Errors:  %.6f\n", metrics["gen_max_col_error"])
        @printf("  RAS Row Errors:  %.6f\n", metrics["ras_max_row_error"])
        @printf("  RAS Col Errors:  %.6f\n", metrics["ras_max_col_error"])
        
        println("\nTotal Adjustments from Prior:")
        @printf("  Gen: %.2f\n", metrics["gen_total_adjustment"])
        @printf("  RAS: %.2f\n", metrics["ras_total_adjustment"])
        
        println("\nDifference Between Methods:")
        @printf("  Absolute: %.2f\n", metrics["method_difference"])
        @printf("  Percentage: %.2f%%\n", metrics["method_difference_pct"])
        
        println("\nWeighted Errors (Gen's optimization target):")
        @printf("  Row constraint violations: %.4f\n", metrics["gen_weighted_row_error"])
        @printf("  Col constraint violations: %.4f\n", metrics["gen_weighted_col_error"])
        println("\n" * "="^70 * "\n")
    end
    
    return Dict(
        "gen_result" => gen_result,
        "ras_result" => ras_result,
        "metrics" => metrics,
        "gen_trace" => gen_trace
    )
end


"""
    simple_ras_balance(matrix, target_rows, target_cols; 
                       tol=1e-6, max_iter=1000)

Simple implementation of RAS algorithm in Julia for comparison.
"""
function simple_ras_balance(
    matrix::Matrix{Float64},
    target_rows::Vector{Float64},
    target_cols::Vector{Float64};
    tol::Float64 = 1e-6,
    max_iter::Int = 1000
)
    balanced = copy(matrix)
    rows, cols = size(balanced)
    
    for iter in 1:max_iter
        # R step: Scale rows
        current_row_sums = sum(balanced, dims=2)[:]
        r_scalers = target_rows ./ (current_row_sums .+ 1e-10)
        balanced = balanced .* r_scalers
        
        # S step: Scale columns
        current_col_sums = sum(balanced, dims=1)[:]
        s_scalers = target_cols ./ (current_col_sums .+ 1e-10)
        balanced = balanced .* s_scalers'
        
        # Check convergence
        row_diff = sum(abs.(sum(balanced, dims=2)[:] .- target_rows))
        col_diff = sum(abs.(sum(balanced, dims=1)[:] .- target_cols))
        
        if row_diff + col_diff < tol
            return balanced
        end
    end
    
    @warn "RAS did not converge within $max_iter iterations"
    return balanced
end


"""
    gen_balance_with_trace(prior_matrix, target_rows, target_cols,
                           row_sigmas, col_sigmas)

Run Gen.jl balancing and return both the result and the trace.
"""
function gen_balance_with_trace(
    prior_matrix::Matrix{Float64},
    target_rows::Vector{Float64},
    target_cols::Vector{Float64},
    row_sigmas::Vector{Float64},
    col_sigmas::Vector{Float64};
    n_iterations::Int = 5000
)
    
    rows, cols = size(prior_matrix)
    
    # Create observations
    observations = choicemap()
    for r in 1:rows
        observations[:row_targets => r] = target_rows[r]
    end
    for c in 1:cols
        observations[:col_targets => c] = target_cols[c]
    end
    
    # Initialize
    init_params = choicemap()
    for r in 1:rows
        for c in 1:cols
            init_params[:cells => (r, c)] = prior_matrix[r, c]
        end
    end
    
    # Generate initial trace (need to have the model defined)
    # Note: This assumes flow_of_funds_model is defined in the same scope
    # or has been included from gen_balancing.jl
    (trace, _) = generate(
        flow_of_funds_model, 
        (prior_matrix, row_sigmas, col_sigmas), 
        init_params
    )
    
    # Optimize
    for i in 1:n_iterations
        (trace, _) = map_optimize(trace, selection=select(:cells))
    end
    
    result = get_retval(trace)
    return result, trace
end


"""
    analyze_cell_adjustments(prior, gen_result, ras_result; threshold=0.1)

Identify cells where Gen and RAS differ significantly.
"""
function analyze_cell_adjustments(
    prior::Matrix{Float64},
    gen_result::Matrix{Float64},
    ras_result::Matrix{Float64};
    threshold::Float64 = 0.1,
    sector_names::Vector{String} = ["HH", "Corp", "Gov", "ROW"],
    instrument_names::Vector{String} = ["Cash", "Bonds", "Equity", "Loans"]
)
    
    rows, cols = size(prior)
    
    println("\n" * "="^70)
    println("Cell-by-Cell Analysis: Where do Gen and RAS differ?")
    println("="^70)
    println("\nCells where methods differ by more than $(threshold*100)%:")
    println()
    @printf("%-6s %-10s %10s %10s %10s %12s\n", 
            "Sector", "Instrument", "Prior", "Gen", "RAS", "Difference")
    println("-"^70)
    
    significant_differences = 0
    
    for r in 1:rows
        for c in 1:cols
            gen_val = gen_result[r, c]
            ras_val = ras_result[r, c]
            prior_val = prior[r, c]
            
            # Calculate percentage difference
            avg_val = (gen_val + ras_val) / 2
            if avg_val > 1.0  # Only for non-trivial cells
                pct_diff = abs(gen_val - ras_val) / avg_val
                
                if pct_diff > threshold
                    significant_differences += 1
                    sector = r <= length(sector_names) ? sector_names[r] : "Sec$r"
                    inst = c <= length(instrument_names) ? instrument_names[c] : "Inst$c"
                    @printf("%-6s %-10s %10.2f %10.2f %10.2f %11.1f%%\n",
                            sector, inst, prior_val, gen_val, ras_val, pct_diff*100)
                end
            end
        end
    end
    
    if significant_differences == 0
        println("  (No significant differences found)")
    end
    
    println("-"^70)
    println("Total cells with significant differences: $significant_differences")
    println("="^70 * "\n")
end


"""
    visualize_adjustments(prior, balanced; title="Adjustments")

Simple ASCII visualization of how cells were adjusted.
"""
function visualize_adjustments(
    prior::Matrix{Float64},
    balanced::Matrix{Float64};
    title::String = "Cell Adjustments"
)
    
    rows, cols = size(prior)
    adjustments = balanced .- prior
    pct_adjustments = 100 * adjustments ./ (prior .+ 1e-10)
    
    println("\n" * "="^60)
    println(title)
    println("="^60)
    println("\nPercentage Change from Prior:")
    println()
    
    # Header
    @printf("%-6s", "")
    for c in 1:cols
        @printf(" %8s", "Col$c")
    end
    println()
    println("-"^60)
    
    # Rows
    for r in 1:rows
        @printf("Row%-3d", r)
        for c in 1:cols
            val = pct_adjustments[r, c]
            if abs(val) < 0.1
                @printf(" %8s", "~")
            elseif val > 0
                @printf(" %7.1f%%", val)
            else
                @printf(" %7.1f%%", val)
            end
        end
        println()
    end
    
    println("-"^60)
    println("~ indicates < 0.1% change")
    println("="^60 * "\n")
end


"""
    generate_comparison_report(prior, target_rows, target_cols,
                               row_sigmas, col_sigmas)

Generate a comprehensive comparison report.
"""
function generate_comparison_report(
    prior_matrix::Matrix{Float64},
    target_rows::Vector{Float64},
    target_cols::Vector{Float64},
    row_sigmas::Vector{Float64},
    col_sigmas::Vector{Float64}
)
    
    println("\n")
    println("╔" * "="^68 * "╗")
    println("║" * " "^15 * "RAS vs Gen.jl Comparison Report" * " "^21 * "║")
    println("╚" * "="^68 * "╝")
    
    # Run comparison
    results = compare_balancing_methods(
        prior_matrix, target_rows, target_cols,
        row_sigmas, col_sigmas,
        verbose=true
    )
    
    gen_result = results["gen_result"]
    ras_result = results["ras_result"]
    
    # Visualize adjustments
    visualize_adjustments(prior_matrix, gen_result, title="Gen.jl Adjustments")
    visualize_adjustments(prior_matrix, ras_result, title="RAS Adjustments")
    
    # Cell-level analysis
    analyze_cell_adjustments(prior_matrix, gen_result, ras_result)
    
    return results
end


# Example usage
if abspath(PROGRAM_FILE) == @__FILE__
    println("Comparison Utilities for National Accounts Balancing")
    println("This module provides functions to compare RAS and Gen.jl methods.")
    println("\nUsage:")
    println("  results = compare_balancing_methods(prior, rows, cols, row_σ, col_σ)")
    println("  generate_comparison_report(prior, rows, cols, row_σ, col_σ)")
end
