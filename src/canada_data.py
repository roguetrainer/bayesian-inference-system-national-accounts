"""
Utilities for working with Statistics Canada-style national accounts data.

This module provides helpers for:
- Loading and structuring flow-of-funds matrices
- Simulating Canadian sector/instrument data
- Visualizing sectoral balance sheets
"""

import numpy as np
import pandas as pd
from typing import Dict, List, Tuple, Optional

# Canadian sectors (following StatsCan conventions)
SECTORS = [
    "Households",
    "Non-Financial Corporations", 
    "Financial Corporations",
    "Government",
    "Non-Residents"
]

# Common financial instruments in Canadian national accounts
INSTRUMENTS = [
    "Currency and Deposits",
    "Debt Securities", 
    "Equity and Investment Fund Shares",
    "Loans",
    "Life Insurance and Pensions",
    "Other Accounts"
]

# Short names for display
SECTORS_SHORT = ["HH", "NFC", "FC", "Gov", "ROW"]
INSTRUMENTS_SHORT = ["Cash", "Bonds", "Equity", "Loans", "Pensions", "Other"]


def create_statscan_matrix(
    sectors: Optional[List[str]] = None,
    instruments: Optional[List[str]] = None
) -> pd.DataFrame:
    """
    Create an empty flow-of-funds matrix with StatsCan-style structure.
    
    Parameters
    ----------
    sectors : list of str, optional
        Sector names. Defaults to Canadian sectors.
    instruments : list of str, optional
        Instrument names. Defaults to common Canadian instruments.
    
    Returns
    -------
    pd.DataFrame
        Empty matrix with sectors as rows, instruments as columns.
    """
    if sectors is None:
        sectors = SECTORS_SHORT
    if instruments is None:
        instruments = INSTRUMENTS_SHORT
    
    return pd.DataFrame(
        np.zeros((len(sectors), len(instruments))),
        index=sectors,
        columns=instruments
    )


def simulate_canadian_fof(
    scale: float = 1000.0,
    noise_level: float = 0.1,
    seed: Optional[int] = None
) -> Tuple[np.ndarray, np.ndarray, np.ndarray]:
    """
    Simulate a realistic Canadian flow-of-funds matrix.
    
    Based on stylized facts from Statistics Canada data:
    - Households: Large holders of equity, deposits, pensions
    - Financial corps: Dominant in loans, insurance products
    - Government: Issues bonds, small equity holdings
    - Non-residents: Diversified portfolio
    
    Parameters
    ----------
    scale : float
        Overall scale of the economy (in billions CAD)
    noise_level : float
        Amount of noise to add to simulate measurement error
    seed : int, optional
        Random seed for reproducibility
        
    Returns
    -------
    noisy_matrix : np.ndarray
        Preliminary estimates with measurement error
    true_row_sums : np.ndarray
        True sector totals (assets)
    true_col_sums : np.ndarray
        True instrument totals (issuance)
    """
    if seed is not None:
        np.random.seed(seed)
    
    # Stylized Canadian flow-of-funds structure
    # Rows: HH, NFC, FC, Gov, ROW
    # Cols: Cash, Bonds, Equity, Loans, Pensions, Other
    
    # True underlying matrix (in billions CAD)
    true_matrix = np.array([
        [100, 50, 300, 20, 400, 80],   # Households: big in equity, pensions
        [80, 100, 200, 150, 50, 70],   # Non-Financial Corps: diverse
        [50, 150, 100, 300, 100, 50],  # Financial Corps: big in loans
        [30, 200, 20, 50, 30, 20],     # Government: issues bonds
        [40, 100, 80, 80, 20, 30]      # Non-Residents: diversified
    ]) * (scale / 1000.0)
    
    # Add measurement error (different by sector and instrument)
    # Households and cash are noisier than government and bonds
    sector_noise = np.array([0.15, 0.10, 0.05, 0.02, 0.08])  # HH noisiest
    instrument_noise = np.array([0.20, 0.05, 0.10, 0.08, 0.12, 0.15])  # Cash noisiest
    
    # Combine noise factors
    noise_matrix = np.outer(sector_noise, instrument_noise) * noise_level
    
    # Generate noisy observations
    noisy_matrix = true_matrix * (1 + np.random.normal(0, 1, true_matrix.shape) * noise_matrix)
    noisy_matrix = np.maximum(noisy_matrix, 0)  # No negative assets
    
    # True totals (these would come from administrative data)
    true_row_sums = true_matrix.sum(axis=1)
    true_col_sums = true_matrix.sum(axis=0)
    
    return noisy_matrix, true_row_sums, true_col_sums


def calculate_sectoral_balances(
    matrix: np.ndarray,
    liabilities: Optional[np.ndarray] = None
) -> pd.DataFrame:
    """
    Calculate sectoral financial balances (net lending/borrowing).
    
    In SFC models, this is the key indicator of financial sustainability.
    A sector's balance = Financial Assets - Financial Liabilities
    
    Parameters
    ----------
    matrix : np.ndarray
        Asset holdings by sector (rows) and instrument (columns)
    liabilities : np.ndarray, optional
        Liability matrix. If None, calculated from asset whom-to-whom structure.
        
    Returns
    -------
    pd.DataFrame
        Sectoral balances showing net lending (+) or borrowing (-)
    """
    assets = matrix.sum(axis=1)
    
    if liabilities is None:
        # Stylized assumption: liabilities proportional to instrument totals
        # In reality, you'd need whom-to-whom data
        total_liabilities = matrix.sum(axis=0)
        # Rough allocation (governments and corps are net borrowers)
        liab_shares = np.array([0.1, 0.3, 0.3, 0.2, 0.1])  # HH, NFC, FC, Gov, ROW
        liabilities = np.outer(liab_shares, total_liabilities).sum(axis=1)
    else:
        liabilities = liabilities.sum(axis=1)
    
    balance = assets - liabilities
    
    return pd.DataFrame({
        'Assets': assets,
        'Liabilities': liabilities,
        'Net_Position': balance
    }, index=SECTORS_SHORT)


