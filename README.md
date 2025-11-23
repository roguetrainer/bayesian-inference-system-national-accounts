# Probabilistic National Accounts Balancing with Gen.jl

A novel application of probabilistic programming to System of National Accounts (SNA) data balancing, demonstrating how modern machine learning tools can enhance traditional econometric and statistical methods used by national statistical agencies.

## What is This?

This package implements probabilistic balancing of flow-of-funds matrices using Gen.jl, MIT's programmable probabilistic programming system. It provides a principled alternative to traditional methods like RAS (bi-proportional scaling) by:

- **Respecting heterogeneous data quality**: Trust administrative data more than survey data
- **Quantifying uncertainty**: Get confidence intervals, not just point estimates
- **Incorporating domain knowledge**: Encode structural constraints and institutional facts
- **Detecting anomalies**: Identify suspicious data points automatically

## Why Does This Matter?

National statistical agencies like Statistics Canada face a fundamental challenge: data from different sources (surveys, administrative records, regulatory reports) rarely agree perfectly, yet must be reconciled to produce internally consistent national accounts that respect fundamental economic identities.

While probabilistic programming has transformed fields like computer vision and robotics, it remains virtually unknown in official statistics—partly because most statistical agencies don't use Julia, and partly because novel methods take time to diffuse into practice.

**This package demonstrates that advanced probabilistic tools can meaningfully improve national accounts work.**

## Quick Start

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/gen-sna-package.git
cd gen-sna-package

# Install dependencies
bash setup.sh
```

### Python Dependencies (RAS baseline)
```bash
pip install -r requirements.txt
```

### Julia Dependencies (Gen.jl probabilistic approach)
```bash
julia --project=. -e 'using Pkg; Pkg.instantiate()'
```

## Basic Usage

### RAS Balancing (Traditional Method)

```python
import numpy as np
from src.ras_balancing import ras_balance

# Preliminary estimates from surveys
noisy_matrix = np.array([
    [150.0, 50.0, 200.0, 300.0],  # Households
    [100.0, 100.0, 100.0, 50.0],   # Corporations
    [50.0, 200.0, 50.0, 0.0],      # Government
    [20.0, 100.0, 50.0, 10.0]      # Rest of World
])

# Target totals from administrative data
row_totals = np.array([1000.0, 500.0, 300.0, 200.0])
col_totals = np.array([400.0, 600.0, 500.0, 500.0])

# Balance the matrix
balanced = ras_balance(noisy_matrix, row_totals, col_totals)
print(balanced)
```

### Gen.jl Probabilistic Balancing

```julia
using Gen
include("src/gen_balancing.jl")

# Same preliminary data
prior_matrix = [
    150.0 50.0 200.0 300.0;
    100.0 100.0 100.0 50.0;
    50.0 200.0 50.0 0.0;
    20.0 100.0 50.0 10.0
]

# Target totals
target_rows = [1000.0, 500.0, 300.0, 200.0]
target_cols = [400.0, 600.0, 500.0, 500.0]

# SPECIFY DATA QUALITY (Gen's advantage!)
# Households: survey data, less reliable
# Government: administrative data, very reliable
row_sigmas = [10.0, 5.0, 0.1, 5.0]
col_sigmas = [10.0, 0.1, 5.0, 5.0]

