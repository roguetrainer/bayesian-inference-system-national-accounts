# Probabilistic National Accounts Balancing with Gen.jl

## Overview

This package demonstrates a novel application of advanced probabilistic programming techniques to the System of National Accounts (SNA), specifically using Gen.jl to balance flow-of-funds matrices with uncertainty quantification. To our knowledge, this represents the first application of programmable probabilistic inference to national accounts data.

## Why This Matters

While sophisticated statistical tools like probabilistic programming have revolutionized fields like computer vision, robotics, and machine learning, they have rarely found their way into the toolboxes of working national accountants and government statisticians. This is partly due to institutional inertia, but also because many advanced tools are built in languages like Julia that aren't widely adopted in statistical agencies (which predominantly use SAS, R, and increasingly Python).

This package bridges that gap, demonstrating how probabilistic programming can enhance traditional national accounts work while respecting the deep domain knowledge embedded in existing practices.

---

## Core Concepts

### 1. System of National Accounts (SNA)

The **System of National Accounts** is an internationally agreed standard system of macroeconomic accounts that provide a comprehensive, consistent, and flexible framework for economic decision-making. Think of it as the "double-entry bookkeeping" of an entire economy.

The SNA organizes economic data into several key accounts:
- **Production accounts**: What industries produce
- **Income accounts**: How income is distributed
- **Capital accounts**: Investment and saving
- **Financial accounts**: Who owes what to whom (flow-of-funds)
- **Balance sheets**: Stock of assets and liabilities