def format_matrix_display(
    matrix: np.ndarray,
    sectors: Optional[List[str]] = None,
    instruments: Optional[List[str]] = None,
    title: str = "Flow of Funds Matrix"
) -> str:
    """
    Format a matrix for pretty display with row/column sums.
    
    Parameters
    ----------
    matrix : np.ndarray
        The matrix to display
    sectors : list of str, optional
        Sector labels
    instruments : list of str, optional  
        Instrument labels
    title : str
        Title for the display
        
    Returns
    -------
    str
        Formatted string representation
    """
    if sectors is None:
        sectors = SECTORS_SHORT
    if instruments is None:
        instruments = INSTRUMENTS_SHORT
        
    df = pd.DataFrame(matrix, index=sectors, columns=instruments)
    
    # Add row totals
    df['Total'] = df.sum(axis=1)
    
    # Add column totals
    totals_row = df.sum(axis=0)
    totals_row.name = 'Total'
    df = pd.concat([df, pd.DataFrame([totals_row])])
    
    output = f"\n{'='*60}\n"
    output += f"{title:^60}\n"
    output += f"{'='*60}\n\n"
    output += df.to_string(float_format=lambda x: f"{x:8.1f}")
    output += f"\n\n{'='*60}\n"
    
    return output


def assess_balance_quality(
    matrix: np.ndarray,
    target_row_sums: np.ndarray,
    target_col_sums: np.ndarray
) -> Dict[str, float]:
    """
    Assess how well a matrix satisfies target constraints.
    
    Parameters
    ----------
    matrix : np.ndarray
        Balanced matrix
    target_row_sums : np.ndarray
        Target row totals
    target_col_sums : np.ndarray
        Target column totals
        
    Returns
    -------
    dict
        Quality metrics including max errors and RMS errors
    """
    calc_rows = matrix.sum(axis=1)
    calc_cols = matrix.sum(axis=0)
    
    row_errors = calc_rows - target_row_sums
    col_errors = calc_cols - target_col_sums
    
    metrics = {
        'max_row_error': np.abs(row_errors).max(),
        'max_col_error': np.abs(col_errors).max(),
        'rms_row_error': np.sqrt(np.mean(row_errors**2)),
        'rms_col_error': np.sqrt(np.mean(col_errors**2)),
        'max_row_pct_error': (np.abs(row_errors) / target_row_sums).max() * 100,
        'max_col_pct_error': (np.abs(col_errors) / target_col_sums).max() * 100
    }
    
    return metrics


def generate_quarterly_series(
    n_quarters: int = 8,
    scale: float = 1000.0,
    growth_rate: float = 0.02,
    seed: Optional[int] = None
) -> List[Tuple[np.ndarray, np.ndarray, np.ndarray]]:
    """
    Generate a time series of flow-of-funds matrices.
    
    Simulates realistic quarterly data with:
    - Trend growth
    - Seasonal patterns
    - Measurement error
    
    Parameters
    ----------
    n_quarters : int
        Number of quarters to generate
    scale : float
        Initial scale in billions CAD
    growth_rate : float
        Quarterly growth rate (e.g., 0.02 = 2%)
    seed : int, optional
        Random seed
        
    Returns
    -------
    list of tuples
        Each tuple is (noisy_matrix, target_rows, target_cols) for that quarter
    """
    if seed is not None:
        np.random.seed(seed)
    
    series = []
    current_scale = scale
    
    for q in range(n_quarters):
        # Seasonal adjustment (weak)
        seasonal_factor = 1.0 + 0.03 * np.sin(2 * np.pi * q / 4)
        quarter_scale = current_scale * seasonal_factor
        
        # Generate quarter data
        noisy, rows, cols = simulate_canadian_fof(
            scale=quarter_scale,
            noise_level=0.1,
            seed=seed + q if seed else None
        )
        
        series.append((noisy, rows, cols))
        
        # Grow the economy
        current_scale *= (1 + growth_rate)
    
    return series


# Example usage and testing
if __name__ == "__main__":
    print("Statistics Canada National Accounts Data Utilities\n")
    
    # Simulate Canadian data
    print("Simulating Canadian flow-of-funds data...")
    noisy, row_targets, col_targets = simulate_canadian_fof(scale=2000.0, seed=42)
    
    # Display
    print(format_matrix_display(noisy, title="Preliminary Estimates (Noisy Survey Data)"))
    
    # Show targets
    print("\nTarget Row Sums (Sector Assets from Admin Data):")
    for sector, target in zip(SECTORS_SHORT, row_targets):
        print(f"  {sector:6s}: {target:8.1f}")
    
    print("\nTarget Column Sums (Instrument Issuance from Admin Data):")
    for inst, target in zip(INSTRUMENTS_SHORT, col_targets):
        print(f"  {inst:10s}: {target:8.1f}")
    
    # Calculate balances
    print("\n" + "="*60)
    balances = calculate_sectoral_balances(noisy)
    print("\nSectoral Financial Balances:")
    print(balances.to_string())
    
    print("\nNote: Positive = Net Lender, Negative = Net Borrower")
