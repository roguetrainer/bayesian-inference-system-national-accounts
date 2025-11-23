# Gen-SNA Package Summary

## Package Contents

This package demonstrates probabilistic national accounts balancing using Gen.jl and Canadian (StatsCan-style) data.

## Files Included

### Core Documentation
- **README.md** - Main introduction and usage guide
- **docs/OVERVIEW.md** - Comprehensive explanation of concepts:
  - System of National Accounts (SNA)
  - Stock-Flow Consistent (SFC) models  
  - BayesDB and Gen.jl
  - RAS method
  - Post-Keynesian economics and Wynne Godley
  - Whom-to-Whom matrices and accounting integrity
  - Why this application is novel

### Source Code

#### Python Files (`src/`)
- **ras_balancing.py** - Traditional RAS (bi-proportional scaling) implementation
- **canada_data.py** - Utilities for generating StatsCan-style data

#### Julia Files (`src/`)
- **gen_balancing.jl** - Probabilistic balancing with Gen.jl
- **comparison_utils.jl** - Tools to compare RAS vs Gen.jl methods

### Examples
- **examples/simple_balance.jl** - Minimal working example with Canadian data

### Notebooks
- **notebooks/01_introduction.ipynb** - Interactive introduction to the problem and methods

### Configuration
- **requirements.txt** - Python dependencies
- **Project.toml** - Julia dependencies  
- **setup.sh** - Automated installation script
- **LICENSE** - MIT License
- **.gitignore** - Version control configuration

## Key Concepts Explained

### System of National Accounts (SNA)
The internationally standardized framework for measuring economic activity. Like double-entry bookkeeping for an entire economy, ensuring:
- Production = Income = Expenditure (GDP identity)
- Every financial asset is someone's liability
- Stocks and flows are consistent

**Statistics Canada** maintains the Canadian System of National Economic Accounts with quarterly data on GDP, National Balance Sheet, and Financial Flow Accounts.

### Stock-Flow Consistent (SFC) Models
Macroeconomic models that enforce rigorous accounting identities between balance sheets (stocks) and transactions (flows). Pioneered by **Wynne Godley** (1926-2010), a Cambridge economist who predicted the 2008 crisis by tracking unsustainable household debt.

SFC models are primarily used by **post-Keynesian economists** (heterodox school) who emphasize:
- Money and finance matter for real economy
- Sectoral balances are key (households ≠ firms ≠ government)
- Accounting identities are economic constraints

**Key distinction**: Unlike mainstream DSGE models, post-Keynesians take national accounts data seriously and build detailed sectoral models calibrated to actual financial flows.

### Transaction Matrix / Flow-of-Funds Matrix
Shows financial transactions between sectors (rows) and instruments (columns):
- Row sums = net lending/borrowing by sector
- Column sums = net issuance by instrument type
- **"Whom-to-Whom"**: Ideally tracks bilateral flows (who lent to whom?)
- **"Accounting Integrity"**: All identities must hold exactly

### RAS Method (Bi-proportional Scaling)
The traditional algorithm developed by **Richard Stone** (Nobel laureate) in the 1960s:
- Iteratively scale rows and columns to match target sums
- Fast and simple
- **Limitation**: Treats all data sources equally, no uncertainty quantification

### BayesDB
MIT Probabilistic Computing Project's system for probabilistic SQL queries:
- `INFER` missing values
- `SIMULATE` synthetic data  
- `ESTIMATE PROBABILITY` for anomaly detection
- Uses CrossCat (Bayesian nonparametric model)

**Limitation for national accounts**: Generic model doesn't encode accounting identities.

### Gen.jl
MIT's programmable probabilistic programming system:
- Write custom generative models
- Specify data quality explicitly (σ parameters)
- Get posterior distributions (uncertainty quantification)
- Incorporate domain knowledge (structural priors)
- Detect anomalies via likelihood

**Advantage for national accounts**: Can encode accounting identities as probabilistic constraints while respecting heterogeneous data quality.

## Why This Matters

### Novel Application
Advanced statistical tools like probabilistic programming have revolutionized computer vision and robotics, but **have not reached statistical agencies**. Reasons:
- Institutional inertia
- Statistical agencies use SAS/R/Python, not Julia
- Methods take time to diffuse from research to practice

**This package demonstrates**: Probabilistic programming can meaningfully improve national accounts work while respecting existing domain knowledge.

### The Data Quality Problem
National accounts data comes from multiple sources:
- **Administrative data** (tax, regulatory): High reliability, incomplete coverage
- **Survey data** (households, businesses): Comprehensive, but noisy
- **Derived estimates** (residuals): Necessary evil

These sources **never agree perfectly**, requiring reconciliation to enforce accounting identities.

### RAS Limitation
RAS adjusts all cells proportionally without considering:
- Which data sources are more reliable
- Structural facts (e.g., banks hold most mortgages)
- Uncertainty in final estimates

### Gen.jl Solution
Explicitly model data quality:
```julia
# Government data: very reliable
row_uncertainty[government] = 0.1

# Household survey: less reliable  
row_uncertainty[households] = 10.0
```

Inference concentrates adjustments where uncertainty is highest.

## Getting Started

### Installation
```bash
chmod +x setup.sh
./setup.sh
```

### Quick Test
```bash
# Python (RAS)
python3 src/ras_balancing.py

# Julia (Gen.jl)
julia --project=. src/gen_balancing.jl

# Simple example
julia --project=. examples/simple_balance.jl
```

### Interactive Tutorial
```bash
jupyter notebook notebooks/01_introduction.ipynb
```

## Example Workflow

1. **Load Canadian data**: Use `canada_data.py` utilities
2. **Run RAS baseline**: Traditional bi-proportional scaling
3. **Run Gen.jl**: Probabilistic balancing with quality weights
4. **Compare results**: Where do methods differ and why?
5. **Analyze uncertainty**: Extract confidence intervals
6. **Detect anomalies**: Identify suspicious data points

## References

### National Accounts
- United Nations (2009). *System of National Accounts 2008*
- Statistics Canada: www23.statcan.gc.ca

### SFC Modeling
- **Godley & Lavoie (2007)**. *Monetary Economics: An Integrated Approach*
- Caverzasi & Godin (2015). "Post-Keynesian stock-flow-consistent modelling: a survey"

### RAS & Balancing
- **Stone (1961)**. *Input-Output and National Accounts*
- Bacharach (1970). *Biproportional Matrices*

### Probabilistic Programming
- **Cusumano-Towner et al. (2019)**. "Gen: A General-Purpose Probabilistic Programming System"
- Mansinghka et al. (2015). "BayesDB: A Probabilistic Programming System"

## Key Insight

> *"The most important thing we can know about economic relationships is the structure of financial claims. Show me the balance sheets, and I will tell you where the crisis will come from."*  
> — Wynne Godley (paraphrased)

The post-Keynesian tradition recognizes that **sectoral financial balances** are critical for understanding macroeconomic stability. When one sector (e.g., households) accumulates debt rapidly, another must accumulate assets. Understanding the **whom-to-whom** structure reveals fragilities that aggregate models miss.

This package shows how modern probabilistic tools can enhance the analysis of these crucial accounting relationships.

## License

MIT License - see LICENSE file

## Contact

For questions or contributions, please open an issue on GitHub.

---

**Created**: November 2024  
**Purpose**: Demonstrate probabilistic programming for national accounts  
**Status**: Research prototype (not production-ready)
