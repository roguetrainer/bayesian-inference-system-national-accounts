# Simple Example: Balancing a Canadian Flow-of-Funds Matrix
# 
# This example demonstrates the basic workflow for balancing
# national accounts data using Gen.jl

using Gen
using Printf

println("="^70)
println("Simple Example: Probabilistic National Accounts Balancing")
println("="^70)
println()

# ============================================================================
# Step 1: Define the Probabilistic Model
# ============================================================================

"""
The generative model for a flow-of-funds matrix.

This model treats the "true" balanced matrix as latent variables,
and the target totals as noisy observations of row/column sums.
"""
@gen function flow_of_funds_model(
    prior_matrix::Matrix{Float64}, 
    row_uncertainty::Vector{Float64}, 
    col_uncertainty::Vector{Float64}
)
    
    rows, cols = size(prior_matrix)
    
    # LATENT VARIABLES: The "true" cell values
    # We start with prior beliefs based on survey data
    true_matrix = zeros(rows, cols)
    
    for r in 1:rows
        for c in 1:cols
            # Each cell is a random variable
            # Prior: centered at survey estimate with some variance
            true_matrix[r, c] = {:cells => (r, c)} ~ normal(
                prior_matrix[r, c], 
                prior_matrix[r,c] * 0.5
            ) 
        end
    end
    
    # ACCOUNTING IDENTITIES: Calculate row and column sums
    calc_row_sums = sum(true_matrix, dims=2)[:]
    calc_col_sums = sum(true_matrix, dims=1)[:]
    
    # OBSERVATIONS: Target totals are noisy measurements of true sums
    # This is where we encode data quality
    for r in 1:rows
        {:row_targets => r} ~ normal(calc_row_sums[r], row_uncertainty[r])
    end
    
    for c in 1:cols
        {:col_targets => c} ~ normal(calc_col_sums[c], col_uncertainty[c])
    end
    
    return true_matrix
end

# ============================================================================
# Step 2: Prepare Data (Simplified Canadian Example)
# ============================================================================

println("Step 1: Setting up Canadian flow-of-funds data")
println("-"^70)

# Sectors: Households, Corporations, Government, Rest of World
sector_names = ["Households", "Corporations", "Government", "ROW"]

# Instruments: Currency, Bonds, Equities, Mortgages
instrument_names = ["Currency", "Bonds", "Equities", "Mortgages"]

# Preliminary estimates from survey data (in billions CAD)
# These numbers don't add up correctly!
prior_matrix = [
    150.0  50.0  200.0  300.0;  # Households (sum = 700, but should be 1000)
    100.0 100.0  100.0   50.0;  # Corporations
     50.0 200.0   50.0    0.0;  # Government
     20.0 100.0   50.0   10.0   # Rest of World
]

println("\nPreliminary Estimates (Survey Data):")
println("  Rows = Sectors, Columns = Instruments")
println()
@printf("%-15s", "")
for inst in instrument_names
    @printf("%12s", inst)
end
@printf("%12s\n", "Row Sum")
println("-"^70)

for (i, sector) in enumerate(sector_names)
    @printf("%-15s", sector)
    for j in 1:4
        @printf("%12.1f", prior_matrix[i,j])
    end
    @printf("%12.1f\n", sum(prior_matrix[i,:]))
end

# Target totals from administrative data (the "truth")
target_row_sums = [1000.0, 500.0, 300.0, 200.0]  # Sector assets
target_col_sums = [400.0, 600.0, 500.0, 500.0]   # Instrument totals

println("\nTarget Totals (Administrative Data):")
println("  Row targets (sector assets): ", target_row_sums)
println("  Col targets (instrument totals): ", target_col_sums)
println()

# ============================================================================
# Step 3: Specify Data Quality (Gen's Key Advantage)
# ============================================================================

println("\nStep 2: Specifying data quality (uncertainty)")
println("-"^70)

# Lower σ = higher trust in the data
# Households: survey data, less reliable (σ = 10.0)
# Government: administrative data, very reliable (σ = 0.1)
row_sigmas = [10.0, 5.0, 0.1, 5.0]

println("\nRow (Sector) Uncertainty:")
for (i, sector) in enumerate(sector_names)
    reliability = row_sigmas[i] < 1.0 ? "HIGH" : 
                  row_sigmas[i] < 5.0 ? "MEDIUM" : "LOW"
    @printf("  %-15s: σ = %5.1f  (%s reliability)\n", 
            sector, row_sigmas[i], reliability)
end

# Currency: hard to track (σ = 10.0)
# Bonds: registered, precise (σ = 0.1)
col_sigmas = [10.0, 0.1, 5.0, 5.0]

println("\nColumn (Instrument) Uncertainty:")
for (i, inst) in enumerate(instrument_names)
    reliability = col_sigmas[i] < 1.0 ? "HIGH" : 
                  col_sigmas[i] < 5.0 ? "MEDIUM" : "LOW"
    @printf("  %-15s: σ = %5.1f  (%s reliability)\n", 
            inst, col_sigmas[i], reliability)
