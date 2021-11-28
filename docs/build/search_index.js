var documenterSearchIndex = {"docs":
[{"location":"IV-2SLS examples/","page":"IV/2SLS examples","title":"IV/2SLS examples","text":"##IV/2SLS examples","category":"page"},{"location":"IV-2SLS examples/","page":"IV/2SLS examples","title":"IV/2SLS examples","text":"# specify exactly identified model: regress wage on on tenure, instrumented by union,\r\n# controlling for ttl_exp and collgrad\r\nd = download(\"http://www.stata-press.com/data/r8/nlsw88.dta\", tempname() * \".dta\")\r\ndf = DataFrame(load(d))[:, [:wage; :tenure; :ttl_exp; :collgrad; :industry; :union]]\r\ndropmissing!(df)\r\nf = @formula(wage ~ 1 + ttl_exp + collgrad)\r\nf = apply_schema(f, schema(f, df))\r\nresp, predexog = modelcols(f, df)\r\nivf = @formula(tenure ~ union)\r\nivf = apply_schema(ivf, schema(ivf, df))\r\npredendog, inst = modelcols(ivf, df)\r\n\r\n# test that coefficient on tenure = 0, clustering errors by industry\r\nR = [0 0 0 1]; r = [0]\r\nwildboottest(R, r; resp, predexog, predendog, inst, clustid=df.industry)\r\n\r\n# use equal-tailed instead of symmetric p value\r\nwildboottest(R, r; resp, predexog, predendog, inst, clustid=df.industry, ptype=WildBootTests.equaltail)\r\n\r\n# perform bootstrap-c instead of bootstrap-t, as advocated by Young (2019)\r\nwildboottest(R, r; resp, predexog, predendog, inst, clustid=df.industry, bootstrapc=true)\r\n\r\n# Rao/score test without bootstrap\r\nwildboottest(R, r; resp, predexog, predendog, inst, clustid=df.industry, reps=0)\r\n\r\n# Wald test without bootstrap\r\nwildboottest(R, r; resp, predexog, predendog, inst, clustid=df.industry, reps=0, imposenull=false)\r\n\r\n# Anderson-Rubin test that hypothesis holds and instrument is valid\r\nwildboottest(R, r; resp, predexog, predendog, inst, clustid=df.industry, ARubin=true)\r\n\r\n# modify model to drop controls and make ttl_exp an instrument\r\nf = @formula(wage ~ 1)\r\nf = apply_schema(f, schema(f, df))\r\nresp, predexog = modelcols(f, df)\r\nivf = @formula(tenure ~ collgrad + ttl_exp)\r\nivf = apply_schema(ivf, schema(ivf, df))\r\npredendog, inst = modelcols(ivf, df)\r\n\r\n# test same hypothesis in context of LIML regression\r\nR = [0 1]; r = [0]\r\nwildboottest(R, r; resp, predexog, predendog, inst, LIML=true, clustid=df.industry)","category":"page"},{"location":"OLS examples/#Example-with-full-session-log","page":"OLS examples","title":"Example with full session log","text":"","category":"section"},{"location":"OLS examples/","page":"OLS examples","title":"OLS examples","text":"julia> using WildBootTests, CSV, DataFrames, GLM, Plots\r\n\r\njulia> d = download(\"https://raw.github.com/vincentarelbundock/Rdatasets/master/csv/sandwich/PetersenCL.csv\");\r\n\r\njulia> df = CSV.read(d, DataFrame);\r\n\r\njulia> f = @formula(y ~ 1 + x);  # state OLS model\r\n\r\njulia> f = apply_schema(f, schema(f, df));  # link model to data\r\n\r\njulia> lm(f, df)  # run OLS for illustration; not needed for following lines\r\nStatsModels.TableRegressionModel{LinearModel{GLM.LmResp{Vector{Float64}}, GLM.DensePredChol{Float64, LinearAlgebra.CholeskyPivoted{Float64, Matrix{Float64}}}}, Matrix{Float64}}\r\n\r\ny ~ 1 + x\r\n\r\nCoefficients:\r\n─────────────────────────────────────────────────────────────────────────\r\n                 Coef.  Std. Error      t  Pr(>|t|)  Lower 95%  Upper 95%\r\n─────────────────────────────────────────────────────────────────────────\r\n(Intercept)  0.0296797   0.0283593   1.05    0.2954  -0.025917  0.0852764\r\nx            1.03483     0.0285833  36.20    <1e-99   0.978798  1.09087\r\n─────────────────────────────────────────────────────────────────────────\r\n\r\njulia> resp, predexog = modelcols(f, df);  # extract response & (exogenous) predictor variables\r\n\r\njulia> clustid = df.firm;  # extract clustering variable\r\n\r\njulia> R = [0 1]; r = [1];  # put null that coefficient on x = 1 in Rβ = r form, where β is parameter vector\r\n\r\njulia> test = wildboottest(R, r; resp=resp, predexog=predexog, clustid=clustid)\r\nWildBootTests.BoottestResult{Float32}\r\n\r\np  = 0.492\r\nCI = Float32[0.93461335 1.1347668]\r\n\r\njulia> test = wildboottest(R, r; resp, predexog, clustid);  # same, using Julia syntactic sugar\r\n\r\njulia> p(test)  # programmatically extract p value\r\n0.49459493f0\r\n\r\njulia> CI(test)  # programmatically extract confidence interval\r\n1×2 Matrix{Float32}:\r\n 0.934961  1.13469\r\n\r\njulia> plot(plotpoints(test)...)  # plot confidence curve","category":"page"},{"location":"OLS examples/#Further-examples","page":"OLS examples","title":"Further examples","text":"","category":"section"},{"location":"OLS examples/","page":"OLS examples","title":"OLS examples","text":"# use Webb instead of Rademacher weights, 99,999 bootstrap replications instead of 999\r\nwildboottest(R, r; resp, predexog, clustid, reps=99999, auxwttype=WildBootTests.webb)\r\n\r\n# bootstrap in double-precision (Float64) instead of single (Float32)\r\n# slow on first use because of recompile\r\nwildboottest(Float64, R, r; resp, predexog, clustid)\r\n\r\n# use guaranteed-stable random number generator for exact replicability\r\nusing StableRNGs\r\nwildboottest(R, r; resp, predexog, clustid, rng=StableRNG(23948572))\r\n\r\n# test that coefficient on intercept = 0 and coefficient on x = 1; plot confidence surface\r\ntest = wildboottest([1 0; 0 1], [0;1]; resp, predexog, clustid, reps=9999)\r\nplot(plotpoints(test).X..., plotpoints(test).p, st=:contourf)\r\n\r\n# multiway-cluster errors by firm and year; bootstrap by firm\r\nwildboottest(R, r; resp, predexog, clustid=Matrix(df[:,[:firm, :year]]), nerrclustvar=2, nbootclustvar=1)\r\n\r\n# same but bootstrap by year\r\nwildboottest(R, r; resp, predexog, clustid=Matrix(df[:,[:year, :firm]]), nerrclustvar=2, nbootclustvar=1)\r\n\r\n# same but bootstrap by year-firm pair\r\nwildboottest(R, r; resp, predexog, clustid=Matrix(df[:,[:year, :firm]]), nerrclustvar=2, nbootclustvar=2)\r\n\r\n# Rao/score test with multiway clustering of errors but no bootstrap\r\nwildboottest(R, r; resp, predexog, predendog, inst, Matrix(df[:,[:year, :firm]]), reps=0)\r\n\r\n# Same but Wald test: i.e., conventional, multiway clustered errors\r\nwildboottest(R, r; resp, predexog, predendog, inst, clustid=Matrix(df[:,[:year, :firm]]), reps=0, imposenull=false)\r\n\r\n# add year fixed effects to model; cluster by firm\r\nwildboottest(R, r; resp, predexog, feid=df.year, clustid=df.firm)\r\n\r\n# test hypotheses, while imposing model constraint that constant term = 0.2\r\nR1 = [1 0]; r1 = [.2]\r\nwildboottest(R, r; R1, r1, resp, predexog, clustid=df.firm)","category":"page"},{"location":"exported/","page":"Public functions and types","title":"Public functions and types","text":"wildboottest\r\nAuxWtType\r\nPType\r\nMAdjType\r\nDistStatType\r\nteststat\r\nstattype\r\np\r\npadj\r\nreps\r\nrepsfeas\r\nNBootClust\r\ndof\r\ndof_r\r\nplotpoints\r\npeak\r\nCI\r\ndist\r\nstatnumer\r\nstatvar\r\nauxweights","category":"page"},{"location":"exported/#WildBootTests.wildboottest","page":"Public functions and types","title":"WildBootTests.wildboottest","text":"wildboottest([T::DataType=Float32,] R::AbstractMatrix, r::AbstractVector;               resp, <optional keyword arguments>) -> WildBootTest.BoottestResult\n\nFunction to perform wild-bootstrap-based hypothesis test\n\nPositional arguments\n\nT::DataType: data type for inputs, results, and computations: Float32 (default) or Float64\nR::AbstractMatrix and r::AbstractVector: required matrix and vector expressesing the null Rβ=r; see Notes\n\nRequired keyword argument\n\nresp::AbstractVector: response/dependent variable (y/y₁)\n\nOptional keyword arguments\n\npredexog::AbstractVecOrMat: exogenous predictors, including constant term, if any (X/X₁)\npredendog::AbstractVecOrMat: endogenous predictors (Y₂)\ninst::AbstractVecOrMat: instruments (X₂)\nR1::AbstractMatrix and r1::AbstractVector: model constraints; same format as for R and r\nclustid::AbstractVecOrMat{<:Integer}: data vector/matrix of error and bootstrapping cluster identifiers; see Notes \nnbootclustvar::Integer=1: number of bootstrap-clustering variables\nnerrclustvar::Integer=nbootclustvar: number of error-clustering variables\nhetrobust::Bool=true: true unless errors are treated as iid\nfeid::AbstractVector{<:Integer}: data vector for fixed effect group identifier\nfedfadj::Bool=true: true if small-sample adjustment should reflect number of fixed effects\nobswt::AbstractVector: observation weight vector; default is equal weighting\nfweights::Bool=false: true for frequency weights\nmaxmatsize::Number: maximum size of auxilliary weight matrix (v), in gigabytes\nptype::PType=symmetric: p value type (symmetric, equaltail, lower, upper)\nbootstrapc::Bool=false: true for bootstrap-c\nLIML::Bool=false: true for LIML or Fuller LIML\nFuller::Number: Fuller factor\nκ::Number: fixed κ for k-class estimation\nARubin::Bool=false: true for Anderson-Rubin test\nsmall::Bool=true: true for small-sample corrections\nscorebs::Bool=false: true for score bootstrap instead of wild bootstrap\nreps::Integer=999: number of bootstrap replications; reps = 0 requests classical Rao (or Wald) test if imposenull = true (or false)\nimposenull::Bool=true: true to impose null\nauxwttype::AuxWtType=rademacher: auxilliary weight type (rademacher, mammen, webb, normal, gamma)\nrng::AbstractRNG=MersenneTwister(): randon number generator\nlevel::Number=.95: significance level (0-1)\nrtol::Number=1e-6: tolerance for CI bound determination\nmadjtype::MAdjType=nomadj: multiple hypothesis adjustment (nomadj, bonferroni, sidak)\nNH₀::Integer=1: number of hypotheses tested, including one being tested now\nML::Bool=false: true for (nonlinear) ML estimation\nscores::AbstractVecOrMat: for ML, pre-computed scores\nβ::AbstractVector: for ML, parameter estimates\nA::AbstractMatrix: for ML, covariance estimates\ngridmin: vector of graph lower bounds, max length 2, missing entries ask wildboottest() to choose\ngridmax: vector of graph upper bounds\ngridpoints: vector of number of sampling points\ndiststat::DistStatType=nodiststat: t to save bootstrap distribution of Wald/χ²/F/t statistics; numer to save numerators thereof\ngetCI::Bool=true: whether to return CI\ngetplot::Bool=getCI: whether to generate plot data\ngetauxweights::Bool=false: whether to save auxilliary weight matrix (v)\n\nNotes\n\nThe columns of R in the statement of the null should correspond to those of the matrix [predexog predendog], where predendog is non-empty only in instrumental variables regression. \n\nOrder the columns of clustid this way:\n\nVariables only used to define bootstrapping clusters, as in the subcluster bootstrap.\nVariables used to define both bootstrapping and error clusters.\nVariables only used to define error clusters.\n\nIn the most common case, clustid is a single column of type 2.\n\nThe code does not handle missing data values: all data and identifier matrices must  be restricted to the estimation sample.\n\n\n\n\n\n","category":"function"},{"location":"exported/#WildBootTests.AuxWtType","page":"Public functions and types","title":"WildBootTests.AuxWtType","text":"Auxilliary weight types: rademacher, mammen, webb, normal, gamma\n\n\n\n\n\n","category":"type"},{"location":"exported/#WildBootTests.PType","page":"Public functions and types","title":"WildBootTests.PType","text":"p value types: symmetric, equaltail, lower, upper\n\n\n\n\n\n","category":"type"},{"location":"exported/#WildBootTests.MAdjType","page":"Public functions and types","title":"WildBootTests.MAdjType","text":"Multiple hypothesis adjustment types: nomadj, bonferroni, sidak\n\n\n\n\n\n","category":"type"},{"location":"exported/#WildBootTests.DistStatType","page":"Public functions and types","title":"WildBootTests.DistStatType","text":"Bootstrap distribution statistics optionally returned\n\n\n\n\n\n","category":"type"},{"location":"exported/#WildBootTests.teststat","page":"Public functions and types","title":"WildBootTests.teststat","text":"Return test statistic subject to wild bootstrap test\n\n\n\n\n\n","category":"function"},{"location":"exported/#WildBootTests.stattype","page":"Public functions and types","title":"WildBootTests.stattype","text":"Return type of test statistic subject to wild bootstrap test: \"t\", \"z\", \"F\", or \"χ²\" \n\n\n\n\n\n","category":"function"},{"location":"exported/#WildBootTests.p","page":"Public functions and types","title":"WildBootTests.p","text":"Return p value from wild bootstrap test\n\n\n\n\n\n","category":"function"},{"location":"exported/#WildBootTests.padj","page":"Public functions and types","title":"WildBootTests.padj","text":"Returnp p value from wild bootstrap test after multiple-hypothesis adjustment, if any\n\n\n\n\n\n","category":"function"},{"location":"exported/#WildBootTests.reps","page":"Public functions and types","title":"WildBootTests.reps","text":"Return requested number of replications in wild bootstrap test\n\n\n\n\n\n","category":"function"},{"location":"exported/#WildBootTests.repsfeas","page":"Public functions and types","title":"WildBootTests.repsfeas","text":"Return actual number of replications in wild bootstrap test, subject to enumeration of Rademacher draws\n\n\n\n\n\n","category":"function"},{"location":"exported/#WildBootTests.NBootClust","page":"Public functions and types","title":"WildBootTests.NBootClust","text":"Return number of bootstrapping clusters in wild bootstrap test\n\n\n\n\n\n","category":"function"},{"location":"exported/#WildBootTests.dof","page":"Public functions and types","title":"WildBootTests.dof","text":"Return degrees of freedom wild bootstrap test\n\n\n\n\n\n","category":"function"},{"location":"exported/#WildBootTests.dof_r","page":"Public functions and types","title":"WildBootTests.dof_r","text":"Return residual degrees of freedom wild bootstrap test\n\n\n\n\n\n","category":"function"},{"location":"exported/#WildBootTests.plotpoints","page":"Public functions and types","title":"WildBootTests.plotpoints","text":"Return data for confidence plot of wild bootstrap test. Return value is a 2-tuple with named entries X and p holding the confidence sampling locations and p values respectively. X is in turn a 1- or 2-tuple of vectors of sampling coordinates for each  dimension of the tested hypothesis.\n\n\n\n\n\n","category":"function"},{"location":"exported/#WildBootTests.peak","page":"Public functions and types","title":"WildBootTests.peak","text":"Return parameter value with peak p value in wild bootstrap test\n\n\n\n\n\n","category":"function"},{"location":"exported/#WildBootTests.CI","page":"Public functions and types","title":"WildBootTests.CI","text":"Return confidence interval matrix from wild bootstrap test, one row per disjoint piece\n\n\n\n\n\n","category":"function"},{"location":"exported/#WildBootTests.dist","page":"Public functions and types","title":"WildBootTests.dist","text":"Return bootstrap distribution of statistic or statistic numerator in wild bootstrap test\n\n\n\n\n\n","category":"function"},{"location":"exported/#WildBootTests.statnumer","page":"Public functions and types","title":"WildBootTests.statnumer","text":"Return numerator of test statistic in wild bootstrap test\n\n\n\n\n\n","category":"function"},{"location":"exported/#WildBootTests.statvar","page":"Public functions and types","title":"WildBootTests.statvar","text":"Return denominator of test statistic in wild bootstrap test\n\n\n\n\n\n","category":"function"},{"location":"exported/#WildBootTests.auxweights","page":"Public functions and types","title":"WildBootTests.auxweights","text":"Return auxilliary weight matrix for wild bootstrap\n\n\n\n\n\n","category":"function"},{"location":"","page":"Overview","title":"Overview","text":"WildBootTests.jl performs wild bootstrap-based hypothesis tests at extreme speed. It is intended mainly for linear models: ordinary least squares (OLS) and instrumental variables/two-stage least squares (IV/2SLS). For an introduction to the wild bootstrap and the algorithms deployed here, see Roodman et al. (2019).","category":"page"},{"location":"","page":"Overview","title":"Overview","text":"The package offers and/or supports:","category":"page"},{"location":"","page":"Overview","title":"Overview","text":"The wild bootstrap for OLS (Wu 1986).\nThe Wild Restricted Efficient bootstrap (WRE) for IV/2SLS/LIML (Davidson and MacKinnon 2010).\nThe subcluster bootstrap (MacKinnon and Webb 2018).\nNon-bootstrapped Wald, Rao, and Anderson-Rubin tests, optionally with multiway clustering.\nConfidence intervals formed by inverting the test and iteratively searching for bounds.\nMultiway clustering.\nArbitrary and multiple linear hypotheses in the parameters.\nMaintained linear constraints on the model (restricted OLS, IV/2SLS/LIML).\nOne-way fixed effects.\nGeneration of data for plotting of confidence curves or surfaces after one- or two-dimensional hypothesis tests.","category":"page"},{"location":"","page":"Overview","title":"Overview","text":"WildBootTests.jl incorporates order-of-magnitude algorithmic speed-ups developed since Roodman et al. (2019) for OLS and IV/2SLS. And it exploits the efficiency of Julia, for example by offering single-precision (Float32) computation.","category":"page"},{"location":"","page":"Overview","title":"Overview","text":"The interface is low-level: the exported function wildboottest() accepts scalars, vectors, and matrices, not DataFrames or results from estimation functions such as lm(). This design minimizes the package's dependency footprint while making the core functionality available to multiple programming environments, including Julia, R (through JuliaConnectoR), and Python (through PyJulia). A separate package will provide a higher-level Julia interface.","category":"page"},{"location":"","page":"Overview","title":"Overview","text":"wildboottest() accepts many optional arguments. Most correspond to options of the Stata package boottest, which are documented in Roodman et al. (2019), §7. Julia-specific additions include an optional first argument T, which can be Float32 or Float64 to specify the precision of computation; and rng, which takes a random number generator such as MersenneTwister(2302394).","category":"page"}]
}
