var documenterSearchIndex = {"docs":
[{"location":"exported/","page":"Public functions and types","title":"Public functions and types","text":"wildboottest\nteststat\nstattype\np\npadj\nreps\nrepsfeas\nnbootclust\ndof\ndof_r\nplotpoints\npeak\nci\ndist\nstatnumer\nstatvar\nauxweights","category":"page"},{"location":"exported/#WildBootTests.wildboottest","page":"Public functions and types","title":"WildBootTests.wildboottest","text":"wildboottest([T::DataType=Float64,] R::AbstractMatrix, r::AbstractVector;               resp, <optional keyword arguments>) -> WildBootTests.BootTestResult\n\nFunction to perform wild-bootstrap-based hypothesis test\n\nPositional arguments\n\nT::DataType: data type for inputs, results, and computations: Float32 or Float64 (default)\nR::AbstractMatrix and r::AbstractVector: required matrix and vector expressing the null Rβ=r; see notes below\n\nRequired keyword argument\n\nresp::AbstractVector: response/dependent variable (y or y₁ in Roodman et al. (2019))\n\nOptional keyword arguments\n\npredexog::AbstractVecOrMat: exogenous predictors, including constant term, if any (X/X₁)\npredendog::AbstractVecOrMat: endogenous predictors (Y₂)\ninst::AbstractVecOrMat: instruments (X₂)\nR1::AbstractMatrix and r1::AbstractVector: model constraints; same format as for R and r\nclustid::AbstractVecOrMat{<:Integer}: data vector/matrix of error and bootstrapping cluster identifiers; see notes \nnbootclustvar::Integer=size(clustid,2): number of bootstrap-clustering variables\nnerrclustvar::Integer=nbootclustvar: number of error-clustering variables\nissorted:Bool=false: time-saving flag: data matrices\t are already sorted by column types 2, then 3, then 1 (see notes)\nhetrobust::Bool=true: true unless errors are treated as iid\nfeid::AbstractVector{<:Integer}: data vector for one-way fixed effect group identifier\nfedfadj::Integer: degrees of freedom that fixed effects (if any) consume; defaults to number of FEs\nobswt::AbstractVector=[]: observation weight vector; default is equal weighting\nfweights::Bool=false: true for frequency weights\nmaxmatsize::Number: maximum size of auxilliary weight matrix (v), in gigabytes\nptype::Symbol=:symmetric: p value type (:symmetric, :equaltail, :lower, :upper)\nbootstrapc::Bool=false: true to request bootstrap-c instead of bootstrap-t\nliml::Bool=false: true for LIML or Fuller LIML\nfuller::Number: Fuller LIML factor\nkappa::Number: fixed κ for k-class estimation\narubin::Bool=false: true for Anderson-Rubin test\nsmall::Bool=true: true to multiply test statistics by G/(G-1) × N/(N-k), where G, N, k are number of clusters, observations, and predictors\nclusteradj::Bool=true: false to drop G/(G-1) factor\nclustermin::Bool=false`: for multiway clustering, true to base G/(G-1) factor for all clusterings ]on the smallest G across clusterings\njk::Bool=false: true to base the bootstrap data-generating process on residuals jackknifed by bootstrap cluster\nscorebs::Bool=false: true for score bootstrap instead of wild bootstrap\nreps::Integer=999: number of bootstrap replications; reps = 0 requests classical Rao (or Wald) test if imposenull = true (or false)\nimposenull::Bool=true: true to impose null\nauxwttype::Symbol=:rademacher: auxilliary weight type (:rademacher, :mammen, :webb, :normal, :gamma)\nrng::AbstractRNG=MersenneTwister(): randon number generator\nlevel::Number=.95: significance level (0-1)\nrtol::Number=1e-3: tolerance for confidence set bound determination\nmadjtype::Symbol=:none: multiple hypothesis adjustment (:none, :bonferroni, :sidak)\nnH0::Integer=1: number of hypotheses tested, including one being tested now\nml::Bool=false: true for (nonlinear) ML estimation\nscores::AbstractVecOrMat: for ML, pre-computed scores\nbeta::AbstractVector: for ML, parameter estimates\nA::AbstractMatrix: for ML, covariance estimates\ngridmin: vector of graph lower bounds; max length 2, missing/NaN entries ask wildboottest() to choose\ngridmax: vector of graph upper bounds; missing/NaN entries ask wildboottest() to choose\ngridpoints: vector of number of sampling points; missing/NaN entries ask wildboottest() to choose\ngetdist::Bool=:false: whether to return bootstrapped distribution for t/z/F/χ² statistics; and their numerators\ngetci::Bool=true: whether to return confidence interval\ngetplot::Bool=getci: whether to generate plot data\ngetauxweights::Bool=false: whether to save auxilliary weight matrix (v)\n\nNotes\n\nT, ptype, auxwttype, and madjtype may also be strings. Examples: \"Float32\" and \"webb\".\n\nThe columns of R in the statement of the null should correspond to those of the matrix [predexog predendog], where predendog is non-empty only in regressions with instruments. \n\nOrder the columns of clustid this way:\n\nVariables only used to define bootstrapping clusters, as in the subcluster bootstrap.\nVariables used to define both bootstrapping and error clusters.\nVariables only used to define error clusters.\n\nnbootclustvar is then the number of columns of type 1 or 2; nerrclustvar is the number of columns of type 2 or 3. Typically clustid is a single column of type 2 and nbootclustvar and nerrclustvar default to 1.\n\nwildboottest() does not handle missing data values: all data and identifier matrices must  be restricted to the estimation sample.\n\n\n\n\n\n","category":"function"},{"location":"exported/#WildBootTests.teststat","page":"Public functions and types","title":"WildBootTests.teststat","text":"teststat(::WildBootTests.BootTestResult{T}) -> T\n\nGiven a wildboottest() return object, extract test statistic\n\n\n\n\n\n","category":"function"},{"location":"exported/#WildBootTests.stattype","page":"Public functions and types","title":"WildBootTests.stattype","text":"stattype(::WildBootTests.BootTestResult{T}) -> String\n\nGiven a wildboottest() return object, extract type of test statistic: \"t\", \"z\", \"F\", or \"χ²\"\n\n\n\n\n\n","category":"function"},{"location":"exported/#WildBootTests.p","page":"Public functions and types","title":"WildBootTests.p","text":"p(::WildBootTests.BootTestResult{T}) -> T\n\nGiven a wildboottest() return object, extract p value\n\n\n\n\n\n","category":"function"},{"location":"exported/#WildBootTests.padj","page":"Public functions and types","title":"WildBootTests.padj","text":"padj(::WildBootTests.BootTestResult{T}) -> T\n\nGiven a wildboottest() return object, extract p value after multiple-hypothesis adjustment, if any\n\n\n\n\n\n","category":"function"},{"location":"exported/#WildBootTests.reps","page":"Public functions and types","title":"WildBootTests.reps","text":"reps(::WildBootTests.BootTestResult{T}) -> Int64\n\nGiven a wildboottest() return object, extract number of replications\n\n\n\n\n\n","category":"function"},{"location":"exported/#WildBootTests.repsfeas","page":"Public functions and types","title":"WildBootTests.repsfeas","text":"repsfeas(::WildBootTests.BootTestResult{T}) -> Int64\n\nGiven a wildboottest() return object, extract actual number of replications, subject to enumeration of Rademacher draws\n\n\n\n\n\n","category":"function"},{"location":"exported/#WildBootTests.nbootclust","page":"Public functions and types","title":"WildBootTests.nbootclust","text":"nbootclust(::WildBootTests.BootTestResult{T}) -> Int64\n\nGiven a wildboottest() return object, extract number of bootstrapping clusters in test\n\n\n\n\n\n","category":"function"},{"location":"exported/#WildBootTests.dof","page":"Public functions and types","title":"WildBootTests.dof","text":"dof(::WildBootTests.BootTestResult{T}) -> Int64\n\nGiven a wildboottest() return object, extract degrees of freedom of test\n\n\n\n\n\n","category":"function"},{"location":"exported/#WildBootTests.dof_r","page":"Public functions and types","title":"WildBootTests.dof_r","text":"dof_r(::WildBootTests.BootTestResult{T}) -> Int64\n\nGiven a wildboottest() return object, extract residual degrees of freedom of test\n\n\n\n\n\n","category":"function"},{"location":"exported/#WildBootTests.plotpoints","page":"Public functions and types","title":"WildBootTests.plotpoints","text":"plotpoints(::WildBootTests.BootTestResult{T}) -> NamedTuple{(:X, :p), Tuple{Tuple{Vararg{Vector{T}, N} where N},Vector{T}}}\n\nReturn data for confidence plot of test. Return value is a 2-tuple with named entries X and p holding the confidence sampling locations and p values respectively. X is in turn a 1- or 2-tuple of vectors of sampling coordinates for each  dimension of the tested hypothesis.\n\n\n\n\n\n","category":"function"},{"location":"exported/#WildBootTests.peak","page":"Public functions and types","title":"WildBootTests.peak","text":"peak(::WildBootTests.BootTestResult{T}) -> NamedTuple{(:X, :p), Tuple{Vector{T}, T}}\n\nGiven a wildboottest() return object for a one-dimensional test, return the parameter value with peak p value in test Return value is a 2-tuple with named entries X and p holding the parameter value and p value.\n\n\n\n\n\n","category":"function"},{"location":"exported/#WildBootTests.ci","page":"Public functions and types","title":"WildBootTests.ci","text":"ci(::WildBootTests.BootTestResult{T}) -> Matrix{T}\n\nGiven a wildboottest() return object for a one-dimensional test, extract the confidence interval(s) for test, one row per disjoint piece\n\n\n\n\n\n","category":"function"},{"location":"exported/#WildBootTests.dist","page":"Public functions and types","title":"WildBootTests.dist","text":"dist(::WildBootTests.BootTestResult{T}) -> Matrix{T}\n\nGiven a wildboottest() return object, extract bootstrap distribution of statistic\n\n\n\n\n\n","category":"function"},{"location":"exported/#WildBootTests.statnumer","page":"Public functions and types","title":"WildBootTests.statnumer","text":"statnumer(::WildBootTests.BootTestResult{T}) -> T\n\nGiven a wildboottest() return object, extract numerator of test statistic\n\n\n\n\n\n","category":"function"},{"location":"exported/#WildBootTests.statvar","page":"Public functions and types","title":"WildBootTests.statvar","text":"statvar(::WildBootTests.BootTestResult{T}) -> T\n\nGiven a wildboottest() return object, extract squared denominator of test statistic\n\n\n\n\n\n","category":"function"},{"location":"exported/#WildBootTests.auxweights","page":"Public functions and types","title":"WildBootTests.auxweights","text":"auxweights(::WildBootTests.BootTestResult{T}) -> Matrix{T}\n\nGiven a wildboottest() return object for a one-dimensional test, extract auxilliary weight matrix\n\n\n\n\n\n","category":"function"},{"location":"IVexamples/","page":"IV/2SLS examples","title":"IV/2SLS examples","text":"using WildBootTests, CSV, DataFrames, StatsModels, GLM, Plots\n\n# specify exactly identified model: regress wage on on tenure, instrumented by union,\n# controlling for ttl_exp and collgrad\nd = download(\"http://www.stata-press.com/data/r8/nlsw88.dta\", tempname() * \".dta\")\ndf = DataFrame(load(d))[:, [:wage; :tenure; :ttl_exp; :collgrad; :industry; :union]]\ndropmissing!(df)\nf = @formula(wage ~ 1 + ttl_exp + collgrad)\nf = apply_schema(f, schema(f, df))\nresp, predexog = modelcols(f, df)\nivf = @formula(tenure ~ union)\nivf = apply_schema(ivf, schema(ivf, df))\npredendog, inst = modelcols(ivf, df)\n\n# test that coefficient on tenure = 0, clustering errors by industry\nR = [0 0 0 1]; r = [0]\nwildboottest(R, r; resp, predexog, predendog, inst, clustid=df.industry)\n\n# use equal-tailed instead of symmetric p value\nwildboottest(R, r; resp, predexog, predendog, inst, clustid=df.industry, ptype=:equaltail)\n\n# perform bootstrap-c instead of bootstrap-t, as advocated by Young (2019)\nwildboottest(R, r; resp, predexog, predendog, inst, clustid=df.industry, bootstrapc=true)\n\n# Rao/score test without bootstrap\nwildboottest(R, r; resp, predexog, predendog, inst, clustid=df.industry, reps=0)\n\n# Wald test without bootstrap\nwildboottest(R, r; resp, predexog, predendog, inst, clustid=df.industry, reps=0, imposenull=false)\n\n# Anderson-Rubin test that hypothesis holds and instrument is valid\nwildboottest(R, r; resp, predexog, predendog, inst, clustid=df.industry, arubin=true)\n\n# modify model to drop controls and make ttl_exp an instrument\nf = @formula(wage ~ 1)\nf = apply_schema(f, schema(f, df))\nresp, predexog = modelcols(f, df)\nivf = @formula(tenure ~ collgrad + ttl_exp)\nivf = apply_schema(ivf, schema(ivf, df))\npredendog, inst = modelcols(ivf, df)\n\n# test same hypothesis in context of LIML regression\nR = [0 1]; r = [0]\nwildboottest(R, r; resp, predexog, predendog, inst, liml=true, clustid=df.industry)","category":"page"},{"location":"","page":"Overview","title":"Overview","text":"WildBootTests.jl performs wild bootstrap-based hypothesis tests at extreme speed. It is intended mainly for linear models: ordinary least squares (OLS) and instrumental variables/two-stage least squares (IV/2SLS). For an introduction to the wild bootstrap and the algorithms deployed here, see Roodman et al. (2019).","category":"page"},{"location":"","page":"Overview","title":"Overview","text":"The package offers and/or supports:","category":"page"},{"location":"","page":"Overview","title":"Overview","text":"The wild bootstrap for OLS (Wu 1986).\nThe Wild Restricted Efficient bootstrap (WRE) for IV/2SLS/LIML (Davidson and MacKinnon 2010).\nThe subcluster bootstrap (MacKinnon and Webb 2018).\nNon-bootstrapped Wald, Rao, and Anderson-Rubin tests, optionally with multiway clustering.\nConfidence intervals formed by inverting the test and iteratively searching for bounds.\nMultiway clustering.\nArbitrary and multiple linear hypotheses in the parameters.\nMaintained linear constraints on the model (restricted OLS, IV/2SLS/LIML).\nOne-way fixed effects.\nGeneration of data for plotting of confidence curves or surfaces after one- or two-dimensional hypothesis tests.","category":"page"},{"location":"","page":"Overview","title":"Overview","text":"WildBootTests.jl incorporates order-of-magnitude algorithmic speed-ups developed since Roodman et al. (2019) for OLS and IV/2SLS. And it exploits the efficiency of Julia, for example by offering single-precision (Float32) computation.","category":"page"},{"location":"","page":"Overview","title":"Overview","text":"The interface is low-level: the exported function wildboottest() accepts scalars, vectors, and matrices, not DataFrames or results from estimation functions such as lm(). This design minimizes the package's dependency footprint while making the core functionality available to multiple programming environments, including Julia, R (through JuliaConnectoR), and Python (through PyJulia). A separate package will provide a higher-level Julia interface.","category":"page"},{"location":"","page":"Overview","title":"Overview","text":"wildboottest() accepts many optional arguments. Most correspond to options of the Stata package boottest, which are documented in Roodman et al. (2019), §7. Julia-specific additions include an optional first argument T, which can be Float32 or Float64 to specify the precision of computation; and rng, which takes a random number generator such as MersenneTwister(2302394).","category":"page"},{"location":"#On-latency","page":"Overview","title":"On latency","text":"","category":"section"},{"location":"","page":"Overview","title":"Overview","text":"The first time you run wildboottest() in a session, Julia's just-in-time compilation will take ~10 seconds. The same will happen the first time you switch between Float32 and Float64 calculations, or between OLS and IV/2SLS estimation.","category":"page"},{"location":"OLSexamples/#Basic-OLS-example","page":"OLS examples","title":"Basic OLS example","text":"","category":"section"},{"location":"OLSexamples/","page":"OLS examples","title":"OLS examples","text":"julia> using WildBootTests, CSV, DataFrames, StatsModels, GLM, Plots\n\njulia> d = download(\"https://raw.github.com/vincentarelbundock/Rdatasets/master/csv/sandwich/PetersenCL.csv\");\n\njulia> df = CSV.read(d, DataFrame);\n\njulia> f = @formula(y ~ 1 + x);  # state OLS model\n\njulia> f = apply_schema(f, schema(f, df));  # link model to data\n\njulia> lm(f, df)  # run OLS for illustration; not needed for following lines\nStatsModels.TableRegressionModel{LinearModel{GLM.LmResp{Vector{Float64}}, GLM.DensePredChol{Float64, LinearAlgebra.CholeskyPivoted{Float64, Matrix{Float64}}}}, Matrix{Float64}}","category":"page"},{"location":"OLSexamples/","page":"OLS examples","title":"OLS examples","text":"y ~ 1 + x\n\nCoefficients:\n─────────────────────────────────────────────────────────────────────────\n                 Coef.  Std. Error      t  Pr(>|t|)  Lower 95%  Upper 95%\n─────────────────────────────────────────────────────────────────────────\n(Intercept)  0.0296797   0.0283593   1.05    0.2954  -0.025917  0.0852764\nx            1.03483     0.0285833  36.20    <1e-99   0.978798  1.09087\n─────────────────────────────────────────────────────────────────────────","category":"page"},{"location":"OLSexamples/","page":"OLS examples","title":"OLS examples","text":"julia> resp, predexog = modelcols(f, df);  # extract response & (exogenous) predictor variables\n\njulia> clustid = df.firm;  # extract clustering variable\n\njulia> R = [0 1]; r = [1];  # put null that coefficient on x = 1 in Rβ̂ = r form, where β̂ is parameter vector\n\njulia> test = wildboottest(R, r; resp=resp, predexog=predexog, clustid=clustid)\nWildBootTests.BootTestResult{Float32}\n\np  = 0.492\nci = Float32[0.93461335 1.1347668]\n\njulia> test = wildboottest(R, r; resp, predexog, clustid);  # same, using Julia syntactic sugar\n\njulia> p(test)  # programmatically extract p value\n0.49459493f0\n\njulia> ci(test)  # programmatically extract confidence interval","category":"page"},{"location":"OLSexamples/","page":"OLS examples","title":"OLS examples","text":"1×2 Matrix{Float32}:\n 0.934961  1.13469","category":"page"},{"location":"OLSexamples/","page":"OLS examples","title":"OLS examples","text":"julia> plot(plotpoints(test)...)  # plot confidence curve","category":"page"},{"location":"OLSexamples/#Further-examples","page":"OLS examples","title":"Further examples","text":"","category":"section"},{"location":"OLSexamples/","page":"OLS examples","title":"OLS examples","text":"using WildBootTests, CSV, DataFrames, StatsModels, GLM, Plots\n\n# use Webb instead of Rademacher weights, 99,999 bootstrap replications instead of 999\nwildboottest(R, r; resp, predexog, clustid, reps=99999, auxwttype=:webb)\n\n# jackknife the bootstrap data-generating process to reduce distortion from outliers\nwildboottest(Float64, R, r; resp, predexog, clustid, jk=true)\n\n# use guaranteed-stable random number generator for exact replicability\nusing StableRNGs\nwildboottest(R, r; resp, predexog, clustid, rng=StableRNG(23948572))\n\n# test that coefficient on intercept = 0 and coefficient on x = 1; plot confidence surface\ntest = wildboottest([1 0; 0 1], [0;1]; resp, predexog, clustid, reps=9999)\nplot(plotpoints(test).X..., plotpoints(test).p, st=:contourf)\n\n# multiway-cluster errors by firm and year; bootstrap by firm\nwildboottest(R, r; resp, predexog, clustid=Matrix(df[:,[:firm, :year]]), nerrclustvar=2, nbootclustvar=1)\n\n# same but bootstrap by year\nwildboottest(R, r; resp, predexog, clustid=Matrix(df[:,[:year, :firm]]), nerrclustvar=2, nbootclustvar=1)\n\n# same but bootstrap by year-firm pair\nwildboottest(R, r; resp, predexog, clustid=Matrix(df[:,[:year, :firm]]), nerrclustvar=2, nbootclustvar=2)\n\n# Rao/score test with multiway clustering of errors but no bootstrap\nwildboottest(R, r; resp, predexog, predendog, inst, Matrix(df[:,[:year, :firm]]), reps=0)\n\n# Same but Wald test: i.e., conventional, multiway clustered errors\nwildboottest(R, r; resp, predexog, predendog, inst, clustid=Matrix(df[:,[:year, :firm]]), reps=0, imposenull=false)\n\n# add year fixed effects to model; cluster by firm\nwildboottest(R, r; resp, predexog, feid=df.year, clustid=df.firm)\n\n# test hypotheses, while imposing model constraint that constant term = 0.2\nR1 = [1 0]; r1 = [.2]\nwildboottest(R, r; R1, r1, resp, predexog, clustid=df.firm)","category":"page"}]
}
