mutable struct VariationalHiddenDropout{F,M}
    p::F
    mask::M
    active::Union{Bool,Nothing}
end

Flux.trainable(::VariationalHiddenDropout) = ()

Flux.@functor VariationalHiddenDropout

function VariationalHiddenDropout(p, s)
    @assert 0 ≤ p ≤ 1
    mask = zeros(Float32, s)
    vd = VariationalHiddenDropout(p, mask, nothing)
    reset_mask!(vd)
    return vd
end

function reset_mask!(a::VariationalHiddenDropout)
    Flux.rand!(a.mask)
    return a.mask .= Flux._dropout_kernel.(a.mask, a.p, 1 - a.p)
    # Sync the mask across all processes
    # if MPI.Initialized() && MPI.Comm_size(MPI.COMM_WORLD) > 1
    #     safe_bcast!(a.mask, 0, MPI.COMM_WORLD)
    # end
end

Zygote.@nograd reset_mask!

function (a::VariationalHiddenDropout)(x)
    Flux._isactive(a) || return x
    is_mask_reset_allowed() && reset_mask!(a)
    return variational_hidden_dropout(x, a.mask; active=true)
end

function Flux.testmode!(m::VariationalHiddenDropout, mode=true)
    return (m.active = (isnothing(mode) || mode == :auto) ? nothing : !mode; m)
end

function Base.show(io::IO, d::VariationalHiddenDropout)
    print(io, "VariationalDropout(", d.p)
    print(io, ", size = $(repr(size(d.mask)))")
    return print(io, ")")
end

function variational_hidden_dropout(x, mask; active::Bool=true)
    active || return x
    return x .* mask
end

Zygote.@adjoint function variational_hidden_dropout(x, mask; active::Bool=true)
    active || return x, Δ -> (Δ, nothing)
    return x .* mask, Δ -> (Δ .* mask, nothing)
end
