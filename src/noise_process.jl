one_over_sqrt2 = 1/sqrt(2)
@inline wiener_randn() = randn()
@inline wiener_randn(x...) = randn(x...)
@inline wiener_randn!(x...) = randn!(x...)
@inline wiener_randn{T<:Number}(::Type{Complex{T}}) = one_over_sqrt2*(randn(T)+im*randn(T))
@inline wiener_randn{T<:Number}(::Type{Complex{T}},x...) = one_over_sqrt2*(randn(T,x...)+im*randn(T,x...))
@inline wiener_randn{T<:Number}(y::AbstractRNG,::Type{Complex{T}},x...) = one_over_sqrt2*(randn(y,T,x...)+im*randn(y,T,x...))
@inline wiener_randn{T<:Number}(y::AbstractRNG,::Type{Complex{T}}) = one_over_sqrt2*(randn(y,T)+im*randn(y,T))
@inline function wiener_randn!{T<:Number}(y::AbstractRNG,x::AbstractArray{Complex{T}})
  for i in eachindex(x)
    x[i] = one_over_sqrt2*(randn(y,T)+im*randn(y,T))
  end
end
@inline function wiener_randn!{T<:Number}(x::AbstractArray{Complex{T}})
  for i in eachindex(x)
    x[i] = one_over_sqrt2*(randn(T)+im*randn(T))
  end
end

type NoiseProcess{class,inplace,F}
  noise_func::F
end

(n::NoiseProcess)(a) = n.noise_func(a)
(n::NoiseProcess)(a...) = n.noise_func(a...)
(n::NoiseProcess)(a,b) = n.noise_func(a,b)

@inline function white_noise_func_wrapper(integrator)
  wiener_randn()
end

@inline function white_noise_func_wrapper(x::Tuple,integrator)
  wiener_randn(x)
end

@inline function white_noise_func_wrapper!(rand_vec,integrator)
  wiener_randn!(rand_vec)
end

const WHITE_NOISE = NoiseProcess{:White,false,typeof(white_noise_func_wrapper)}(white_noise_func_wrapper)
const INPLACE_WHITE_NOISE = NoiseProcess{:White,true,typeof(white_noise_func_wrapper!)}(white_noise_func_wrapper!)

"""
construct_correlated_noisefunc(Γ::AbstractArray)

Takes in a constant Covariance matrix Γ and spits out the noisefunc.
"""
function construct_correlated_noisefunc(Γ::AbstractArray)
  γ = svdfact(Γ)
  A = γ[:U]*Diagonal(√γ[:S])
  b = Vector{eltype(Γ)}(size(Γ,1))
  noise_func! = function (a)
    randn!(b)
    A_mul_B!(a,A,b)
  end
  NoiseProcess{:White,true,typeof(noise_func!)}(noise_func!)
end

isinplace{class,inplace,F}(n::NoiseProcess{class,inplace,F}) = inplace
noise_class{class,inplace,F}(n::NoiseProcess{class,inplace,F}) = class
