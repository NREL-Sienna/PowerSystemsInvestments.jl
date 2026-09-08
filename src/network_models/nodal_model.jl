# Nodal power balance model: energy balance constraint at each bus (node).
# Structure mirrors multiregion_model.jl but uses PSIP.Node instead of PSIP.Zone.

function add_constraints!(
    container::SingleOptimizationContainer,
    ::Type{T},
    port::U,
    use_slacks::Bool=false,
) where {T <: NodalBalanceConstraint, U <: PSIP.Portfolio}
    time_mapping = get_time_mapping(container)
    time_steps = get_time_steps(time_mapping)
    nodes = PSIP.get_name.(PSIP.get_regions(PSIP.Node, port))
    expressions = get_expression(container, EnergyBalance(), U)
    constraint = add_constraints_container!(container, T(), U, nodes, time_steps)
    jump_model = get_jump_model(container)

    if !use_slacks
        for t in time_steps, n in nodes
            constraint[n, t] = JuMP.@constraint(jump_model, expressions[n, t] == 0)
        end
        return
    end

    # Soft power balance: expressions[n,t] + slack_up - slack_dn == 0
    #   slack_up  > 0  → unserved energy (deficit)
    #   slack_dn  > 0  → over-supply (surplus)
    # Both are penalized in the objective so they stay at zero wherever the
    # balance can feasibly be met; any nonzero slack pinpoints an unservable node.
    store_names = get_store_variable_names(get_settings(container))
    slack_up = add_variable_container!(container, BalanceSlackUp(), U, nodes, time_steps)
    slack_dn = add_variable_container!(container, BalanceSlackDown(), U, nodes, time_steps)
    for t in time_steps, n in nodes
        up = JuMP.@variable(
            jump_model,
            lower_bound = 0.0,
            base_name = store_names ? "BalanceSlackUp_{$(n), $(t)}" : "",
        )
        dn = JuMP.@variable(
            jump_model,
            lower_bound = 0.0,
            base_name = store_names ? "BalanceSlackDown_{$(n), $(t)}" : "",
        )
        slack_up[n, t] = up
        slack_dn[n, t] = dn
        constraint[n, t] =
            JuMP.@constraint(jump_model, expressions[n, t] + up - dn == 0)
        add_to_objective_operations_expression!(
            container,
            (up + dn) * BALANCE_SLACK_PENALTY,
        )
    end

    return
end
