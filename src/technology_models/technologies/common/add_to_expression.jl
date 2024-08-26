"""
Default implementation to add technology cost variables to VariableOMCost
"""
#add_to_expression!(
#    container,
#    VariableOMCost,
#    linear_cost,
#    component,
#    time_period,
#)
function add_to_expression!(
    container::SingleOptimizationContainer,
    ::Type{S},
    cost_expression::JuMP.AbstractJuMPScalar,
    technology::T,
    time_period::Int,
) where {S <: OperationsExpressionType, T <: PSIP.SupplyTechnology}
    if has_container_key(container, S, T)
        device_cost_expression = get_expression(container, S(), T)
        component_name = PSY.get_name(technology)
        JuMP.add_to_expression!(
            device_cost_expression[component_name, time_period],
            cost_expression,
        )
    end
    return
end

function add_to_expression!(
    container::SingleOptimizationContainer,
    ::Type{S},
    cost_expression::JuMP.AbstractJuMPScalar,
    technology::T,
    time_period::Int,
) where {S <: InvestmentExpressionType, T <: PSIP.SupplyTechnology}
    if has_container_key(container, S, T)
        device_cost_expression = get_expression(container, S(), T)
        component_name = PSY.get_name(technology)
        JuMP.add_to_expression!(
            device_cost_expression[component_name, time_period],
            cost_expression,
        )
    end
    return
end