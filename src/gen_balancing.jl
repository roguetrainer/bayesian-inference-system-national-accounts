using Gen
using LinearAlgebra
using Printf

# --- 1. The Probabilistic Model ---
@gen function flow_of_funds_model(prior_matrix::Matrix{Float64}, 
                                  row_uncertainty::Vector{Float64}, 
                                  col_uncertainty::Vector{Float64})
    
    rows, cols = size(prior_matrix)
    
    # LATENT STATE: The "True" Balanced Matrix
    # We model the true value of each cell.
    # We assume the prior guess is the survey data, but it has wide variance.
    true_matrix = zeros(rows, cols)
    
    for r in 1:rows
        for c in 1:cols
            # We define the "prior" for the cell. 
            # We use a truncated normal because assets cannot be negative.
            # The {:cells => (r, c)} address lets us infer this value.
            true_matrix[r, c] = {:cells => (r, c)} ~ normal(prior_matrix[r, c], prior_matrix[r,c] * 0.5) 
        end
    end
    
    # ACCOUNTING IDENTITIES (The "Physics")
    # We compute the sums of our "True" matrix
    calc_row_sums = sum(true_matrix, dims=2)[:]
    calc_col_sums = sum(true_matrix, dims=1)[:]
    
    # MEASUREMENT MODEL (The Constraints)
    # In RAS, these must match perfectly. In Gen, we treat the "Target Totals" 
    # as noisy observations of the true sums.
    
    # We observe the Row Totals (Sector Wealth)
    for r in 1:rows
        # Sigma varies! Gov data (r=3) might be stricter than Household data (r=1)
        {:row_targets => r} ~ normal(calc_row_sums[r], row_uncertainty[r])
    end
    
    # We observe the Col Totals (Instrument Supply)
    for c in 1:cols
        {:col_targets => c} ~ normal(calc_col_sums[c], col_uncertainty[c])
    end
    
    return true_matrix
end

# --- 2. Setup Data (Same as Python Example) ---
rows, cols = 4, 4

# The "Noisy" Survey Data (Interior)
prior_matrix = [
    150.0 50.0  200.0 300.0; # Households (Implied 700)
    100.0 100.0 100.0 50.0;  # Corps
    50.0  200.0 50.0  0.0;   # Gov
    20.0  100.0 50.0  10.0   # ROW
]

# The Targets (Admin Data)
# Note: Grand sum is 2000.0
target_row_sums = [1000.0, 500.0, 300.0, 200.0] 
target_col_sums = [400.0, 600.0, 500.0, 500.0]

# --- 3. Define Reliability (The Gen Advantage) ---
# RAS implicitly assumes all constraints are equally hard.
# In Gen, we can specify that we trust Gov data more than Household data.

# Variance for Sector Totals (Lower = Harder Constraint)
# Households (1) are messy; Gov (3) is precise.
row_sigmas = [10.0, 5.0, 0.1, 5.0] 

# Variance for Instrument Totals
# Cash (1) is hard to track; Bonds (2) are registered and precise.
col_sigmas = [10.0, 0.1, 5.0, 5.0]

# --- 4. Inference ---

# Create Observations (The Constraints)
observations = choicemap()
for r in 1:rows
    observations[:row_targets => r] = target_row_sums[r]
end
for c in 1:cols
    observations[:col_targets => c] = target_col_sums[c]
end

# Initial Trace
# We initialize the latent cells with the noisy data to give the optimizer a good start
init_params = choicemap()
for r in 1:rows
    for c in 1:cols
        init_params[:cells => (r, c)] = prior_matrix[r, c]
    end
end

# Run MAP Estimation (Optimization)
# We want the single most likely matrix that satisfies our "weighted" constraints
(trace, _) = generate(flow_of_funds_model, (prior_matrix, row_sigmas, col_sigmas), init_params)

# We use MAP optimization to shift the cells to satisfy the constraints
# This is analogous to the iterative scaling in RAS, but guided by probability
for i in 1:5000
    (trace, _) = map_optimize(trace, selection=select(:cells))
end

# --- 5. Output ---
result = get_retval(trace)

println("--- Gen.jl Balanced Matrix ---")
sectors = ["HH", "Corp", "Gov", "ROW"]
cols_names = ["Cash", "Bonds", "Shares", "Mtgs"]

@printf("%-6s", "Sec")
for name in cols_names
    @printf("%10s", name)
end
println()

for r in 1:rows
    @printf("%-6s", sectors[r])
    for c in 1:cols
        @printf("%10.2f", result[r,c])
    end
    println()
end

println("\n--- Verification of Constraints ---")
calc_rows = sum(result, dims=2)[:]
println("Gov Target: $(target_row_sums[3]) | Gen Result: $(round(calc_rows[3], digits=3)) (Should be very close)")
println("HH Target : $(target_row_sums[1]) | Gen Result: $(round(calc_rows[1], digits=3)) (Allowed to drift slightly)")