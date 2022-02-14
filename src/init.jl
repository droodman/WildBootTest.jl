@inline _sortperm(X::AbstractVecOrMat) = size(X,2)==1 ? sortperm(ndims(X)==1 ? X : vec(X), alg=RadixSort) : sortperm(collect(eachrow(X)))  # sort a data matrix

function Init!(o::StrBootTest{T}) where T  # for efficiency when varying r repeatedly to make CI, do stuff once that doesn't depend on r
	o.kX = o.kX₁ + o.kX₂
	o.kX₂==0 && (o.X₂ = zeros(T,o.Nobs,0))
  iszero(o.kY₂) && (o.Y₂ = zeros(T,o.Nobs,0))
  o.kZ = o.kX₁ + o.kY₂
  if o.LIML && o.kX₂==o.kY₂  # exactly identified LIML = 2SLS
  	o.κ = one(T)
  	o.LIML = false
  end
  if !(o.REst = length(o.R₁)>0)  # base model contains no restrictions?
    o.R₁ = zeros(T,0,o.kZ)
    o.r₁ = zeros(T,0)
  end
  isnan(o.κ) && (o.κ = o.kX₂>0 ? one(T) : zero(T))  # if κ in κ-class estimation not specified, it's 0 or 1 for OLS or 2SLS
  o.WRE = !(iszero(o.κ) || o.scorebs) || o.ARubin

  iszero(o.B) && (o.scorebs = true)

  o.haswt = !iszero(nrows(o.wt))
	if o.haswt
		o.sumwt = sum(o.wt)
		o._Nobs = o.fweights ? o.sumwt : T(o.Nobs)
	else
		o.sumwt = one(T)
		o._Nobs = T(o.Nobs)
	end

	if !(iszero(o.NClustVar) || o.issorted)
		o.subcluster = o.NClustVar - o.nerrclustvar
		p = _sortperm(view(o.ID, :, [collect(o.subcluster+1:o.NClustVar); collect(1:o.subcluster)]))  # sort by err cluster vars, then remaining boot cluster vars
		o.ID = ndims(o.ID)==1 ? o.ID[p] : o.ID[p,:]
		o.X₁ = ndims(o.X₁)==1 ? o.X₁[p] : o.X₁[p,:]
		o.X₂ = ndims(o.X₂)==1 ? o.X₂[p] : o.X₂[p,:]
		o.y₁ = o.y₁[p]
		o.Y₂ = ndims(o.Y₂)==1 ? o.Y₂[p] : o.Y₂[p,:]
		isdefined(o, :FEID) && nrows(o.FEID)>0 && (o.FEID = o.FEID[p])

		if o.haswt
			o.wt = o.wt[p]

			sqrtwt = sqrt(o.wt)
			o.y₁ .= o.y₁ ./ sqrtwt  # can overwrite sorted copy of user's data
			length(o.Y₂)>0 && (o.Y₂ .= o.Y₂ ./ sqrtwt)
			length(o.X₁)>0 && (o.X₁ .= o.X₁ ./ sqrtwt)
			length(o.X₂)>0 && (o.X₂ .= o.X₂ ./ sqrtwt)
		end
	elseif o.haswt
		sqrtwt = sqrt(o.wt)
		o.y₁ = o.y₁ ./ sqrtwt  # don't overwrite user's data
		length(o.Y₂)>0 && (o.Y₂ = o.Y₂ ./ sqrtwt)
		length(o.X₁)>0 && (o.X₁ = o.X₁ ./ sqrtwt)
		length(o.X₂)>0 && (o.X₂ = o.X₂ ./ sqrtwt)
	end

  if o.WREnonARubin
	  if iszero(o.NClustVar)
	    o.info⋂ = o.info✻ = Vector{UnitRange{Int64}}(undef, o.Nobs, 0)  # no clustering, so no collapsing by cluster
	  else
	    o.info✻, o.ID✻ = panelsetupID(o.ID, 1:o.nbootclustvar)
	  end
  elseif !iszero(o.NClustVar)
	  o.info✻ = panelsetup(o.ID, 1:min(o.NClustVar,o.nbootclustvar))  # bootstrap cluster grouping defs rel to original data
  else
	  info⋂ = info✻⋂ = o.info✻ = Vector{UnitRange{Int64}}(undef, o.Nobs, 0)  # causes no collapsing of data in panelsum() calls, only multiplying by weights if any
  end
  o.N✻ = nrows(o.info✻)

	if o.NClustVar > o.nbootclustvar  # info for grouping by intersections of all bootstrap && clustering vars wrt data; used to speed crosstab UXAR wrt bootstrapping cluster && intersection of all error clusters
		if o.WREnonARubin && !o.granular
			o.info✻⋂, ID✻⋂ = panelsetupID(o.ID, 1:o.NClustVar)
		else
			o.info✻⋂       = panelsetup(o.ID, 1:o.NClustVar)
		end
		if o.subcluster>0 && nrows(o.info✻) ≠ nrows(o.info✻⋂)
			throw(ErrorException("\nThis program can only perform the subcluster bootstrap when the bootstrap clusters are nested within the (intersections of the) error clusters.\n"))
		end
	else
		o.info✻⋂ = o.info✻  # info for grouping by intersections of all bootstrap && clustering vars wrt data; used to speed crosstab UXAR wrt bootstrapping cluster && intersection of all error clusters
		o.WREnonARubin && !o.granular && (o._ID✻⋂ = o.ID✻)
	end

	o.N✻⋂ = length(o.info✻⋂)

	if o.NClustVar > o.nerrclustvar  # info for intersections of error clustering wrt data
		if o.WREnonARubin && !o.granular
			o.info⋂, ID⋂ = panelsetupID(o.ID, o.subcluster+1:o.NClustVar)
		else
			o.info⋂      = panelsetup(o.ID, o.subcluster+1:o.NClustVar)
		end
		ID⋂_✻⋂ = length(o.info⋂)==o.Nobs ? o.ID : o.ID[first.(o.info⋂ ),:]  # version of ID matrix with one row for each all-error-cluster-var intersection instead of 1 row for each obs; gets resorted
		o.ID✻⋂ =            o.N✻⋂==o.Nobs ? o.ID : o.ID[first.(o.info✻⋂),:]  # version of ID matrix with one row for each all-bootstrap && error cluster-var intersection instead of 1 row for each obs
	else
		o.info⋂ = o.info✻⋂  # info for intersections of error clustering wrt data
		o.WREnonARubin && !o.granular && (ID⋂ = o._ID✻⋂)
		o.ID✻⋂ = ID⋂_✻⋂ = nrows(o.info⋂)==o.Nobs ? o.ID : o.ID[first.(o.info⋂),:]  # version of ID matrix with one row for each all-error-cluster-var intersection instead of 1 row for each obs; gets resorted
	end
	o.WREnonARubin && (o.info✻_✻⋂ = panelsetup(o.ID✻⋂, 1:o.nbootclustvar))

	if o.bootstrapt
    if o.NClustVar>0
	    minN = T(Inf)

	    combs = [x & 2^y > 0 for x in 2^o.nerrclustvar-1:-1:1, y in o.nerrclustvar-1:-1:0]  # represent all error clustering combinations. First is intersection of all error clustering vars
	    o.clust = Vector{StrClust{T}}(undef, nrows(combs))  # leave out no-cluster combination
	    o.NErrClustCombs = length(o.clust)

	    o.BootClust = 2^(o.NClustVar - o.nbootclustvar)  # location of bootstrap clustering within list of cluster combinations

	    @inbounds for c ∈ 1:o.NErrClustCombs  # for each error clustering combination
		    ClustCols = o.subcluster .+ findall(@view combs[c,:])
		    even = isodd(length(ClustCols))  # not a typo

		    if isone(c)
		      if iszero(o.subcluster)
		    	  order = Vector{Int64}(undef,0)
		    	  info  = Vector{UnitRange{Int64}}(undef, 0)  # causes no collapsing of data in panelsum() calls
						N = o.N✻⋂
		      else
		    	  order = _sortperm(@view ID⋂_✻⋂[:,ClustCols])
		    	  info  = panelsetup(view(ID⋂_✻⋂,order,:), ClustCols)
						N = nrows(info)
		      end
		    else
		      if any(combs[c, minimum(findall(combs[c,:] .≠ combs[c-1,:])):end])  # if this sort ordering same as last to some point and missing thereafter, no need to re-sort
		    	  order = _sortperm(@view ID⋂_✻⋂[:,ClustCols])
		    	  info = panelsetup(view(ID⋂_✻⋂,order,:), ClustCols)
		      else
		    	  order = Vector{Int64}(undef,0)
						info = panelsetup(ID⋂_✻⋂, ClustCols)
		      end
					N = nrows(info)
		    end

		    if o.small
					multiplier = T(N / (N-1))
					minN = min(minN,N)
				else
					multiplier = one(T)
				end
				o.clust[c] = StrClust{T}(N, multiplier, even, order, info)
	    end

	    (o.scorebs || !o.WREnonARubin) &&
		  	(o.ClustShare = o.haswt ? @panelsum(o, o.wt, o.info⋂)/o.sumwt : T.(length.(o.info⋂)./o.Nobs)) # share of observations by group

    else  # if no clustering, cast "robust" as clustering by observation
      o.clust = StrClust{T}(Nobs, small ? o._Nobs / (o._Nobs - one(T)) : one(T), true, Vector{Int64}(undef,0), Vector{UnitRange{Int64}}(undef,0))
      o.NErrClustCombs = one(Int16)
      (o.scorebs || !o.WREnonARubin) &&
    		(o.ClustShare = o.haswt ? o.wt/o.sumwt : fill(one(T)/o._Nobs,o._Nobs))
    end

		o.purerobust = o.robust && !o.scorebs && iszero(o.subcluster) && o.N✻==o.Nobs  # do we ever error-cluster *and* bootstrap-cluster by individual?
		o.granular   = o.WREnonARubin ? 2*o.Nobs*o.B*(2*o.N✻+1) < o.N✻*(o.N✻*o.Nobs+o.clust[1].N*o.B*(o.N✻+1)) :
											o.NClustVar>0 && !o.scorebs && (o.purerobust || (o.clust[1].N+o.N✻)*o.kZ*o.B + (o.clust[1].N-o.N✻)*o.B + o.kZ*o.B < o.clust[1].N*o.kZ^2 + o.Nobs*o.kZ + o.clust[1].N * o.N✻ * o.kZ + o.clust[1].N * o.N✻)

		if o.robust && !o.purerobust
			(o.subcluster>0 || o.granular) && !o.WREnonARubin && 
				(o.info⋂_✻⋂ = panelsetup(o.ID✻⋂, o.subcluster+1:o.NClustVar))  # info for error clusters wrt data collapsed to intersections of all bootstrapping && error clusters; used to speed crosstab UXAR wrt bootstrapping cluster && intersection of all error clusterings
			((o.scorebs && o.B>0) || (o.WREnonARubin && !o.granular && o.bootstrapt)) &&
				(o.JN⋂N✻ = zeros(T, o.clust[1].N, o.N✻))
		end

		if o.WREnonARubin && o.robust && o.bootstrapt && !o.granular
			if iszero(length(o._ID✻⋂))
				_, o._ID✻⋂ = panelsetupID(o.ID,              1:o.NClustVar)
				_, ID⋂     = panelsetupID(o.ID, o.subcluster+1:o.NClustVar)
			end

			o.IDCT⋂✻   = Vector{Vector{Int64}}(undef, o.N✻)
			o.infoCT⋂✻ = Vector{Vector{UnitRange{Int64}}}(undef, o.N✻)
			for i ∈ 1:o.N✻
				tmp = o._ID✻⋂[o.info✻[i]]                        # ID numbers w.r.t. intersection of all bootstrap/error clusterings contained in bootstrap cluster i
				o.infoCT⋂✻[i] = o.info✻⋂[tmp[1]:tmp[end]]       # for each of those ID's, panel info for the all-bootstrap/error-clusterings data row groupings
				o.IDCT⋂✻[i] = ID⋂[first.(o.infoCT⋂✻[i])]  # ID numbers of those groupings w.r.t. the all-error-clusterings grouping
			end
		end
  else
	  minN = T(nrows(o.info✻))
	end

	InitFEs(o)

	if o.B>0 && o.robust && o.granular && !o.purerobust && o.bootstrapt && !o.WREnonARubin
		if o.NFE>0 && !o.FEboot
			_, o.ID✻ = panelsetupID(o.ID   , 1:o.nbootclustvar)
		else
			_, o.ID✻_✻⋂ = panelsetupID(o.ID✻⋂, 1:o.nbootclustvar)
		end
	end

	o.enumerate = o.B>0 && o.auxtwtype==rademacher && o.N✻*log(2) < log(o.B)+1e-6  # generate full Rademacher set?
	o.enumerate && (o.maxmatsize = 0)

	o.Nw = iszero(o.maxmatsize) ? one(Int64) : ceil(Int64, (o.B+1) * Float64(max(nrows(o.ID✻), length(o.ID✻_✻⋂), o.N✻) * sizeof(T)) / o.maxmatsize / 1073741824) # 1073741824 = giga(byte)
	if isone(o.Nw)
		MakeWildWeights!(o, o.B, first=true)  # make all wild weights, once
		o.enumerate && (o.B = ncols(o.v) - 1)  # replications reduced to 2^G
		o.WeightGrp = [1:ncols(o.v)]
	else
    o.seed = rand(o.rng, UInt64)
		_B = ceil(Int64, (o.B+1) / o.Nw)
		o.Nw = ceil(Int64, (o.B+1) / _B)
		o.WeightGrp = [(i-1)*_B+1:i*_B for i ∈ 1:o.Nw]
		o.WeightGrp[end] = first(o.WeightGrp[end]):o.B+1
	end

	if o.ML
		o.dof = nrows(o.R)
	else
		if o.ARubin
			o.R = hcat(zeros(o.kX₂,o.kX₁), Matrix(I(o.kX₂)))  # attack surface is all endog vars
			o.R₁ = o.kX₁>0 && nrows(o.R₁)>0 ? hcat(o.R₁[:,1:o.kX₁], zeros(nrows(o.R₁),o.kX₂)) : zeros(0, o.kX)  # and convert model constraints from referring to X₁, Y₂ to X₁, X₂
		end
		o.dof = nrows(o.R)

		if !o.WRE && iszero(o.κ)  # regular OLS
			o.DGP = StrEstimator{T}(true, o.LIML, o.Fuller, o.κ)
			o.Repl = StrEstimator{T}(true, false, zero(T), zero(T))  # XXX isDGP=1 for Repl? doesn't matter?
			setR!(o.DGP, o, o.null ? [o.R₁ ; o.R] : o.R₁)  # DGP constraints: model constraints + null if imposed
			setR!(o.Repl, o, o.R₁)  # model constraints only
			InitVarsOLS!(o.DGP, o, o.Repl.R₁perp)
			InitTestDenoms!(o.DGP, o)
			o.M = o.DGP  # StrEstimator object from which to get A, AR, XAR
		elseif o.ARubin
			if o.willplot  # for plotting/CI purposes get original point estimate since not normally generated
				o.DGP = StrEstimator{T}(true, o.LIML, o.Fuller, o.κ)
				setR!(o.DGP, o, o.R₁, zeros(T,0,o.kZ))  # no-null model
				InitVarsIV!(o.DGP, o)
				EstimateIV!(o.DGP, o, o.r₁)
				o.confpeak = o.DGP.β̈  # estimated coordinate of confidence peak
			end

			o.DGP = StrEstimator{T}(true, false, zero(T), zero(T))
			setR!(o.DGP, o, o.R₁)
			InitVarsARubin!(o.DGP, o)
			InitTestDenoms!(o.DGP, o)
			o.M = o.DGP  # StrEstimator object from which to get A, AR, XAR
			o.kZ = o.kX

		elseif o.WREnonARubin

			o.Repl = StrEstimator{T}(false, o.LIML, o.Fuller, o.κ)
			setR!(o.Repl, o, o.R₁, o.R)
			InitVarsIV!(o.Repl, o)
			EstimateIV!(o.Repl, o, o.r₁)

			o.DGP = StrEstimator{T}(true, T(o.kX₂ ≠ o.kY₂), zero(T), one(T))
			setR!(o.DGP, o, o.null ? [o.R₁ ; o.R] : o.R₁, zeros(T,0,o.kZ))  # DGP constraints: model constraints + null if imposed
			InitVarsIV!(o.DGP, o)
			if !o.null  # if not imposing null, then DGP constraints, κ, Hessian, etc. do not vary with r and can be set now
				EstimateIV!(o.DGP, o, o.r₁)
				MakeResidualsIV!(o.DGP, o)
			end

			InitWRE!(o)

		else  # the score bootstrap for IV/GMM uses a IV/GMM DGP but then masquerades as an OLS test because most factors are fixed during the bootstrap. To conform, need DGP and Repl objects with different R, R₁, one with FWL, one not

			o.DGP = StrEstimator{T}(true, o.LIML, o.Fuller, o.κ)
			setR!(o.DGP, o, o.null ? [o.R₁ ; o.R] : o.R₁, zeros(T,0,o.kZ))  # DGP constraints: model constraints + null if imposed
			InitVarsIV!(o.DGP, o)
			o.Repl = StrEstimator{T}(true, o.LIML, o.Fuller, o.κ)
			setR!(o.Repl, o, o.R₁, I)  # process replication restraints = model constraints only
			InitVarsIV!(o.Repl, o, o.Repl.R₁perp)
			EstimateIV!(o.Repl, o, o.r₁)  # bit inefficient to estimate in both objects, but maintains the conformity
			InitTestDenoms!(o.Repl, o)
			o.M = o.Repl  # StrEstimator object from which to get A, AR, XAR; DGP follows WRE convention of using FWL, Repl follows OLS convention of not; scorebs for IV/GMM mixes the two
			if !o.null  # if not imposing null, then DGP constraints, κ, Hessian, etc. do not vary with r and can be set now
				EstimateIV!(o.DGP, o, o.r₁)
				MakeResidualsIV!(o.DGP, o)
			end
		end
  end

  if !o.WREnonARubin && o.bootstrapt
		o.denom = [Matrix{T}(undef,0,0) for _ in 1:o.dof, _ in 1:o.dof]
		if o.robust
			o.Kcd =                       Matrix{Matrix{T}}(undef, o.NErrClustCombs, o.dof)
			o.Jcd = iszero(o.B) ? o.Kcd : Matrix{Matrix{T}}(undef, o.NErrClustCombs, o.dof)  # if B = 0, Kcd will be multiplied by v, which is all 1's, and will constitute Jcd
		end

		if o.robust && o.granular<o.NErrClustCombs && o.B>0
			inds = o.subcluster>0 ?
				        [CartesianIndex(j, i) for (j,v) ∈ enumerate(o.info⋂_✻⋂) for i ∈ v] :  # crosstab ∩,* is wide
								o.NClustVar == o.nbootclustvar ?
										[CartesianIndex(i, i) for i ∈ 1:o.N✻⋂] :  # crosstab ∩,* is square
										[CartesianIndex(i, j) for (j,v) ∈ enumerate(o.clust[o.BootClust].info) for i ∈ v]  # crosstab ∩,* is tall
			o.crosstab⋂✻ind = LinearIndices(FakeArray(Tuple(max(inds...))...))[inds]
		end
	end

  o.small && (o.dof_r = o.NClustVar>0 ? minN - one(T) : o._Nobs - (o.kZ + o.NFE))  # floating-point dof_r allows for fractional fweights, FWIW...

  o.sqrt = isone(o.dof)  # work with t/z stats instead of F/chi2?

  if o.small
		o.multiplier = (o.smallsample = (o._Nobs - o.kZ - o.FEdfadj * o.NFE) / (o._Nobs - o.robust)) / o.dof  # divide by # of constraints because F stat is so defined
  else
		o.multiplier = o.smallsample = 1
  end

  !(o.robust || o.ML) && (o.multiplier *= o._Nobs)  # will turn sum of squared errors in denom of t/z into mean
  o.sqrt && (o.multiplier = √o.multiplier)

  o.dist = fill(T(NaN), 1, o.B+1)
  (o.Nw>1 || o.WREnonARubin || (!o.null && o.dof≤2)) && (o.numer = fill(T(NaN), o.dof, o.B+1))

  if o.WREnonARubin
		if o.Repl.kZ>1
			o.bootstrapt && o.robust &&
      	(o.Zyg = Vector{Matrix{T}}(undef,o.Repl.kZ))
			o.numer_b = Vector{T}(undef,nrows(o.Repl.RRpar))
		end
		o.bootstrapt && o.robust &&
    	(o.crosstab✻ind = o.Nobs==o.N✻ ? Vector(diagind(FakeArray(o.N✻,o.N✻))) : 
			                                 LinearIndices(FakeArray(o.Nobs,o.N✻))[CartesianIndex.(1:o.Nobs, o.ID✻)])
	else
		o.poles = o.anchor = zeros(T,0)
		o.interpolable = o.bootstrapt && o.B>0 && o.null && o.Nw==1 && (iszero(o.κ) || o.ARubin)
		if o.interpolable
			o.∂numer∂r = Vector{Matrix{T}}(undef, o.q)
			o.interpolate_u = !(o.robust || o.ML)
			o.interpolate_u && (o.∂u∂r = Vector{Matrix{T}}(undef, o.q))
			if o.robust
				o.∂denom∂r   = [Matrix{Matrix{T}}(undef, o.dof, o.dof) for _ in 1:o.q]
				o.∂²denom∂r² = [Matrix{Matrix{T}}(undef, o.dof, o.dof) for _ in 1:o.q, _ in 1:o.q]
				o.∂Jcd∂r     = [Matrix{Matrix{T}}(undef, o.NErrClustCombs, o.dof) for _ in 1:o.q]
			end
		end
  end
	o.initialized = true
	nothing