# Run probabilistic inference
balanced_matrix = gen_balance(
    prior_matrix, 
    target_rows, target_cols,
    row_sigmas, col_sigmas
)
```

## Key Differences: RAS vs. Gen

| Feature | RAS | Gen.jl |
|---------|-----|--------|
| Speed | Very fast (< 1 sec) | Slower (~ 1-10 sec) |
| Treats all data equally | Yes | No - specify reliability |
| Uncertainty estimates | No | Yes - full posterior |
| Encoding constraints | Row/col sums only | Arbitrary constraints |
| Anomaly detection | Manual | Automatic via likelihood |
| Learning curve | Gentle | Steeper |

## Package Contents

```
gen-sna-package/
├── src/
│   ├── ras_balancing.py           # Traditional RAS in Python
│   ├── gen_balancing.jl           # Probabilistic Gen.jl
│   ├── canada_data.py             # StatsCan data utilities
│   └── comparison_utils.jl        # Compare methods
├── notebooks/
│   ├── 01_introduction.ipynb      # Start here!
│   ├── 02_ras_method.ipynb        # RAS deep dive
│   ├── 03_gen_balancing.ipynb     # Gen.jl tutorial
│   ├── 04_comparison.ipynb        # RAS vs Gen
│   ├── 05_uncertainty.ipynb       # Confidence intervals
│   └── 06_anomalies.ipynb         # Detecting outliers
├── examples/
│   ├── simple_balance.jl          # Minimal example
│   ├── quarterly_series.jl        # Multi-period balancing
│   └── heterogeneous_reliability.jl
├── docs/
│   ├── OVERVIEW.md                # Comprehensive guide
│   ├── THEORY.md                  # Mathematical foundations
│   └── STATSCAN_DATA.md           # Using Canadian data
└── tests/
    └── test_balancing.jl
```

## Notebooks Tour

### 1. Introduction (`01_introduction.ipynb`)
- What is national accounts balancing?
- The problem with heterogeneous data sources
- Why probabilistic programming helps

### 2. RAS Method (`02_ras_method.ipynb`)
- History of bi-proportional scaling
- Mathematical derivation
- Worked example with Canadian data
- When RAS works well (and when it doesn't)

### 3. Gen.jl Balancing (`03_gen_balancing.ipynb`)
- Introduction to probabilistic programming
- Building a generative model for flow-of-funds
- Encoding accounting identities as constraints
- Running inference with MAP optimization

### 4. Comparison (`04_comparison.ipynb`)
- Side-by-side: RAS vs. Gen on same data
- Scenarios where they agree
- Scenarios where they diverge (and why)
- Computational performance comparison

### 5. Uncertainty Quantification (`05_uncertainty.ipynb`)
- Getting confidence intervals from Gen
- How uncertainty varies by data quality
- Communicating uncertainty to policymakers

### 6. Anomaly Detection (`06_anomalies.ipynb`)
- Using log-likelihood for outlier detection
- Identifying suspicious transactions
- Case studies from hypothetical Canadian data

## Core Concepts Explained

### System of National Accounts (SNA)
The SNA is the internationally standardized framework for measuring economic activity. It's essentially double-entry bookkeeping for an entire economy, ensuring that:
- Production = Income = Expenditure (GDP identity)
- Every financial asset is someone's liability
- Stocks (balance sheets) and flows (transactions) are consistent

Statistics Canada maintains the Canadian System of National Economic Accounts, publishing quarterly GDP, national balance sheets, and financial flow accounts.

### Stock-Flow Consistent (SFC) Models
SFC models enforce rigorous accounting between balance sheets (stocks) and transactions (flows). Pioneered by economist Wynne Godley, they're used primarily by post-Keynesian economists who emphasize the role of finance and sectoral balance sheets in macroeconomic dynamics.

Key principle: If household debt rises, someone else's financial assets must rise by the same amount. The question is: who, and what does that imply for stability?

### Transaction Matrix / Flow-of-Funds
A matrix showing financial transactions between sectors. Rows and columns both represent uses and sources of funds. In a balanced matrix:
- Row sums = net lending (+) or borrowing (-) by sector
- Column sums = net issuance (+) or retirement (-) of instruments
- Grand sum = 0 (closed economy) or current account balance (open economy)

### RAS Method (Bi-proportional Scaling)
The traditional workhorse algorithm, developed by Nobel laureate Richard Stone in the 1960s. Iteratively scales rows and columns to hit target sums while minimizing proportional adjustments.

Strengths: Fast, simple, always converges
Weaknesses: Treats all data equally, no uncertainty quantification

### Gen.jl and Probabilistic Programming
Gen.jl, developed at MIT, allows you to write custom probabilistic models and custom inference algorithms. Unlike "black-box" systems (Stan, PyMC), Gen gives you fine-grained control over how inference happens.

For national accounts, this means:
- Model data quality explicitly (σ parameters)
- Encode structural knowledge (priors)
- Get posterior distributions (uncertainty)
- Detect anomalies (likelihood)

## Example Use Cases

### 1. Heterogeneous Data Quality
**Problem**: Household survey data chronically underreports wealth (people forget accounts, refuse to answer, or don't know values). Government balance sheets are precise.

**RAS Solution**: Scales everything proportionally, including the reliable government data.

**Gen Solution**: Specify `row_uncertainty[households] = 10.0` and `row_uncertainty[government] = 0.1`. Inference adjusts household data much more than government data.

### 2. Structural Constraints  
**Problem**: You know from institutional facts that banks hold 95%+ of residential mortgages. But preliminary data shows households with significant mortgage *assets* (impossible—they have mortgage *liabilities*).

**RAS Solution**: No way to encode this knowledge. Will balance around whatever data you give it.

**Gen Solution**: Add a structural prior:
```julia
# Household mortgage assets should be ~0
{:cells => (households, mortgages)} ~ normal(0, 1.0)
# Bank mortgage assets should be ~total
{:cells => (banks, mortgages)} ~ normal(mortgage_total, 10.0)
```

### 3. Uncertainty Quantification
**Problem**: The Finance Minister asks, "What's the 95% confidence interval for household net worth?"

**RAS Solution**: Produces a single point estimate. Estimating uncertainty requires running many scenarios manually or using separate statistical methods.

**Gen Solution**: The posterior distribution directly provides this:
```julia
traces = mcmc_inference(model, observations, 1000)
household_wealth = [sum(tr[:cells => (1, :)]) for tr in traces]
ci = quantile(household_wealth, [0.025, 0.975])
```

### 4. Anomaly Detection
**Problem**: Household holdings of corporate bonds jumped 500% quarter-over-quarter. Is this real or a data error?

**RAS Solution**: Balances the matrix regardless. You'd need to manually check the cell and investigate.

**Gen Solution**: The log-likelihood of the trace tells you how surprising this data is:
```julia
if get_score(trace) < threshold
    println("Warning: anomaly detected in cell (1, 2)")