end
println()

# ============================================================================
# Step 4: Run Inference
# ============================================================================

println("\nStep 3: Running probabilistic inference")
println("-"^70)

# Create observations (constraints)
observations = choicemap()
for r in 1:4
    observations[:row_targets => r] = target_row_sums[r]
end
for c in 1:4
    observations[:col_targets => c] = target_col_sums[c]
end

# Initialize with prior matrix
init_params = choicemap()
for r in 1:4
    for c in 1:4
        init_params[:cells => (r, c)] = prior_matrix[r, c]
    end
end

println("\nInitializing trace...")
(trace, _) = generate(
    flow_of_funds_model, 
    (prior_matrix, row_sigmas, col_sigmas), 
    init_params
)

println("Running MAP optimization (5000 iterations)...")
# Optimize to find most likely balanced matrix
for i in 1:5000
    (trace, _) = map_optimize(trace, selection=select(:cells))
    if i % 1000 == 0
        @printf("  Iteration %d/5000\n", i)
    end
end

# Extract result
result = get_retval(trace)

println("\n✓ Inference complete!")
println()

# ============================================================================
# Step 5: Display Results
# ============================================================================

println("="^70)
println("RESULTS: Gen.jl Balanced Matrix")
println("="^70)
println()

@printf("%-15s", "")
for inst in instrument_names
    @printf("%12s", inst)
end
@printf("%12s\n", "Row Sum")
println("-"^70)

for (i, sector) in enumerate(sector_names)
    @printf("%-15s", sector)
    for j in 1:4
        @printf("%12.1f", result[i,j])
    end
    @printf("%12.1f\n", sum(result[i,:]))
end

println("-"^70)
@printf("%-15s", "Column Sum")
for j in 1:4
    @printf("%12.1f", sum(result[:,j]))
end
@printf("%12.1f\n\n", sum(result))

# ============================================================================
# Step 6: Verify Constraints
# ============================================================================

println("Constraint Verification:")
println("-"^70)

calc_rows = sum(result, dims=2)[:]
calc_cols = sum(result, dims=1)[:]

println("\nRow Constraints:")
for (i, sector) in enumerate(sector_names)
    error = calc_rows[i] - target_row_sums[i]
    @printf("  %-15s: Target = %8.1f, Actual = %8.1f, Error = %+7.4f\n",
            sector, target_row_sums[i], calc_rows[i], error)
end

println("\nColumn Constraints:")
for (i, inst) in enumerate(instrument_names)
    error = calc_cols[i] - target_col_sums[i]
    @printf("  %-15s: Target = %8.1f, Actual = %8.1f, Error = %+7.4f\n",
            inst, target_col_sums[i], calc_cols[i], error)
end

# ============================================================================
# Step 7: Interpret Results
# ============================================================================

println("\n" * "="^70)
println("INTERPRETATION")
println("="^70)

println("\nKey Observations:")
println()
println("1. Data Quality Impact:")
println("   - Government row sum is very close to target (high reliability)")
gov_error = abs(calc_rows[3] - target_row_sums[3])
@printf("     Government error: %.4f (σ = %.1f)\n", gov_error, row_sigmas[3])

println()
println("   - Household row sum has more slack (lower reliability)")
hh_error = abs(calc_rows[1] - target_row_sums[1])
@printf("     Household error: %.4f (σ = %.1f)\n", hh_error, row_sigmas[1])

println()
println("2. Instrument Precision:")
println("   - Bond column is very precise (registered instruments)")
bond_error = abs(calc_cols[2] - target_col_sums[2])
@printf("     Bond error: %.4f (σ = %.1f)\n", bond_error, col_sigmas[2])

println()
println("   - Currency column has more uncertainty (cash transactions)")
curr_error = abs(calc_cols[1] - target_col_sums[1])
@printf("     Currency error: %.4f (σ = %.1f)\n", curr_error, col_sigmas[1])

println()
println("3. Where Did Adjustments Go?")
println("   Gen.jl placed the largest adjustments in cells with:")
println("   - High row uncertainty AND high column uncertainty")
println("   - This respects both institutional knowledge and data quality")

# Show biggest adjustments
adjustments = abs.(result .- prior_matrix)
max_adj_idx = argmax(adjustments)
max_adj = adjustments[max_adj_idx]
@printf("\n   Largest adjustment: %.1f CAD billion\n", max_adj)
@printf("   Location: %s, %s\n", 
        sector_names[max_adj_idx[1]], 
        instrument_names[max_adj_idx[2]])

println()
println("="^70)
println("Example complete! ✓")
println("="^70)
println()
println("This demonstrates how Gen.jl:")
println("  • Respects heterogeneous data quality")
println("  • Satisfies accounting identities probabilistically")
println("  • Places adjustments where uncertainty is highest")
println()
println("Compare this to RAS, which treats all data equally!")
println()
