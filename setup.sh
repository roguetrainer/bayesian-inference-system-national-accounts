#!/bin/bash

# Setup script for Gen-SNA package
# Probabilistic National Accounts Balancing

set -e  # Exit on error

echo "============================================================"
echo "  Gen-SNA Package Setup"
echo "  Probabilistic National Accounts Balancing"
echo "============================================================"
echo ""

# Check for Python
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is not installed. Please install Python 3.8 or higher."
    exit 1
fi

PYTHON_VERSION=$(python3 --version | cut -d' ' -f2 | cut -d'.' -f1,2)
echo "✓ Found Python $PYTHON_VERSION"

# Check for Julia
if ! command -v julia &> /dev/null; then
    echo "❌ Julia is not installed."
    echo "   Please install Julia 1.9 or higher from https://julialang.org/downloads/"
    exit 1
fi

JULIA_VERSION=$(julia --version | cut -d' ' -f3)
echo "✓ Found Julia $JULIA_VERSION"

echo ""
echo "------------------------------------------------------------"
echo "Installing Python dependencies..."
echo "------------------------------------------------------------"

# Create virtual environment (optional but recommended)
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
source venv/bin/activate

# Upgrade pip
pip install --upgrade pip

# Install requirements
pip install -r requirements.txt

echo "✓ Python dependencies installed"

echo ""
echo "------------------------------------------------------------"
echo "Installing Julia dependencies..."
echo "------------------------------------------------------------"

# Create Julia project if it doesn't exist
if [ ! -f "Project.toml" ]; then
    echo "Creating Julia project..."
    julia --project=. -e 'using Pkg; Pkg.activate(".")'
fi

# Add required Julia packages
julia --project=. -e '
using Pkg
Pkg.activate(".")

println("Adding Gen.jl...")
Pkg.add("Gen")

println("Adding LinearAlgebra...")
# LinearAlgebra is in stdlib, no need to add

println("Adding DataFrames...")
Pkg.add("DataFrames")

println("Adding CSV...")
Pkg.add("CSV")

println("Adding Plots...")
Pkg.add("Plots")

println("Adding StatsPlots...")
Pkg.add("StatsPlots")

println("Adding Statistics...")
# Statistics is in stdlib

println("Adding Printf...")
# Printf is in stdlib

println("Instantiating project...")
Pkg.instantiate()

println("Precompiling packages...")
Pkg.precompile()

println("✓ Julia dependencies installed")
'

echo ""
echo "------------------------------------------------------------"
echo "Running tests..."
echo "------------------------------------------------------------"

# Test Python installation
echo "Testing Python modules..."
python3 -c "
import numpy as np
import pandas as pd
print('  ✓ NumPy version:', np.__version__)
print('  ✓ Pandas version:', pd.__version__)
"

# Test Julia installation
echo ""
echo "Testing Julia packages..."
julia --project=. -e '
using Gen
using DataFrames
using Plots
println("  ✓ Gen.jl loaded successfully")
println("  ✓ DataFrames.jl loaded successfully")
println("  ✓ Plots.jl loaded successfully")
'

echo ""
echo "------------------------------------------------------------"
echo "Testing basic functionality..."
echo "------------------------------------------------------------"

# Test RAS Python implementation
echo "Testing RAS balancing (Python)..."
python3 -c "
import sys
sys.path.insert(0, 'src')
from ras_balancing import ras_balance
import numpy as np

matrix = np.array([[150.0, 50.0], [100.0, 100.0]])
rows = np.array([250.0, 200.0])
cols = np.array([250.0, 200.0])
result = ras_balance(matrix, rows, cols)
print('  ✓ RAS balancing works')
"

# Test Gen.jl implementation
echo ""
echo "Testing Gen.jl balancing..."
julia --project=. -e '
include("src/gen_balancing.jl")
println("  ✓ Gen.jl balancing script loaded successfully")
'

echo ""
echo "============================================================"
echo "  Setup Complete! ✓"
echo "============================================================"
echo ""
echo "Next steps:"
echo ""
echo "  1. Activate Python environment:"
echo "     source venv/bin/activate"
echo ""
echo "  2. Start Jupyter notebook:"
echo "     jupyter notebook notebooks/"
echo ""
echo "  3. Or run examples:"
echo "     python3 src/ras_balancing.py"
echo "     julia --project=. src/gen_balancing.jl"
echo ""
echo "  4. Read the documentation:"
echo "     docs/OVERVIEW.md"
echo ""
echo "Happy balancing! 📊"
echo ""