end
```

## Theoretical Foundations

### The Mathematical Connection
Both RAS and Gen aim to solve:
**Find balanced matrix B that is "close" to prior matrix A and satisfies constraints**

**RAS formulation** (constrained optimization):
```
minimize: Σᵢⱼ Bᵢⱼ log(Bᵢⱼ / Aᵢⱼ)  [KL divergence]
subject to: Σⱼ Bᵢⱼ = rᵢ  [row constraints]
            Σᵢ Bᵢⱼ = cⱼ  [column constraints]
```

**Gen formulation** (Bayesian inference):
```
Prior: Bᵢⱼ ~ Normal(Aᵢⱼ, σₚ)
Likelihood: rᵢ ~ Normal(Σⱼ Bᵢⱼ, σᵣ)
            cⱼ ~ Normal(Σᵢ Bᵢⱼ, σc)
Infer: P(B | r, c, A) [posterior distribution]
```

The key difference: RAS treats constraints as hard (must satisfy exactly), while Gen treats them as soft (weighted by uncertainty).

When all σᵣ, σc → 0 and you use MAP estimation, Gen converges to something similar to RAS. But Gen's flexibility allows for much richer models.

## Real-World Applications

### At Statistics Canada
StatsCan produces quarterly National Economic Accounts, including:
- **Provincial and Territorial GDP**: How much does each province produce?
- **National Balance Sheet**: Who owns what assets and owes what liabilities?
- **Financial Flow Accounts**: How do funds flow between sectors?

These estimates combine:
- Surveys (businesses, households, government)
- Administrative data (tax records, regulatory filings)
- Model-based estimates (residuals, imputations)

Currently, StatsCan uses a mix of RAS, other balancing methods, and expert judgment. This package demonstrates how probabilistic programming could complement these methods.

### In Economic Research
Post-Keynesian economists build detailed SFC models calibrated to national accounts data. Examples:
- Modeling the effects of fiscal policy on sectoral balance sheets
- Understanding the build-up of household debt
- Analyzing the sustainability of current account deficits

These models often have 50+ equations and 20+ sectors. Calibrating them while respecting accounting identities is difficult. Gen.jl could help estimate parameters while maintaining consistency.

## Performance Considerations

**RAS**: Extremely fast. Balances a 10×10 matrix in milliseconds. Suitable for production systems processing hundreds of tables daily.

**Gen.jl**: Slower. The same matrix might take seconds (MAP optimization) to minutes (full MCMC). Suitable for:
- Research and development
- Monthly/quarterly analysis where runtime is less critical
- Cases where uncertainty quantification justifies the cost
- Checking RAS results on important tables

**Optimization tips** for Gen:
- Use MAP estimation (faster) for point estimates
- Use importance sampling (medium) for approximate posteriors
- Use MCMC (slower) only when full posterior is essential
- Parallelize over multiple CPUs/GPUs
- Warm-start from previous period's results

## Limitations and Future Work

### Current Limitations
1. **Computational cost**: Slower than RAS for routine production
2. **Complexity**: Requires more expertise to implement
3. **Software ecosystem**: Julia is less common in statistical agencies than R/Python/SAS
4. **Limited precedent**: No established best practices for this application

### Future Directions
1. **Whom-to-whom estimation**: Infer bilateral financial flows (who lent to whom?)
2. **Time-series models**: Jointly balance multiple quarters with smoothness constraints
3. **Hierarchical models**: Provincial accounts that aggregate to national accounts
4. **Online learning**: Update posteriors as new data arrives (nowcasting)
5. **Integration with SFC models**: Use Gen to calibrate behavioral parameters
6. **Production optimization**: Make it fast enough for operational use
7. **User interfaces**: Build tools for non-programmers

## Contributing

We welcome contributions! Areas where help would be particularly valuable:
- Additional examples with real Statistics Canada data
- Comparison with other balancing methods (Stone, Denton, etc.)
- Optimization and performance improvements
- Documentation and tutorials
- Translation of concepts for practitioners

## Citation

If you use this package in research, please cite:

```bibtex
@software{gen_sna_2024,
  title = {Probabilistic National Accounts Balancing with Gen.jl},
  author = {[Your Name]},
  year = {2024},
  url = {https://github.com/yourusername/gen-sna-package}
}
```

## License

MIT License - see LICENSE file for details.

## Acknowledgments

- **MIT Probabilistic Computing Project**: For developing Gen.jl and BayesDB
- **Wynne Godley**: For pioneering stock-flow consistent modeling
- **Richard Stone**: For developing the RAS method and founding modern national accounts
- **Statistics Canada**: For maintaining high-quality, publicly accessible national accounts data

## Learn More

- **Gen.jl Documentation**: https://www.gen.dev/
- **Statistics Canada National Accounts**: https://www23.statcan.gc.ca/
- **Godley & Lavoie (2007)**: *Monetary Economics* (the SFC modeling bible)
- **Stone (1961)**: *Input-Output and National Accounts*

## Support

- **Documentation**: See `docs/` folder for detailed guides
- **Issues**: Open an issue on GitHub
- **Discussions**: Use GitHub Discussions for questions

---

**Note**: This is a research prototype demonstrating the potential of probabilistic programming for national accounts. It is not production-ready software for use in official statistics without further validation and testing.

*"In economics, if your numbers don't add up, your theory is wrong."* — Wynne Godley