**Key principle**: Every transaction must be recorded twice. When a household buys a bond, this appears as:
- A decrease in household cash assets (negative)
- An increase in household bond holdings (positive)
- An increase in government bond liabilities (if it's a government bond)

This "accounting integrity" ensures internal consistency.

#### Statistics Canada and the Canadian System of National Accounts

Statistics Canada maintains the Canadian System of National Economic Accounts, producing quarterly and annual estimates of:
- GDP (production, income, and expenditure approaches)
- National Balance Sheet (sectoral wealth)
- Flow of Funds (financial transactions between sectors)
- Input-Output tables (inter-industry transactions)

The data used in this package mirrors the structure of StatsCan's National Balance Sheet and Financial Flow Accounts.

### 2. Stock-Flow Consistent (SFC) Models

**Stock-Flow Consistent models** are a class of macroeconomic models that enforce rigorous accounting identities between stocks (balance sheets) and flows (transactions). They ensure that:

1. Every financial asset is someone's liability
2. Flows of funds add up to changes in stocks
3. No money appears or disappears mysteriously

The SFC approach was pioneered by economists like **Wynne Godley** (1926-2010), a British economist who worked at the Cambridge Department of Applied Economics and later at the Levy Economics Institute. Godley was famous for predicting economic crises (including the 2008 financial crisis) by identifying unsustainable trends in sectoral financial balances.

SFC models are primarily used by **post-Keynesian economists**, a heterodox school that emphasizes:
- The role of money and finance in the economy
- Fundamental uncertainty (not just risk)
- The importance of institutional detail
- Sector-specific behavior (households ≠ firms ≠ government)

This contrasts with mainstream Dynamic Stochastic General Equilibrium (DSGE) models, which often abstract away from financial details and sectoral distinctions.

**Key insight**: SFC models view the economy as a network of financial claims. When one sector runs a surplus, another must run a deficit. Understanding *which* sectors are accumulating wealth or debt is crucial for predicting instability.

### 3. Transaction Matrix and Flow-of-Funds Matrix

A **Transaction Matrix** (or Social Accounting Matrix) shows all transactions in the economy in a period, organized so that:
- Rows represent receipts (income, asset sales)
- Columns represent expenditures (purchases, investments)
- Row sums equal column sums (income = expenditure for each sector)

A **Flow-of-Funds Matrix** is more specific: it shows financial transactions between sectors. Here's a simplified example:

```
              Assets Acquired (Uses of Funds)
            | Cash  | Bonds | Equities | Mortgages | Σ
--------------------------------------------------------
Households  |  +50  |  +100 |   +200   |   -300    | +50
Corps       |  +30  |   -50 |    +20   |   +200    | +200
Government  |   -80 |  +200 |    -50   |     0     | +70
Banks       |   0   | -250  |   -170   |   +100    | -320
--------------------------------------------------------
Σ           |   0   |    0  |      0   |      0    | 0
```

**Key features**:
- **Column sums = 0**: Every instrument has a buyer and a seller
- **Row sums = net lending/borrowing**: Households saved $50M, banks borrowed $320M
- **"Whom-to-Whom"**: Not just "households bought bonds," but ideally "households bought government bonds"

In practice, detailed whom-to-whom data is rare. Most statistical agencies know:
- How much cash each sector holds (from surveys)
- Total cash in circulation (from central bank)

But matching specific holders to specific issuers is difficult.

### 4. Accounting Integrity and the Balancing Problem

**Accounting integrity** means that the data respects fundamental identities:
- Assets = Liabilities + Net Worth (for each sector)
- Total financial assets = Total financial liabilities (for the economy)
- Changes in stocks = Flows (for each instrument and sector)

The problem: Data comes from multiple sources with different reliability:
- **Administrative data** (tax records, regulatory filings): High reliability, but incomplete
- **Survey data** (household surveys, business surveys): Comprehensive, but noisy
- **Derived estimates** (residuals, modeling): Necessary, but uncertain

These sources rarely agree. Household surveys typically **underreport wealth** (people forget accounts, understate values, or refuse to answer). Administrative data on bond issuance is precise, but doesn't tell us who bought them.

**The balancing problem**: Adjust the initial estimates to satisfy accounting identities while respecting data quality.

### 5. The RAS Method (Bi-proportional Scaling)

The **RAS algorithm** is the workhorse of national accounts balancing. Named after its creators Richard Stone (Nobel laureate) and his collaborators in the 1960s, it solves:

**Given**:
- A matrix A (preliminary estimates)
- Target row sums r (e.g., total assets by sector)
- Target column sums c (e.g., total issuance by instrument)

**Find**: A balanced matrix B such that:
- Row sums of B equal r
- Column sums of B equal c
- B is "as close as possible" to A (in a specific sense)

**How it works**:
1. **R step**: Scale each row to match target row sums
2. **A step**: The original matrix (starting point)
3. **S step**: Scale each column to match target column sums
4. Repeat until convergence

**Mathematical formulation**:
```
B = R̂ · A · Ŝ
```
where R̂ and Ŝ are diagonal matrices of scaling factors.

**Advantages**:
- Simple, fast, always converges
- Preserves zero entries (if Aᵢⱼ = 0, then Bᵢⱼ = 0)
- Well-understood mathematical properties

**Limitations**:
1. **Treats all data equally**: Can't say "Trust government data more than household surveys"
2. **No uncertainty quantification**: Produces a single balanced matrix, no confidence intervals
3. **Proportional adjustments**: If households underreport by 30%, RAS scales up all household assets by 30%, even if the error is concentrated in specific instruments (e.g., cash holdings)
4. **No structural knowledge**: Can't incorporate domain expertise like "mortgage liabilities of households ≈ mortgage assets of banks"

### 6. BayesDB: Probabilistic Databases

**BayesDB** was developed by the MIT Probabilistic Computing Project (led by Vikash Mansinghka) as a research system for querying databases with uncertainty. The key idea: extend SQL with probabilistic queries.

Traditional SQL:
```sql
SELECT AVG(salary) FROM employees WHERE age > 30
```

BayesDB (BQL):
```sql
INFER salary FROM employees WHERE age = 25 LIMIT 10
```

This query doesn't just look up data—it generates plausible values based on patterns in the data.

**Core capabilities**:
- **INFER**: Generate likely values for missing or unobserved data
- **SIMULATE**: Generate synthetic datasets from learned patterns
- **ESTIMATE PROBABILITY**: Detect anomalies (low-probability rows)
- **ESTIMATE DEPENDENCE PROBABILITY**: Find predictive relationships between columns

**Under the hood**: BayesDB uses CrossCat, a Bayesian nonparametric model that:
- Clusters columns (which variables are related?)
- Clusters rows within column groups (which records are similar?)
- Makes predictions based on these clusters

**Example application to national accounts**:
- "INFER household_wealth WHERE province = 'Newfoundland' AND year = 2019" (missing data imputation)
- "ESTIMATE DEPENDENCE PROBABILITY OF mortgage_debt WITH housing_prices" (finding relationships)
- "SIMULATE 1000 FROM financial_flows WHERE sector = 'Households'" (scenario analysis)

**Limitations for national accounts**:
- CrossCat is a generic model; doesn't encode accounting identities
- Designed for heterogeneous tabular data, not structured matrices
- No built-in support for "whom-to-whom" constraints

### 7. Gen.jl: Programmable Probabilistic Programming

**Gen.jl** is a probabilistic programming system developed at MIT (by the same group behind BayesDB) that takes a different approach. Instead of providing a fixed inference algorithm, Gen gives you building blocks to write custom inference.

**Philosophy**: 
- You know your domain (e.g., accounting identities in economics)
- You should be able to encode that knowledge
- One-size-fits-all inference often fails on complex problems

**Key features**:

1. **Generative functions** (`@gen`): Define how data is generated
   ```julia
   @gen function model(x)
       slope ~ normal(0, 1)
       intercept ~ normal(0, 1)
       y ~ normal(slope * x + intercept, 0.1)
       return y
   end
   ```

2. **Traces**: Records of random choices
   - Every `~` creates an addressable random choice
   - Can be queried, constrained, or optimized

3. **Choice maps**: Specify observations
   ```julia
   observations = choicemap()
   observations[:y] = 3.5  # We observed y = 3.5
   ```

4. **Programmable inference**: Mix and match strategies
   - Importance sampling
   - Markov Chain Monte Carlo (MCMC)
   - Sequential Monte Carlo (particle filters)
   - Variational inference
   - Gradient-based optimization (MAP estimation)

**Why Gen for National Accounts?**

Gen excels when you need to:
- Encode complex constraints (accounting identities)
- Specify heterogeneous data quality (trust some sources more than others)
- Propagate uncertainty (not just a point estimate)
- Incorporate structural knowledge (e.g., banks hold most mortgages)

**The Gen approach to balancing**:
1. Model the "true" balanced matrix as latent variables
2. Treat preliminary estimates as noisy observations
3. Encode accounting identities as probabilistic constraints
4. Specify different uncertainty for different data sources
5. Infer the posterior distribution over balanced matrices

This is fundamentally different from RAS:
- **RAS**: Mechanical adjustment to satisfy constraints
- **Gen**: Bayesian inference over the true state given noisy measurements

---

## Comparison: RAS vs. Gen.jl

| Aspect | RAS | Gen.jl |
|--------|-----|--------|
| **Philosophy** | Algorithmic adjustment | Probabilistic inference |
| **Data quality** | All sources equal | Different uncertainty per source |
| **Output** | Single balanced matrix | Posterior distribution (with uncertainty) |
| **Constraints** | Hard constraints (must satisfy exactly) | Soft constraints (weighted by uncertainty) |
| **Domain knowledge** | Only via choosing targets | Fully customizable model |
| **Computational cost** | Very fast (seconds) | Slower (minutes for complex models) |
| **Implementation** | Few lines of code | More complex setup |
| **Interpretability** | Scaling factors | Probabilistic narrative |
| **Anomaly detection** | Not built-in | Natural via likelihood |

**When to use RAS**:
- Routine production work with tight deadlines
- Simple balancing problems with homogeneous data quality
- Well-established workflows
- When uncertainty quantification isn't needed

**When to use Gen**:
- Experimental analysis with heterogeneous data sources
- Need for uncertainty quantification (confidence intervals)
- Complex constraints beyond row/column sums
- Want to incorporate structural economic knowledge
- Research and development of new methods

---

## The Gen.jl Advantage for National Accounts

### 1. Heterogeneous Data Quality

**Scenario**: You're balancing a flow-of-funds matrix for Canada. You have:
- **Household surveys**: Comprehensive but notoriously unreliable for wealth
- **Tax data**: Precise for taxable instruments (bonds, dividends) but incomplete
- **Regulatory data**: Perfect for bank balance sheets
- **Residual estimates**: Used to close gaps, but highly uncertain

**RAS approach**: Treats all cells equally when adjusting.

**Gen approach**: 
```julia
# Trust government balance sheet data (small σ)
row_uncertainty[3] = 0.1  # Government
# Less trust in household surveys (large σ)  
row_uncertainty[1] = 10.0  # Households
```

The inference algorithm will adjust cells with high uncertainty more than those with low uncertainty.

### 2. Structural Constraints

**Scenario**: You know from institutional knowledge that:
- Almost all residential mortgages are held by banks (>95%)
- Households and non-residents hold negligible mortgage assets

**RAS approach**: Can't encode this; might incorrectly inflate household mortgage holdings.

**Gen approach**: Add a structural prior:
```julia
# Mortgages column, households row
{:cells => (1, 4)} ~ normal(0, 1.0)  # Near-zero with tight variance
# Mortgages column, banks row
{:cells => (5, 4)} ~ normal(mortgage_total, 10.0)  # Most mortgages
```

### 3. Uncertainty Quantification

**Scenario**: The Minister asks, "What's our confidence interval for household net worth?"

**RAS approach**: Produces a single number. To get uncertainty, you'd need to:
- Run multiple scenarios manually
- Apply ad-hoc sensitivity analysis
- Use separate statistical methods

**Gen approach**: The posterior distribution gives you this directly:
```julia
# Run 1000 posterior samples
traces = [...]  # from MCMC or importance sampling
household_wealth = [sum(trace[:cells => (1, :)]) for trace in traces]
ci_lower = quantile(household_wealth, 0.025)
ci_upper = quantile(household_wealth, 0.975)
```

### 4. Anomaly Detection

**Scenario**: A data cell seems suspicious—household holdings of foreign bonds jumped 500% year-over-year.

**RAS approach**: Will balance around whatever numbers you give it, no questions asked.

**Gen approach**: The likelihood tells you how surprising this is:
```julia
likelihood = exp(get_score(trace))  # Probability of the data
if likelihood < threshold
    println("Anomaly detected in cell $(r, c)")
end
```

### 5. Temporal Consistency

**Scenario**: You're balancing quarterly data. You want smooth transitions between quarters, not wild swings.

**Gen approach**: Add a time-series component:
```julia
@gen function temporal_model(prior_matrices, T)
    for t in 1:T
        for r in 1:rows, c in 1:cols
            if t == 1
                {:cells => (t, r, c)} ~ normal(prior_matrices[t][r,c], σ)
            else
                # Current value depends on previous value
                prev = {:cells => (t-1, r, c)}
                {:cells => (t, r, c)} ~ normal(prev, σ_transition)
            end
        end
    end
end
```

This enforces smooth evolution over time while still respecting accounting constraints in each period.

---

## Heterodox Economics and SFC Models

While mainstream macroeconomics (New Keynesian DSGE models) tends to abstract from financial detail, **post-Keynesian economics** places finance at the center of analysis. This tradition includes:

- **Hyman Minsky**: Financial instability hypothesis
- **Wynne Godley**: Stock-flow consistent modeling
- **Marc Lavoie**: Monetary circuit theory
- **Stephanie Kelton**: Modern Monetary Theory (MMT) popularization

These economists argue that:
1. **Money is endogenous**: Created by bank lending, not just central bank actions
2. **Finance matters**: Who owes what to whom determines spending
3. **Accounting is economics**: If you don't respect identities, your model is wrong
4. **Sectors behave differently**: You can't aggregate households, firms, government, and banks into a "representative agent"

**Why post-Keynesians care about SNA data**:
- The sectoral financial balances (S - I by sector) are key to understanding instability
- Rising private debt often precedes crises (Godley predicted the 2008 crisis by observing unsustainable household debt growth)
- SFC models can be calibrated to national accounts data

**Connection to Gen.jl**: Post-Keynesian SFC models are often **highly detailed** with many sectors, instruments, and behavioral equations. Calibrating these models to data while respecting accounting identities is a perfect use case for probabilistic programming.

---

## Package Contents

This package includes:

### Code Files
- **`src/ras_balancing.py`**: Traditional RAS implementation in Python
- **`src/gen_balancing.jl`**: Probabilistic balancing with Gen.jl
- **`src/canada_data.py`**: Utilities for working with StatsCan-style data
- **`src/comparison_utils.jl`**: Functions to compare RAS vs. Gen results

### Notebooks
- **`notebooks/01_introduction.ipynb`**: Conceptual overview and simple examples
- **`notebooks/02_ras_method.ipynb`**: Deep dive into RAS algorithm
- **`notebooks/03_gen_balancing.ipynb`**: Gen.jl probabilistic approach
- **`notebooks/04_comparison.ipynb`**: Side-by-side RAS vs. Gen analysis
- **`notebooks/05_uncertainty_quantification.ipynb`**: Extracting confidence intervals
- **`notebooks/06_anomaly_detection.ipynb`**: Finding suspicious data points

### Documentation
- **`docs/OVERVIEW.md`**: This file
- **`docs/THEORY.md`**: Mathematical foundations
- **`docs/STATSCAN_DATA.md`**: Guide to Statistics Canada data sources

### Examples
- **`examples/simple_balance.jl`**: Minimal working example
- **`examples/quarterly_series.jl`**: Multi-period balancing
- **`examples/heterogeneous_reliability.jl`**: Different data quality by source

---

## Future Directions

This package demonstrates the potential of probabilistic programming for national accounts, but there's much more to explore:

1. **Whom-to-Whom estimation**: Use network models to infer bilateral financial relationships
2. **Time-series integration**: Jointly balance multiple periods with temporal smoothness
3. **Hierarchical models**: Provincial accounts that sum to national accounts
4. **Integration with SFC models**: Use Gen to calibrate behavioral parameters
5. **Real-time updating**: As new data arrives, update the posterior (online learning)
6. **Comparison with other methods**: Benchmark against Stone's method, Denton method, etc.
7. **Production readiness**: Optimize for speed, create pipelines for statistical agencies

---

## References

### System of National Accounts
- United Nations et al. (2009). *System of National Accounts 2008*. UN.
- Statistics Canada. *National Economic Accounts*. www23.statcan.gc.ca

### Stock-Flow Consistent Modeling  
- Godley, W., & Lavoie, M. (2007). *Monetary Economics: An Integrated Approach to Credit, Money, Income, Production and Wealth*. Palgrave Macmillan.
- Caverzasi, E., & Godin, A. (2015). "Post-Keynesian stock-flow-consistent modelling: a survey". *Cambridge Journal of Economics*, 39(1), 157-187.

### RAS and Balancing Methods
- Stone, R. (1961). *Input-Output and National Accounts*. OECD.
- Bacharach, M. (1970). *Biproportional Matrices and Input-Output Change*. Cambridge University Press.
- Miller, R. E., & Blair, P. D. (2009). *Input-Output Analysis: Foundations and Extensions*. Cambridge University Press.

### Probabilistic Programming
- Cusumano-Towner, M. F., et al. (2019). "Gen: A General-Purpose Probabilistic Programming System with Programmable Inference". *PLDI 2019*.
- Mansinghka, V., et al. (2015). "BayesDB: A Probabilistic Programming System for Querying the Probable Implications of Data". *arXiv:1512.05006*.

### Post-Keynesian Economics
- Minsky, H. (1986). *Stabilizing an Unstable Economy*. Yale University Press.
- Lavoie, M. (2014). *Post-Keynesian Economics: New Foundations*. Edward Elgar.

---

## Acknowledgments

This package builds on the pioneering work of:
- The MIT Probabilistic Computing Project (Vikash Mansinghka, Marco Cusumano-Towner, et al.)
- Wynne Godley and the Cambridge Economic Policy Group  
- Richard Stone and the early national accounts pioneers
- Statistics Canada's methodology research division

## License

MIT License - see LICENSE file for details.

## Contact

For questions, suggestions, or collaboration opportunities, please open an issue on GitHub.

---

*"The most important thing we can know about economic relationships is the structure of financial claims. Show me the balance sheets, and I will tell you where the crisis will come from."* — Wynne Godley (paraphrased)
