I'm excited to share a new project that bridges probabilistic programming and economics - specifically applying Gen.jl (MIT's probabilistic programming system) to national accounts balancing.

Most economists don't realize that when statistical agencies like Statistics Canada compile GDP and balance sheet data, they face a fundamental challenge: data from different sources (surveys, tax records, regulatory filings) rarely agrees perfectly. The traditional solution - RAS bi-proportional scaling from the 1960s - treats all data sources equally, even though we know household surveys are much noisier than government administrative records.

This project demonstrates how probabilistic programming can help by explicitly modeling data quality. Instead of mechanically scaling numbers to make them add up, we can say "trust this government data more" (small variance) and "this survey data less" (large variance), and let Bayesian inference figure out where adjustments should go.

The irony is striking: while probabilistic programming has transformed computer vision, robotics, and machine learning over the past decade, it remains virtually unknown in economics and official statistics. This isn't because it wouldn't be useful - it's because novel methods take time to diffuse across disciplines, and because statistical agencies understandably stick with established workflows.

As Wynne Godley (who predicted the 2008 crisis by carefully tracking sectoral balance sheets) said: "Show me the balance sheets, and I will tell you where the crisis will come from." The post-Keynesian tradition he helped build recognizes that who owes what to whom matters enormously for understanding economic fragility. 

We have incredibly powerful tools for reasoning under uncertainty and incorporating domain knowledge. Economics - especially the granular work of compiling national accounts that underpin all macroeconomic analysis - could benefit tremendously. The bridge between Bayesian inference and economic measurement deserves more attention.

The code (Python & Julia), examples using Canadian data, and extensive documentation on Stock-Flow Consistent modeling are all available. Would love to hear from others working at this intersection of statistics, economics, and probabilistic methods.