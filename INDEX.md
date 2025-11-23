# Gen-SNA Package: Complete Contents

## Download

- **[gen-sna-package.tar.gz](computer:///mnt/user-data/outputs/gen-sna-package.tar.gz)** - Complete package archive
- **[gen-sna-package/](computer:///mnt/user-data/outputs/gen-sna-package/)** - Uncompressed package directory

## What's Inside

### 📚 Documentation

1. **[README.md](computer:///mnt/user-data/outputs/gen-sna-package/README.md)**  
   Main introduction, installation instructions, and usage guide

2. **[PACKAGE_SUMMARY.md](computer:///mnt/user-data/outputs/gen-sna-package/PACKAGE_SUMMARY.md)**  
   Quick reference summary of all concepts

3. **[docs/OVERVIEW.md](computer:///mnt/user-data/outputs/gen-sna-package/docs/OVERVIEW.md)**  
   Comprehensive guide covering:
   - System of National Accounts (SNA)
   - Stock-Flow Consistent (SFC) models
   - Wynne Godley and post-Keynesian economics
   - Transaction matrices and whom-to-whom flows
   - Accounting integrity principles
   - BayesDB probabilistic databases
   - Gen.jl probabilistic programming
   - RAS (bi-proportional scaling) method
   - Why this is a novel application

### 💻 Source Code

#### Python Files
- **[src/ras_balancing.py](computer:///mnt/user-data/outputs/gen-sna-package/src/ras_balancing.py)**  
  Traditional RAS algorithm implementation

- **[src/canada_data.py](computer:///mnt/user-data/outputs/gen-sna-package/src/canada_data.py)**  
  Utilities for generating Statistics Canada-style national accounts data

#### Julia Files
- **[src/gen_balancing.jl](computer:///mnt/user-data/outputs/gen-sna-package/src/gen_balancing.jl)**  
  Probabilistic balancing using Gen.jl

- **[src/comparison_utils.jl](computer:///mnt/user-data/outputs/gen-sna-package/src/comparison_utils.jl)**  
  Functions to compare RAS vs Gen.jl results

### 📓 Jupyter Notebook

- **[notebooks/01_introduction.ipynb](computer:///mnt/user-data/outputs/gen-sna-package/notebooks/01_introduction.ipynb)**  
  Interactive tutorial covering:
  - The national accounts balancing problem
  - Working with Canadian data
  - Running RAS method
  - Understanding Gen.jl advantages
  - Visualizing results

### 🎯 Examples

- **[examples/simple_balance.jl](computer:///mnt/user-data/outputs/gen-sna-package/examples/simple_balance.jl)**  
  Minimal working example with Canadian flow-of-funds data

### ⚙️ Configuration

- **[requirements.txt](computer:///mnt/user-data/outputs/gen-sna-package/requirements.txt)** - Python dependencies
- **[Project.toml](computer:///mnt/user-data/outputs/gen-sna-package/Project.toml)** - Julia dependencies
- **[setup.sh](computer:///mnt/user-data/outputs/gen-sna-package/setup.sh)** - Automated installation script
- **[LICENSE](computer:///mnt/user-data/outputs/gen-sna-package/LICENSE)** - MIT License

## Key Concepts Explained

### System of National Accounts (SNA)
International standard for measuring economic activity - essentially double-entry bookkeeping for an entire economy. Statistics Canada maintains quarterly accounts for GDP, balance sheets, and financial flows.

### Stock-Flow Consistent (SFC) Models
Macroeconomic models enforcing rigorous accounting between stocks (balance sheets) and flows (transactions). Pioneered by **Wynne Godley**, who used sectoral financial balances to predict the 2008 crisis.

### Post-Keynesian Economics
Heterodox school emphasizing:
- Money and finance are central (not neutral)
- Sectoral behavior matters (don't aggregate everything)
- Accounting identities are economic constraints
- National accounts data reveals fragilities

**Key insight**: Unlike mainstream economics, post-Keynesians take the System of National Accounts seriously as the foundation for understanding macroeconomic dynamics.

### The Balancing Problem
National accounts data comes from multiple sources with different reliability:
- Administrative data (tax, regulatory): High quality, incomplete
- Survey data: Comprehensive, noisy
- Derived estimates: Gap-filling, uncertain

These sources never agree perfectly, requiring reconciliation while preserving accounting identities.

### RAS Method
Traditional algorithm (Richard Stone, 1960s):
- Iteratively scale rows and columns
- Fast and simple
- **Limitation**: Treats all data equally

### Gen.jl Solution
Probabilistic programming approach:
- Model data quality explicitly (σ parameters)
- Concentrate adjustments in high-uncertainty cells
- Provide confidence intervals
- Incorporate institutional knowledge
- Detect anomalies automatically

## Why This Is Novel

To our knowledge, this is the **first application of programmable probabilistic inference to national accounts balancing**.

While probabilistic programming has transformed fields like computer vision and robotics, it remains virtually unknown in official statistics - partly because statistical agencies don't use Julia, and partly because diffusion of methods takes time.

This package demonstrates that these advanced tools can meaningfully improve traditional statistical work.

## Quick Start

```bash
# Extract package
tar -xzf gen-sna-package.tar.gz
cd gen-sna-package

# Install dependencies
chmod +x setup.sh
./setup.sh

# Run examples
python3 src/ras_balancing.py
julia --project=. examples/simple_balance.jl

# Open notebook
jupyter notebook notebooks/01_introduction.ipynb
```

## Use Cases

1. **Heterogeneous data quality**: Trust government data more than surveys
2. **Structural constraints**: Encode facts like "banks hold most mortgages"
3. **Uncertainty quantification**: Get confidence intervals for estimates
4. **Anomaly detection**: Automatically flag suspicious data
5. **Time-series balancing**: Jointly balance multiple periods with smoothness
6. **Research**: Calibrate SFC models to data while respecting identities

## References

### Essential Readings
- **Godley & Lavoie (2007)**: *Monetary Economics* - The SFC modeling bible
- **Stone (1961)**: *Input-Output and National Accounts* - Origins of RAS
- **Cusumano-Towner et al. (2019)**: "Gen: A General-Purpose Probabilistic Programming System"
- **Statistics Canada**: National Economic Accounts documentation

### The Post-Keynesian Tradition
The economists who care most about national accounts data:
- **Wynne Godley** (1926-2010): Stock-flow consistent modeling pioneer
- **Hyman Minsky**: Financial instability hypothesis
- **Marc Lavoie**: Monetary circuit theory
- **Stephanie Kelton**: Modern Monetary Theory popularizer

These economists argue that sectoral financial balances (who owes what to whom) are crucial for understanding economic stability - a perspective that requires careful attention to national accounts data.

## Next Steps

1. Read **docs/OVERVIEW.md** for comprehensive background
2. Work through **notebooks/01_introduction.ipynb** interactively
3. Run **examples/simple_balance.jl** to see Gen.jl in action
4. Compare RAS and Gen.jl results on your own data
5. Explore uncertainty quantification and anomaly detection

## License

MIT License - Free to use, modify, and distribute

## Status

Research prototype demonstrating the potential of probabilistic programming for national accounts. Not production-ready without further validation and testing.

---

**Created for**: Economic researchers, statistical agencies, post-Keynesian modelers  
**Demonstrates**: Novel application of Gen.jl to national accounts  
**Emphasizes**: Heterogeneous data quality, uncertainty quantification, domain knowledge

*"Show me the balance sheets, and I will tell you where the crisis will come from."* - Wynne Godley
