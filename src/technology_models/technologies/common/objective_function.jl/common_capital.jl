##################################
####### BuildCapacity Cost #######
##################################

function add_capital_cost!(
    container::SingleOptimizationContainer,
    ::U,
    devices::Union{Vector{T}, IS.FlattenIteratorWrapper{T}},
    ::V,
    tech_model::String,
) where {T<:PSIP.SupplyTechnology,U<:BuildCapacity,V<:ContinuousInvestment}
    for d in devices
        capital_cost_data = PSIP.get_capital_costs(d)
        _add_cost_to_objective!(container, U(), d, capital_cost_data, V(), tech_model)
    end
    return
end

function add_capital_cost!(
    container::SingleOptimizationContainer,
    ::U,
    devices::Union{Vector{T}, IS.FlattenIteratorWrapper{T}},
    ::V,
    tech_model::String,
) where {T<:PSIP.ACTransportTechnology,U<:BuildCapacity,V<:ContinuousInvestment}
    for d in devices
        capital_cost_data = PSIP.get_capital_cost(d)
        _add_cost_to_objective!(container, U(), d, capital_cost_data, V(), tech_model)
    end
    return
end

function _add_proportional_term!(
    container::SingleOptimizationContainer,
    ::T,
    technology::U,
    linear_term::Float64,
    time_period::Int,
    tech_model::String
) where {T<:InvestmentVariableType,U<:PSIP.Technology}
    technology_name = PSIP.get_name(technology)
    #@debug "Linear Variable Cost" _group = LOG_GROUP_COST_FUNCTIONS component_name
    variable = get_variable(container, T(), U, tech_model)[technology_name, time_period]
    lin_cost = variable * linear_term
    add_to_objective_investment_expression!(container, lin_cost)
    return lin_cost
end

#############################
####### Fixed OM Cost #######
#############################

function add_fixed_om_cost!(
    container::SingleOptimizationContainer,
    ::U,
    devices::Union{Vector{T}, IS.FlattenIteratorWrapper{T}},
    ::V,
    tech_model::String,
) where {T<:PSIP.SupplyTechnology,U<:CumulativeCapacity,V<:ContinuousInvestment}
    for d in devices
        fixed_cost_data = PSIP.get_operation_costs(d)
        _add_cost_to_objective!(container, U(), d, fixed_cost_data, V(), tech_model)
    end
    return
end

function add_fixed_om_cost!(
    container::SingleOptimizationContainer,
    ::U,
    devices::Union{Vector{T}, IS.FlattenIteratorWrapper{T}},
    ::V,
    tech_model::String,
) where {T<:PSIP.StorageTechnology,U<:CumulativeEnergyCapacity,V<:ContinuousInvestment}
    for d in devices
        fixed_cost_data = PSIP.get_om_costs_energy(d)
        _add_cost_to_objective!(container, U(), d, fixed_cost_data, V(), tech_model)
    end
    return
end

function add_fixed_om_cost!(
    container::SingleOptimizationContainer,
    ::U,
    devices::Union{Vector{T}, IS.FlattenIteratorWrapper{T}},
    ::V,
    tech_model::String,
) where {T<:PSIP.StorageTechnology,U<:CumulativePowerCapacity,V<:ContinuousInvestment}
    for d in devices
        fixed_cost_data = PSIP.get_om_costs_power(d)
        _add_cost_to_objective!(container, U(), d, fixed_cost_data, V(), tech_model)
    end
    return
end

function _add_proportional_term!(
    container::SingleOptimizationContainer,
    ::T,
    technology::U,
    linear_term::Float64,
    time_period::Int,
    tech_model::String
) where {T<:InvestmentExpressionType,U<:PSIP.Technology}
    technology_name = PSIP.get_name(technology)
    #@debug "Linear Variable Cost" _group = LOG_GROUP_COST_FUNCTIONS component_name
    expr = get_expression(container, T(), U, tech_model)[technology_name, time_period]
    lin_cost = expr * linear_term
    add_to_objective_investment_expression!(container, lin_cost)
    return lin_cost
end


##################################
####### BuildEnergyCapacity Cost #######
##################################

function add_capital_cost!(
    container::SingleOptimizationContainer,
    ::U,
    devices::Union{Vector{T}, IS.FlattenIteratorWrapper{T}},
    ::V,
    tech_model::String,
) where {T<:PSIP.StorageTechnology,U<:BuildEnergyCapacity,V<:ContinuousInvestment}
    for d in devices
        capital_cost_data = PSIP.get_capital_costs_energy(d)
        _add_cost_to_objective!(container, U(), d, capital_cost_data, V(), tech_model)
    end
    return
end

##################################
####### BuildPowerCapacity Cost #######
##################################

function add_capital_cost!(
    container::SingleOptimizationContainer,
    ::U,
    devices::Union{Vector{T}, IS.FlattenIteratorWrapper{T}},
    ::V,
    tech_model::String,
) where {T<:PSIP.StorageTechnology,U<:BuildPowerCapacity,V<:ContinuousInvestment}
    for d in devices
        capital_cost_data = PSIP.get_capital_costs_power(d)
        _add_cost_to_objective!(container, U(), d, capital_cost_data, V(), tech_model)
    end
    return
end

