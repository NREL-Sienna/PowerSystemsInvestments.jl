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
