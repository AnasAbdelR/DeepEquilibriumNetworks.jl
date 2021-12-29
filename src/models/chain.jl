modeltype_to_val(::DeepEquilibriumNetwork) = Val(1)
modeltype_to_val(::SkipDeepEquilibriumNetwork) = Val(2)
modeltype_to_val(::MultiScaleDeepEquilibriumNetwork) = Val(3)
modeltype_to_val(::MultiScaleSkipDeepEquilibriumNetwork) = Val(4)
modeltype_to_val(::DeepEquilibriumNetwork{true}) = Val(5)
modeltype_to_val(::SkipDeepEquilibriumNetwork{M,S,true}) where {M,S} = Val(6)
modeltype_to_val(::DeepEquilibriumNetwork{false,true}) = Val(7)
modeltype_to_val(::SkipDeepEquilibriumNetwork{M,S,false,true}) where {M,S} = Val(8)
modeltype_to_val(::DeepEquilibriumNetwork{true,true}) = Val(9)
modeltype_to_val(::SkipDeepEquilibriumNetwork{M,S,true,true}) where {M,S} = Val(10)
modeltype_to_val(::MultiScaleDeepEquilibriumNetwork{true}) = Val(11)
modeltype_to_val(::MultiScaleSkipDeepEquilibriumNetwork{S,true}) where {S} = Val(12)
modeltype_to_val(m) = Val(-1)

# Default to nothing happening
reset_mask!(x) = nothing

struct DEQChain{V,P1,D,P2}
    pre_deq::P1
    deq::D
    post_deq::P2
end

function DEQChain(layers...)
    if length(layers) == 3
        pre_deq, deq, post_deq = layers
        val = modeltype_to_val(deq)
        val == Val(-1) && error("$deq must subtype AbstractDeepEquilibriumNetwork and define `modeltype_to_val`")
        return DEQChain{val,typeof(pre_deq),typeof(deq),typeof(post_deq)}(pre_deq, deq, post_deq)
    end
    pre_deq = []
    post_deq = []
    deq = nothing
    encounter_deq = false
    global_val = Val(1)
    for l in layers
        val = modeltype_to_val(l)
        if val != Val(-1)
            global_val = val
            encounter_deq && error("Can have only 1 DEQ Layer in the Chain!!!")
            deq = l
            encounter_deq = true
            continue
        end
        if encounter_deq
            push!(post_deq, l)
        else
            push!(pre_deq, l)
        end
    end
    !encounter_deq && error("No DEQ Layer in the Chain!!! Maybe you wanted to use Chain")
    pre_deq = length(pre_deq) == 0 ? NoOpLayer() : (length(pre_deq) == 1 ? pre_deq[1] : FChain(pre_deq...))
    post_deq = length(post_deq) == 0 ? NoOpLayer() : (length(post_deq) == 1 ? post_deq[1] : FChain(post_deq...))
    return DEQChain{global_val,typeof(pre_deq),typeof(deq),typeof(post_deq)}(pre_deq, deq, post_deq)
end

Flux.@functor DEQChain

function (deq::DEQChain)(x)
    x1 = deq.pre_deq(x)
    x2, deq_soln = deq.deq(x1)
    x3 = deq.post_deq(x2)
    return x3, deq_soln
end

function get_and_clear_nfe!(model::DEQChain)
    nfe = model.deq.stats.nfe
    model.deq.stats.nfe = 0
    return nfe
end

function Base.show(io::IO, model::DEQChain)
    l1 = length(destructure_parameters(model)[1])
    println(io, "DEQChain(")
    print(io, "\t")
    show(io, model.pre_deq)
    print(io, "\n\t")
    show(io, model.deq)
    print(io, "\n\t")
    show(io, model.post_deq)
    return print(io, "\n) $l1 Trainable Parameters")
end
