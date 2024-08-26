#! format: off
get_variable_upper_bound(::BuildCapacity, d::PSIP.SupplyTechnology, ::InvestmentTechnologyFormulation) = PSIP.get_maximum_capacity(d)
get_variable_lower_bound(::BuildCapacity, d::PSIP.SupplyTechnology, ::InvestmentTechnologyFormulation) = PSIP.get_minimum_required_capacity(d)
get_variable_binary(::BuildCapacity, d::PSIP.SupplyTechnology, ::ContinuousInvestment) = false

get_variable_lower_bound(::ActivePowerVariable, d::PSIP.SupplyTechnology, ::OperationsTechnologyFormulation) = 0.0
get_variable_upper_bound(::ActivePowerVariable, d::PSIP.SupplyTechnology, ::OperationsTechnologyFormulation) = nothing
#! format: on

function get_default_time_series_names(
    ::Type{U},
    ::Type{V},
    ::Type{W},
) where {
    U <: PSIP.SupplyTechnology,
    V <: InvestmentTechnologyFormulation,
    W <: OperationsTechnologyFormulation,
}
    return Dict{Type{<:TimeSeriesParameter}, String}()
end

function get_default_attributes(
    ::Type{U},
    ::Type{V},
    ::Type{W},
) where {
    U <: PSIP.SupplyTechnology,
    V <: InvestmentTechnologyFormulation,
    W <: OperationsTechnologyFormulation,
}
    return Dict{String, Any}()
end

################### Variables ####################

################## Expressions ###################

function add_expression!(
    container::SingleOptimizationContainer,
    expression_type::T,
    devices::U,
    formulation::AbstractTechnologyFormulation,
) where {
    T <: CumulativeCapacity,
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
} where {D <: PSIP.Technology}
    @assert !isempty(devices)
    time_steps = get_time_steps_investments(container)
    binary = false

    var = get_variable(container, BuildCapacity(), D)

    expression = add_expression_container!(
        container,
        expression_type,
        D,
        [PSIP.get_name(d) for d in devices],
        time_steps,
    )

    for t in time_steps, d in devices
        name = PSIP.get_name(d)
        expression[name, t] = JuMP.@expression(
            get_jump_model(container),
            sum(var[name, t_p] for t_p in time_steps if t_p <= t),
            #binary = binary
        )
        #ub = get_variable_upper_bound(expression_type, d, formulation)
        #ub !== nothing && JuMP.set_upper_bound(variable[name, t], ub)

        #lb = get_variable_lower_bound(expression_type, d, formulation)
        #lb !== nothing && JuMP.set_lower_bound(variable[name, t], lb)
    end

    return
end

function add_expression!(
    container::SingleOptimizationContainer,
    expression_type::T,
    devices::U,
    formulation::AbstractTechnologyFormulation,
) where {
    T <: VariableOMCost,
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
} where {D <: PSIP.Technology}
    @assert !isempty(devices)
    time_steps = get_time_steps(container)
    binary = false

    var = get_variable(container, BuildCapacity(), D)

    expression = add_expression_container!(
        container,
        expression_type,
        D,
        [PSIP.get_name(d) for d in devices],
        time_steps,
    )

    return
end

################### Constraints ##################

function add_constraints!(
    container::SingleOptimizationContainer,
    ::Type{T},
    ::V,
    devices::U,
    model,
    ::NetworkModel{X},
) where {
    T <: ActivePowerVariableLimitsConstraint,
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    V <: ActivePowerVariable,
    X <: PM.AbstractPowerModel,
} where {D <: PSIP.SupplyTechnology{PSY.RenewableDispatch}}
    time_steps = get_time_steps(container)
    # Hard Code Mapping #
    # TODO: Remove
    @warn("creating hard code mapping. Remove it later")
    mapping_ops = Dict(("2030", 1) => 1:24, ("2035", 1) => 25:48)
    mapping_inv = Dict("2030" => 1, "2035" => 2)
    device_names = PSIP.get_name.(devices)
    con_ub = add_constraints_container!(container, T(), D, device_names, time_steps)

    @warn("We should use the expression TotalCapacity rather than BuildCapacity")
    installed_cap = get_variable(container, BuildCapacity(), D)
    active_power = get_variable(container, V(), D)

    for d in devices
        name = PSIP.get_name(d)
        ts_name = "ops_variable_cap_factor"
        ts_keys = filter(x -> x.name == ts_name, IS.get_time_series_keys(d))
        for ts_key in ts_keys
            ts_type = ts_key.time_series_type
            features = ts_key.features
            year = features["year"]
            rep_day = features["rep_day"]
            ts_data = TimeSeries.values(
                IS.get_time_series(ts_type, d, ts_name; year=year, rep_day=rep_day).data,
            )
            time_steps_ix = mapping_ops[(year, rep_day)]
            time_step_inv = mapping_inv[year]

            for (ix, t) in enumerate(time_steps_ix)
                con_ub[name, t] = JuMP.@constraint(
                    get_jump_model(container),
                    active_power[name, t] <=
                    ts_data[ix] * installed_cap[name, time_step_inv]
                )
            end
        end
    end
