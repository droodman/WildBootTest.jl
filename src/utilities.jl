@inline nrows(X::AbstractArray) = size(X,1)
@inline ncols(X::AbstractArray) = size(X,2)
@inline sqrtNaN(x) = x<0 ? typeof(x)(NaN) : sqrt(x)

# iszero(nrows(X)) && (return Symmetric(X))
# X, ipiv, info = LinearAlgebra.LAPACK.sytrf!('U', Matrix(X))
# iszero(info) && LinearAlgebra.LAPACK.sytri!('U', X, ipiv)
invsym(X) =
	try
		#=Symmetric=#(pinv(Symmetric(X)))
	catch _
		#=Symmetric=#(fill(eltype(X)(NaN), size(X)))
	end
invsym(X::Symmetric) =
	try
		#=Symmetric=#(pinv(X))
	catch _
		#=Symmetric=#(fill(eltype(X)(NaN), size(X)))
	end

eigvalsNaN(X) =
	try
		eigvals(X)
	catch _
		fill(eltype(X)(NaN), size(X))
	end

function invsymsingcheck(X)  # inverse of symmetric matrix, checking for singularity
	iszero(nrows(X)) && (return (false, #=Symmetric=#(X)))
	X, ipiv, info = LinearAlgebra.LAPACK.sytrf!('U', Matrix(X))
	singular = info>0
	!singular && LinearAlgebra.LAPACK.sytri!('U', X, ipiv)
	singular, #=Symmetric=#(X)
end


@inline colsum(X::AbstractArray) = iszero(length(X)) ? similar(X, 1, size(X)[2:end]...) : sum(X, dims=1)
@inline colsum(X::AbstractArray{Bool}) = iszero(length(X)) ? Array{Int}(undef, 1, size(X)[2:end]...) : sum(X, dims=1)  # type-stable
@inline rowsum(X::AbstractArray) = vec(sum(X, dims=2))

function X₁₂B(X₁::AbstractVecOrMat, X₂::AbstractArray, B::AbstractMatrix)
	dest = X₁ * view(B,1:size(X₁,2),:)
	length(dest)>0 && length(X₂)>0 && matmulplus!(dest, X₂, B[size(X₁,2)+1:end,:])
	dest
end
function X₁₂B(X₁::AbstractArray, X₂::AbstractArray, B::AbstractVector)
	dest = X₁ * view(B,1:size(X₁,2))
	length(dest)>0 && length(X₂)>0 && matmulplus!(dest, X₂, B[size(X₁,2)+1:end])
	dest
end

function coldot!(dest::AbstractMatrix{T}, row::Integer, A::AbstractMatrix{T}, B::AbstractMatrix{T}) where T  # colsum(A .* B)
  dest[row,:] .= zero(T)
	coldotplus!(dest, row, A, B)
	nothing
end
function coldot(A::AbstractMatrix{T}, B::AbstractMatrix{T}) where T
  dest = Matrix{T}(undef, 1, size(A,2))
  coldot!(dest, 1, A, B)
  dest
end
coldot(A::AbstractMatrix) = coldot(A, A)
coldot(A::AbstractVector, B::AbstractVector) = [dot(A,B)]

function coldotplus!(dest::AbstractMatrix, row::Integer, A::AbstractMatrix, B::AbstractMatrix)
  @tturbo for i ∈ eachindex(axes(A,2),axes(B,2)), j ∈ eachindex(axes(A,1),axes(B,1))
	  dest[row,i] += A[j,i] * B[j,i]
  end
	nothing
end
function coldotplus!(dest::AbstractMatrix, row::Integer, A::AbstractMatrix, v::AbstractVector, B::AbstractMatrix)
  @tturbo for i ∈ eachindex(axes(A,2),axes(B,2)), j ∈ eachindex(axes(A,1),axes(B,1))
	  dest[row,i] += A[j,i] * v[j] * B[j,i]
  end
	nothing
end

function coldotminus!(dest::AbstractVecOrMat, row::Integer, A::AbstractMatrix, B::AbstractMatrix)
  @tturbo for i ∈ eachindex(axes(A,2),axes(B,2)), j ∈ eachindex(axes(A,1),axes(B,1))
	  dest[row,i] -= A[j,i] * B[j,i]
  end
	nothing
end

# Add Q-norms of rows of A to dest; despite "!", puts result in return value too
function rowquadformplus!(dest::AbstractVector, A::AbstractMatrix, Q::AbstractMatrix, B::AbstractMatrix)
  @tturbo for i ∈ axes(A,1), j ∈ axes(A,2), k ∈ axes(A,2)
    dest[i] += A[i,j] * Q[k,j] * B[i,k]
  end
  dest
end

function rowquadform(A::AbstractMatrix{T}, Q::AbstractMatrix{T}, B::AbstractMatrix{T}) where T
	dest = Vector{T}(undef, size(A,1))
	rowquadformplus!(dest, A, Q, B)
	dest
end

function colquadformminus!(dest::AbstractMatrix, row::Integer, A::AbstractMatrix, Q::AbstractMatrix, B::AbstractMatrix)
  @tturbo for i ∈ axes(A,2), j ∈ axes(A,1), k ∈ axes(A,1)
    dest[row,i] -= A[j,i] * Q[k,j] * B[k,i]
  end
  dest
end

# compute negative of the norm of each col of A using quadratic form Q; dest should be a one-row matrix
function negcolquadform!(dest::AbstractMatrix{T}, Q::AbstractMatrix{T}, A::AbstractMatrix{T}) where T
  fill!(dest, zero(T))
	colquadformminus!(dest,1,A,Q,A)
	nothing
end

function matmulplus!(A::Matrix, B::AbstractMatrix, C::Matrix)  # add B*C to A in place
	@tturbo for i ∈ eachindex(axes(A,1),axes(B,1)), k ∈ eachindex(axes(A,2), axes(C,2)), j ∈ eachindex(axes(B,2),axes(C,1))
		A[i,k] += B[i,j] * C[j,k]
	end
	nothing
end
function matmulplus!(A::Vector, B::AbstractMatrix, C::Vector)  # add B*C to A in place
	@tturbo for j ∈ eachindex(axes(B,2),C), i ∈ eachindex(axes(A,1),axes(B,1))
		A[i] += B[i,j] * C[j]
	end
	nothing
end

# like Mata panelsetup() but can group on multiple columns, like sort(). But doesn't take minobs, maxobs arguments.
function panelsetup(X::AbstractArray{S} where S, colinds::AbstractVector{T} where T<:Integer)
  N = nrows(X)
	iszero(N) && return(Vector{UnitRange{Int64}}(undef,0))
  info = Vector{UnitRange{Int64}}(undef, N)
  lo = p = 1
  @inbounds for hi ∈ 2:N
    for j ∈ colinds
      if X[hi,j] ≠ X[lo,j]
        info[p] = lo:hi-1
        lo = hi
        p += 1
        break
      end
  	end
  end
  info[p] = lo:N
  resize!(info, p)
  info
end
# Like above but also return standardized ID variable, starting from 1
function panelsetupID(X::AbstractArray{S} where S, colinds::UnitRange{T} where T<:Integer)
  N = nrows(X)
  info = Vector{UnitRange{Int64}}(undef, N)
  ID = ones(Int64, N)
  lo = p = 1
  @inbounds for hi ∈ 2:N
    for j ∈ colinds
      if X[hi,j] ≠ X[lo,j]
        info[p] = lo:hi-1
        lo = hi
        p += 1
        break
      end
  	end
	  ID[hi] = p
  end
  info[p] = lo:N
  resize!(info, p)
  info, ID
end

# Return matrix that counts from 0 to 2^N-1 in binary, one column for each number, one row for each binary digit
# except use provided lo and hi values for 0 and 1
count_binary(N::Integer, lo::Number, hi::Number) = N≤1 ? [lo  hi] :
														  (tmp = count_binary(N-1, lo, hi);
														   [fill(lo, 1, ncols(tmp)) fill(hi, 1, ncols(tmp)) ;
																			            tmp                     tmp     ])

function panelsum!(dest::AbstractVecOrMat, X::AbstractVecOrMat, info::AbstractVector{UnitRange{T}} where T<:Integer)
	iszero(length(X)) && return
	J = CartesianIndices(axes(X)[2:end])
	eachindexJ = eachindex(J)
	@inbounds for g in eachindex(info)
		f, l = first(info[g]), last(info[g])
		fl = f+1:l
		if f<l
			for j ∈ eachindexJ
				Jj = J[j]
				tmp = X[f,Jj]
				@tturbo for i ∈ fl
					tmp += X[i,Jj]
				end
				dest[g,Jj] = tmp
			end
		else
			@simd for j ∈ eachindexJ
				dest[g,J[j]] = X[f,J[j]]
			end
		end
	end
end
function panelsum!(dest::AbstractVecOrMat{T}, X::AbstractVecOrMat{T}, wt::AbstractVector{T}, info::AbstractVector{UnitRange{S}} where S<:Integer) where T
	iszero(length(X)) && return
	if iszero(length(info)) || nrows(info)==nrows(X)
		dest .= X .* wt
		return
	end
	J = CartesianIndices(axes(X)[2:end])
	eachindexJ = eachindex(J)
	@inbounds for g in eachindex(info)
		f, l = first(info[g]), last(info[g])
    fl = f+1:l
		_wt = wt[f]
		if f<l
			for j ∈ eachindexJ
				Jj = J[j]
				tmp = X[f,Jj] * _wt
				@tturbo for i ∈ fl
					tmp += X[i,Jj] * wt[i]
				end
				dest[g,Jj] = tmp
			end
		else
			for j ∈ eachindexJ
				dest[g,J[j]] = X[f,J[j]] * _wt
			end
		end
	end
end
function panelsum!(dest::AbstractArray, X::AbstractArray{T,3} where T, info::Vector{UnitRange{S}} where S<:Integer)
  iszero(length(X)) && return
  @inbounds for g in eachindex(info)
    f, l = first(info[g]), last(info[g])
    fl = f+1:l
    if f<l
      for i ∈ axes(X,1), k ∈ axes(X,3)
        tmp = X[i,f,k]
        @tturbo for j ∈ fl
          tmp += X[i,j,k]
        end
        dest[i,g,k] = tmp
      end
    else
      for i ∈ axes(X,1), k ∈ axes(X,3)
        dest[i,g,k] = X[i,f,k]
      end
    end
  end
end

# groupwise inner product of two two data matrices
# 1st dimension of result corresponds to columns of X, second to rows of info, third to columns of Y
function panelcross!(dest::AbstractArray{T,3}, X::AbstractVecOrMat{T}, Y::AbstractVecOrMat{T}, info::Vector{UnitRange{S}} where S<:Integer) where T
	iszero(length(X)) && return
	if iszero(nrows(info)) || nrows(info)==nrows(X)
		@inbounds for i ∈ axes(Y,2)
			dest[:,:,i] .= X' .* view(Y,:,i)'
		end
		return
	elseif X===Y
    @inbounds Threads.@threads for g in eachindex(info)
      v = view(X,info[g],:)
      dest[:,g,:] = v'v
    end
  else
    fill!(dest, zero(T))
  	@inbounds for (g, infog) ∈ enumerate(info)
      @tturbo for j ∈ eachindex(axes(X,2)), k ∈ eachindex(axes(Y,2)), i ∈ infog
        dest[j,g,k] += X[i,j] * Y[i,k]
      end
    end
  end
	nothing
end
# version for two matrices on left
function panelcross!(dest::AbstractArray{T,3}, X₁::AbstractVecOrMat{T}, X₂::AbstractVecOrMat{T}, Y::AbstractVecOrMat{T}, info::Vector{UnitRange{S}} where S<:Integer) where T
	panelcross!(view(dest,            1:size(X₁  ,2),:,:), X₁, Y, info)
	panelcross!(view(dest, size(X₁,2)+1:size(dest,1),:,:), X₂, Y, info)
end
function panelcross(X::AbstractVecOrMat{T}, Y::AbstractVecOrMat{T}, info::AbstractVector{UnitRange{S}} where S<:Integer) where T
	dest = Array{T,3}(undef, size(X,2), iszero(length(info)) ? nrows(X) : length(info), size(Y,2))
	panelcross!(dest, X, Y, info)
	dest
end

function panelsum(X::AbstractVecOrMat{T}, wt::AbstractVector{T}, info::AbstractVector{UnitRange{S}} where S<:Integer) where T
	dest = isa(X, AbstractVector{T}) ? Vector{T}(undef, iszero(length(info)) ? nrows(X) : length(info)           ) :
		                                 Matrix{T}(undef, iszero(length(info)) ? nrows(X) : length(info), size(X,2))
	if iszero(length(info)) || length(info)==length(X)
		dest .= X .* wt
	else
		panelsum!(dest, X, wt, info)
	end
	dest
end
function panelsum(X::AbstractVecOrMat, info::AbstractVector{UnitRange{T}} where T<:Integer)
	dest = similar(X, iszero(length(info)) ? nrows(X) : length(info), size(X)[2:end]...)
	panelsum!(dest, X, info)
	dest
end
function panelsum(X::AbstractArray{T,3}, info::AbstractVector{UnitRange{S}} where S<:Integer) where T
	dest = Array{T,3}(undef, size(X,1), size(info,1), size(X,3))
	panelsum!(dest, X, info)
	dest
end
function panelsum2(X₁::AbstractVecOrMat{T}, X₂::AbstractVecOrMat{T}, wt::AbstractVector{T}, info::AbstractVector{UnitRange{S}} where S<:Integer) where T
	if iszero(length(X₂))
		panelsum(X₁,wt,info)
	else
		dest = Matrix{T}(undef, iszero(length(info)) ? nrows(X₁) : length(info), ncols(X₁)+ncols(X₂))
		panelsum!(view(dest, :,           1:ncols(X₁   )), X₁, wt, info)
		panelsum!(view(dest, :, ncols(X₁)+1:size(dest,2)), X₂, wt, info)
		dest
	end
end

# macros to efficiently handle result = input
macro panelsum(X, info)
	:(local _X = $(esc(X)); iszero(length($(esc(info)))) || length($(esc(info)))==size(_X,ndims(_X)==3 ? 2 : 1) ? _X : panelsum(_X, $(esc(info)) ) )
end

@inline sumpanelcross(X::Array{T} where T) = dropdims(sum(X, dims=2); dims=2)

# cross-tab sum of a column vector w.r.t. given panel info and fixed-effect var
# one row per FE, one col per other grouping
# handling multiple columns in v
# dimensions: (FEs,entries of info, cols of v)
# this facilitates reshape() to 2-D array in which results for each col of v are stacked vertically
function crosstabFE(o::StrBootTest{T}, v::AbstractVecOrMat{T}, info::Vector{UnitRange{Int64}}) where T
  dest = zeros(T, o.NFE, nrows(info), ncols(v))
	if o.haswt
		vw = v .* o.sqrtwt
		if nrows(info)>0
			@inbounds Threads.@threads for i ∈ axes(info,1)
				FEIDi = view(o._FEID, info[i])
				vi    = @view      vw[info[i],:]
				@inbounds for j ∈ axes(FEIDi,1)
					dest[FEIDi[j],i,:] += @view vi[j,:]
				end
			end
		else  # "robust" case, no clustering
			@inbounds Threads.@threads for i ∈ axes(o._FEID,1)
				dest[o._FEID[i],i,:] .= @view vw[i,:]
			end
		end
	else
		if nrows(info)>0
			@inbounds Threads.@threads for i ∈ axes(info,1)
				FEIDi = view(o._FEID, info[i])
				vi    = @view       v[info[i],:]
				@inbounds for j ∈ axes(FEIDi,1)
					dest[FEIDi[j],i,:] += @view vi[j,:]
				end
			end
		else  # "robust" case, no clustering
			@inbounds Threads.@threads for i ∈ axes(o._FEID,1)
				dest[o._FEID[i],i,:] .= @view v[i,:]
			end
		end
	end		
  dest
end

# same, transposed
function crosstabFEt(o::StrBootTest{T}, v::AbstractVector{T}, info::Vector{UnitRange{Int64}}) where T
  dest = zeros(T, nrows(info), o.NFE)
	if o.haswt
		vw = v .* o.sqrtwt
		if nrows(info)>0
			@inbounds Threads.@threads for i ∈ axes(info,1)
				FEIDi = @view o._FEID[info[i]]
				vi    = @view      vw[info[i]]
				@inbounds for j ∈ eachindex(vi, FEIDi)
					dest[i,FEIDi[j]] += vi[j]
				end
			end
		else  # "robust" case, no clustering
			@inbounds Threads.@threads for i ∈ eachindex(v,o._FEID)
				dest[i,o._FEID[i]] = vw[i]
			end
		end
	else
		if nrows(info)>0
			@inbounds Threads.@threads for i ∈ axes(info,1)
				FEIDi = @view o._FEID[info[i]]
				vi    = @view       v[info[i]]
				@inbounds for j ∈ eachindex(vi, FEIDi)
					dest[i,FEIDi[j]] += vi[j]
				end
			end
		else  # "robust" case, no clustering
			@inbounds Threads.@threads for i ∈ eachindex(v,o._FEID)
				dest[i,o._FEID[i]] = v[i]
			end
		end
	end	
  dest
end

# partial any fixed effects out of a data matrix
function partialFE!(o::StrBootTest, In::AbstractArray)
  if length(In)>0
		if o.haswt
			Threads.@threads for f ∈ o.FEs
				tmp = @view In[f.is,:]
				tmp .-= f.sqrtwt .* (f.wt'tmp)
			end
		else
			Threads.@threads for f ∈ o.FEs
				tmp = @view In[f.is,:]
				tmp .-= f.wt[1] .* sum(tmp; dims=1)
			end
		end
  end
	nothing
end
function partialFE(o::StrBootTest, In::AbstractArray)
  Out = similar(In)
  if length(In)>0
		if o.haswt
			Threads.@threads for f ∈ o.FEs
				tmp = @view In[f.is,:]
				Out[f.is,:] .= tmp .- f.sqrtwt .* (f.wt'tmp)
			end
		else
			Threads.@threads for f ∈ o.FEs
				tmp = @view In[f.is,:]
				Out[f.is,:] .= tmp .- f.wt[1] .* sum(tmp; dims=1)
			end
		end
  end
  Out
end

macro storeWtGrpResults!(dest, content)  # poor hygiene in referencing caller's o and w
  if dest == :(o.dist)
		return quote
			if isone($(esc(:o)).Nw)
				$(esc(dest)) = $(esc(content))
			else
				$(esc(dest))[$(esc(:o)).WeightGrp[$(esc(:w))]] = reshape($(esc(content)),:)
			end
		end
  else
	  return quote
			local _content = $(esc(content))
	    if isone($(esc(:o)).Nw)
	  	  $(esc(dest)) = _content
	    else
	  	  $(esc(dest))[:,$(esc(:o)).WeightGrp[$(esc(:w))]] = _content
	    end
	  end
  end
end

macro clustAccum!(X, c, Y)  # efficiently add a cluster combination-specific term, factoring in the needed multiplier and sign
  return quote
		local _Y = $(esc(Y))
	  if isone($(esc(c)))
	    if isone($(esc(:o)).clust[1].multiplier)
	  	  $(esc(X)) = $(esc(:o)).clust[1].even ? _Y : -_Y
	    else
	  	  $(esc(X)) = _Y * ($(esc(:o)).clust[1].even ? $(esc(:o)).clust[1].multiplier : -$(esc(:o)).clust[1].multiplier)
	    end
	  elseif $(esc(:o)).clust[$(esc(c))].even
	    if isone($(esc(:o)).clust[$(esc(c))].multiplier)
	  	  $(esc(X)) .+= _Y
	    else
	  	  $(esc(X)) .+= _Y .* $(esc(:o)).clust[$(esc(c))].multiplier
	    end
	  elseif isone($(esc(:o)).clust[$(esc(c))].multiplier)
	    $(esc(X)) .-= _Y
	  else
	    $(esc(X)) .-= _Y .* $(esc(:o)).clust[$(esc(c))].multiplier
	  end
  end
end

import Base.size
struct FakeArray{N} <: AbstractArray{Bool,N} size::Tuple{Vararg{Int64,N}} end # AbstractArray with almost no storage, just for LinearIndices() conversion         
FakeArray(size...) = FakeArray{length(size)}(size)
size(X::FakeArray) = X.size

# use 3-arrays to hold single-indexed sets of matrices. Index in _middle_ dimension.
import LinearAlgebra.mul!
function mul!(dest::Array{T,3}, A::AbstractArray{T,3}, B::AbstractVecOrMat{T}) where T
	_dest = reshape(dest, size(dest,1) * size(dest,2), size(dest,3))
	mul!(_dest, reshape(A, size(A,1) * size(A,2), size(A,3)), B)
	nothing
end
function mul!(dest::Array{T,3}, A::AbstractVecOrMat{T}, B::AbstractArray{T,3}) where T
	_dest = reshape(dest, size(dest,1), size(dest,2) * size(dest,3))
	mul!(_dest, A, reshape(B, size(B,1), size(B,2) * size(B,3)))
	nothing
end

import Base.*, Base.adjoint, Base.hcat, Base.vcat, Base.-, Base.inv, LinearAlgebra.pinv
@inline each(A::Array{T,3}) where T = [view(A,:,i,:) for i ∈ 1:size(A,2)]  #	eachslice(A; dims=2) more elegant but type-unstable
@inline *(A::AbstractArray{T,3}, B::AbstractVecOrMat{T}) where T = reshape(reshape(A, size(A,1) * size(A,2), size(A,3)) * B, size(A,1), size(A,2), size(B,2)) #:: Array{T,3}
@inline *(A::AbstractVecOrMat{T}, B::AbstractArray{T,3}) where T = reshape(A * reshape(B, size(B,1), size(B,2) * size(B,3)), size(A,1), size(B,2), size(B,3)) #:: Array{T,3}
@inline adjoint(A::AbstractArray{T,3} where T) = permutedims(A,(3,2,1))
@inline hcat(A::Array{T,3}, B::Array{T,3}) where T = cat(A,B; dims=3)::Array{T,3}
@inline vcat(A::Array{T,3}, B::Array{T,3}) where T = cat(A,B; dims=1)::Array{T,3}

function *(A::Array{T,3}, B::Array{T,3}) where T
	dest = zeros(T, size(A,1), size(A,2), size(B,3))
	@tturbo for i ∈ eachindex(axes(B,3)), j ∈ eachindex(axes(A,1)), g ∈ eachindex(axes(A,2)), k ∈ eachindex(axes(A,3))
		dest[j,g,i] += A[j,g,k] * B[k,g,i]
	end
	dest
end

# in-place inverse of a set of symmetric matrices
function invsym!(A::Array{T,3}) where T
	@inbounds for g ∈ eachindex(axes(A,2))
		A[:,g,:] = invsym(@view A[:,g,:])
	end
	nothing
end
function invsym(A::Array{T,3}) where T
	dest = similar(A)
	@inbounds for g ∈ eachindex(axes(A,2))
		dest[:,g,:] = invsym(@view A[:,g,:])
	end
	dest
end

@inline (-)(A::AbstractMatrix{T}, B::Array{T,3}) where T = reshape(A, (size(A,1),1,size(A,2))) .- B # would be better to overload .-, but more complicated

# delete-g inner products of two vector/matrices; returns full inner product too 
function crossjk(A::VecOrMat{T}, B::AbstractMatrix{T}, info::Vector{UnitRange{Int64}}) where T
	t = panelcross(A,B,info)
	sumt = sumpanelcross(t)
	if length(t)>0
		@tturbo for i ∈ eachindex(axes(B,2)), g ∈ eachindex(axes(info)), j ∈ eachindex(axes(A,2))
			t[j,g,i] = sumt[j,i] - t[j,g,i]
		end
	end
	(sumt, t)
end
function crossjk(A::VecOrMat{T}, B::Vector{T}, info::Vector{UnitRange{Int64}}) where T
	(sumt, t) = crossjk(A, view(B,:,:), info)
	(vec(sumt), t)
end

# helper for partialling Z from A, jackknifed. A and Z are data matrices/vectors. ZZZA is a 3-array (or 2-array if A is a vector)
# Returns {A_g - Z_g * ZZZA_g} stacked
function partialjk(A::VecOrMat{T}, Z::Matrix{T}, ZZZA::Array{T}, info::Vector{UnitRange{Int64}}) where T
	dest = similar(A)
	if length(A)>0
		for (g,G) ∈ enumerate(info)
	    @tturbo for i ∈ eachindex(axes(ZZZA,3)), j ∈ G, k ∈ eachindex(axes(Z,2))
			  dest[j,i] = A[j,i] - Z[j,k] * ZZZA[k,g,i]
	    end
		end
	end
  dest
end

# XXX needed?
@inline hcat(A::Vector{Matrix{T}}, B::Vector{Matrix{T}}) where T = hcat.(A,B)  # interpret [A B] entrywise
@inline vcat(A::Vector{Matrix{T}}, B::Vector{Matrix{T}}) where T = vcat.(A,B)  # interpret [A B] entrywise
@inline *(A::Vector{Matrix{T}}, B::Vector{Matrix{T}}) where T = A .* B
@inline *(A::Vector{Matrix{T}}, B::Union{VecOrMat{T},Adjoint{T, Matrix{T}}}) where T = [a * B for a ∈ A]
@inline *(A::Union{VecOrMat{T},Adjoint{T, Matrix{T}}}, B::Vector{Matrix{T}}) where T = [A * b for b ∈ B]
@inline tranpose(A::Vector{Matrix{T}}) where T = transpose.(A)  # transpose entrywise
@inline inv(A::Vector{Matrix{T}}) where T = inv.(A)
@inline pinv(A::Vector{Matrix{T}}) where T = pinv.(A)
