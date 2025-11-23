import numpy as np
import pandas as pd

def ras_balance(matrix, target_row_sums, target_col_sums, tolerance=1e-6, max_iter=1000):
    """
    Balances a matrix using Bi-proportional Scaling (RAS).
    matrix: The initial noisy estimate (interior).
    target_row_sums: The reliable totals for rows (e.g., Total Sector Assets).
    target_col_sums: The reliable totals for cols (e.g., Total Instrument Issuance).
    """
    balanced = matrix.copy()
    rows, cols = balanced.shape
    
    for iteration in range(max_iter):
        # 1. Row Scaling (R step)
        current_row_sums = balanced.sum(axis=1)
        # Avoid division by zero
        r_scalers = np.divide(target_row_sums, current_row_sums, 
                              out=np.ones_like(target_row_sums), 
                              where=current_row_sums!=0)
        # Broadcast multiplication across rows
        balanced = balanced * r_scalers[:, np.newaxis]
        
        # 2. Column Scaling (S step)
        current_col_sums = balanced.sum(axis=0)
        s_scalers = np.divide(target_col_sums, current_col_sums, 
                              out=np.ones_like(target_col_sums), 
                              where=current_col_sums!=0)
        # Broadcast multiplication across columns
        balanced = balanced * s_scalers
        
        # Check convergence
        row_diff = np.abs(balanced.sum(axis=1) - target_row_sums).sum()
        col_diff = np.abs(balanced.sum(axis=0) - target_col_sums).sum()
        
        if row_diff + col_diff < tolerance:
            print(f"RAS Converged in {iteration} iterations.")
            return balanced
            
    print("RAS reached max iterations.")
    return balanced

# --- SYNTHETIC DATA (Based on StatsCan National Balance Sheet) ---
# Sectors: Households, Non-Fin Corps, Gov, Non-Residents
# Instruments: Cash, Bonds, Shares, Mortgages

# 1. The "Target" Totals (High Reliability Admin Data)
# Total Assets per Sector
row_totals = np.array([1000.0, 500.0, 300.0, 200.0]) 
# Total Value per Instrument
col_totals = np.array([400.0, 600.0, 500.0, 500.0])

# 2. The "Noisy" Survey Data (Interior)
# This data implies totals that DO NOT match the targets above.
noisy_matrix = np.array([
    [150.0, 50.0,  200.0, 300.0], # Households (Sum=700, Target=1000) - Big underreporting!
    [100.0, 100.0, 100.0, 50.0],  # Corps
    [50.0,  200.0, 50.0,  0.0],   # Gov
    [20.0,  100.0, 50.0,  10.0]   # Non-Residents
])

# Run RAS
balanced_matrix = ras_balance(noisy_matrix, row_totals, col_totals)

# Output Results
df = pd.DataFrame(balanced_matrix, 
                  columns=["Cash", "Bonds", "Shares", "Mtgs"],
                  index=["HH", "Corp", "Gov", "ROW"])
print("\n--- RAS Balanced Matrix ---")
print(df.round(2))