end

#Essentially the same constraint as above, just removed the variable capacity factor since not needed
#for thermal gen
function add_constraints!(
    container::SingleOptimizationContainer,
    ::Type{T},
    ::V,
    devices::U,
    model,
    ::NetworkModel{X},
) where {
    T <: ActivePowerLimitsConstraint,
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    V <: ActivePowerVariable,
    X <: PM.AbstractPowerModel,
} where {D <: PSIP.SupplyTechnology{PSY.ThermalStandard}}
    time_steps = get_time_steps(container)
    # Hard Code Mapping #
    # TODO: Remove
    @warn("creating hard code mapping. Remove it later")
    mapping_ops = Dict(("2030", 1) => 1:24, ("2035", 1) => 25:48)
    mapping_inv = Dict("2030" => 1, "2035" => 2)
    device_names = PSIP.get_name.(devices)
    con_ub = add_constraints_container!(container, T(), D, device_names, time_steps)

    @warn("We should use the expression TotalCapacity rather than BuildCapacity")
    installed_cap = get_variable(container, BuildCapacity(), D)
    active_power = get_variable(container, V(), D)

    for d in devices
        name = PSIP.get_name(d)
        ts_name = "ops_variable_cap_factor"
        ts_keys = filter(x -> x.name == ts_name, IS.get_time_series_keys(d))
        for ts_key in ts_keys
            features = ts_key.features
            year = features["year"]
            rep_day = features["rep_day"]
            time_steps_ix = mapping_ops[(year, rep_day)]
            time_step_inv = mapping_inv[year]

            for t in time_steps_ix
                con_ub[name, t] = JuMP.@constraint(
                    get_jump_model(container),
                    active_power[name, t] <= installed_cap[name, time_step_inv]
                )
            end
        end
    end
end

# Maximum cumulative capacity
function add_constraints!(
    container::SingleOptimizationContainer,
    ::Type{T},
    ::V,
    devices::U,
    model,
    #::NetworkModel{X},
) where {
    T <: MaximumCumulativeCapacity,
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    V <: CumulativeCapacity,
    #X <: PM.AbstractPowerModel,
} where {D <: PSIP.SupplyTechnology}
    time_steps = get_time_steps_investments(container)

    device_names = PSIP.get_name.(devices)
    con_ub = add_constraints_container!(container, T(), D, device_names, time_steps)

    installed_cap = get_expression(container, CumulativeCapacity(), D)

    for d in devices
        name = PSIP.get_name(d)
        max_capacity = PSIP.get_maximum_capacity(d)
        for t in time_steps
            con_ub[name, t] = JuMP.@constraint(
                get_jump_model(container),
                installed_cap[name, t] <= max_capacity
            )
        end
    end
end

########################### Objective Function Calls#############################################
# These functions are custom implementations of the cost data. In the file objective_functions.jl there are default implementations. Define these only if needed.

function objective_function!(
    container::SingleOptimizationContainer,
    devices::IS.FlattenIteratorWrapper{T},
    ::U, #DeviceModel{T, U},
    formulation::BasicDispatch, #Type{<:PM.AbstractPowerModel},
) where {T <: PSIP.SupplyTechnology, U <: ActivePowerVariable}
    add_variable_cost!(container, ActivePowerVariable(), devices, formulation) #U()
    #add_start_up_cost!(container, StartVariable(), devices, U())
    #add_shut_down_cost!(container, StopVariable(), devices, U())
    #add_proportional_cost!(container, OnVariable(), devices, U())
    return
end

function objective_function!(
    container::SingleOptimizationContainer,
    devices::IS.FlattenIteratorWrapper{T},
    ::U, #DeviceModel{T, U},
    formulation::ContinuousInvestment, #Type{<:PM.AbstractPowerModel},
) where {T <: PSIP.SupplyTechnology, U <: BuildCapacity}
    add_capital_cost!(container, BuildCapacity(), devices, formulation) #U()
    return
end