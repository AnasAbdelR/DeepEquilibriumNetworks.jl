function solve_steady_state_problem(re, p, x, u0, sensealg, args...; dudt=nothing, update_nfe=() -> (), kwargs...)
    # Solving the equation f(u) - u = du = 0
    update_is_mask_reset_allowed(false)

    dudt_ = if dudt === nothing
        function (u, _p, t)
            update_nfe()
            return re(_p)(u, x) .- u
        end
    else
        dudt
    end

    ssprob = SteadyStateProblem(dudt_, u0, p)
    sol = solve(ssprob, args...; u0=u0, sensealg=sensealg, kwargs...)

    z = re(p)(sol.u, x)::typeof(x)
    update_nfe()

    update_is_mask_reset_allowed(true)

    return z
end