end

function InitFEs(o::StrBootTest{T}) where T
	if isdefined(o, :FEID) && nrows(o.FEID)>0
		p = _sortperm(o.FEID)
		sortID = o.FEID[p]
		i_FE = 1; o.FEboot = o.B>0 && !o.WREnonARubin && o.NClustVar>0; j = o.Nobs; o._FEID = ones(Int64, o.Nobs)
		o.invFEwt = zeros(T, o.NFE>0 ? o.NFE : o.Nobs)
		o.FEs = Vector{StrFE{T}}(undef, o.NFE>0 ? o.NFE : o.Nobs)
		_sqrtwt = T[]
		@inbounds for i ∈ o.Nobs-1:-1:1
			if sortID[i] ≠ sortID[i+1]
				is = @view p[i+1:j]
				if o.haswt
					_sqrtwt  = @view o.sqrtwt[is]
					wt = _sqrtwt / (sumFEwt = sum(@view o.wt[is]))
				else
					sumFEwt = T(j - i)
					wt = one(T)/sumFEwt
				end
				o.FEs[i_FE] = StrFE{T}(is, wt, _sqrtwt)
				((o.B>0 && o.robust && o.granular < o.nerrclustvar) || (o.WREnonARubin && o.robust && o.granular && o.bootstrapt)) &&
					(o.invFEwt[i_FE] = one(T) / sumFEwt)

				j = i

				if o.FEboot  # are all of this FE's obs in same bootstrapping cluster? (But no need to check if B=0 for then CT_WE in 2nd term of (62) orthogonal to v = col of 1's)
					tmp = o.ID[is, 1:o.nbootclustvar]
					o.FEboot = all(tmp .== view(tmp, 1,:)')
				end
				i_FE += 1
			end
			o._FEID[p[i]] = i_FE
		end
		is = @view p[1:j]
		if o.haswt
			_sqrtwt  = @view o.sqrtwt[is]
			wt = _sqrtwt / (sumFEwt = sum(@view o.wt[is]))
		else
			sumFEwt = T(j)
			wt = T[1/sumFEwt]
		end
		o.FEs[i_FE] = StrFE{T}(is, wt, _sqrtwt)
		o.robust && ((o.B>0 && o.granular < o.nerrclustvar) || (o.WREnonARubin && o.granular && o.bootstrapt)) &&
			(o.invFEwt[i_FE] = 1 / sumFEwt)
		o.NFE = i_FE
		resize!(o.invFEwt, o.NFE)
		resize!(o.FEs    , o.NFE)
		if o.FEboot  # are all of this FE's obs in same bootstrapping cluster?
			tmp = o.ID[is, 1:o.nbootclustvar]
			o.FEboot = all(tmp .== @view tmp[1,:])
		end

		if o.robust && o.B>0 && o.bootstrapt && !o.FEboot && o.granular < o.nerrclustvar
			o.infoBootAll = panelsetup(o.ID✻⋂, 1:o.nbootclustvar)  # info for bootstrapping clusters wrt data collapsed to intersections of all bootstrapping && error clusters
		end

		o.X₁ = partialFE(o, o.X₁)  # don't overwrite caller's data
		o.X₂ = partialFE(o, o.X₂)
		o.y₁ = partialFE(o, o.y₁)
		o.Y₂ = partialFE(o, o.Y₂)
	end
	nothing
end

# draw wild weight matrix of width _B. If first=true, insert column of 1s at front. For non-Anderson-Rubin WRE, subtract 1 from all
const ϕ = (1 + √5)/2

function MakeWildWeights!(o::StrBootTest{T}, _B::Integer; first::Bool=true) where T
  if _B>0  # in scoretest or waldtest WRE, still make v a col of 1's
    if o.enumerate
			o.v = o.WREnonARubin ? [zeros(o.N✻) count_binary(o.N✻, -2, 0)] :  # complete Rademacher set
								[ones( o.N✻) count_binary(o.N✻, -1, 1)]
		elseif o.auxtwtype==normal
			o.v = randn(o.rng, T, o.N✻, _B+first)
			o.WREnonARubin && (o.v .-= one(T))
		elseif o.auxtwtype==gamma
			tmp = quantile.(Gamma(4,.5), rand(o.rng, o.N✻, _B+first))
			o.v = T==Float64 ? tmp : T.(tmp)
			o.WREnonARubin && (o.v .-= one(T))
		elseif o.auxtwtype==webb
			o.v = rand(o.rng, T.([-√1.5, -1, -√.5, √.5, 1, √1.5] .- o.WREnonARubin), o.N✻, _B+first)
		elseif o.auxtwtype == mammen
			o.v = getindex.(Ref(T.([1-ϕ; ϕ] .- o.WREnonARubin)), ceil.(Int16, rand(o.rng, o.N✻, _B+first) ./ (ϕ/√5)))
		elseif o.WREnonARubin  # Rademacher
			o.v = -2rand(o.rng, Bool, o.N✻, _B+first)
		else
			o.v = rand(o.rng, Bool, o.N✻, _B+first) .- T(.5)  # rand(o.rng, Bool, o.N✻, _B+first) .- T(.5)
			o.v_sd = .5
		end

		first && !(o.enumerate && isone(o.v_sd)) && (o.v[:,1] .= o.WREnonARubin ? zero(T) : o.v_sd)  # keep original residuals in first entry to compute base model stat
  else
		o.v = Matrix{T}(undef,0,1)  # in places, ncols(v) indicates B -- 1 for classical tests
  end
	nothing
end
