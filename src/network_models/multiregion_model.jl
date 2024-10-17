function add_constraints!(
    container::SingleOptimizationContainer,
    ::Type{T},
    port::U,
) where {T <: MultiRegionBalanceConstraint, U <: PSIP.Portfolio}
    time_steps = get_time_steps(container)
    regions = PSIP.get_technologies(PSIP.Zone, port)
    expressions = get_expression(container, EnergyBalance(), U)
    constraint = add_constraints_container!(container, T(), U, regions, time_steps)
    for t in time_steps
        for r in regions
            constraint[r, t] = JuMP.@constraint(get_jump_model(container), expressions[r,t] == 0)
        end
    end

    return
end
