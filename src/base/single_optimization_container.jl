struct PrimalValuesCache
    variables_cache::Dict{VariableKey, AbstractArray}
    expressions_cache::Dict{ExpressionKey, AbstractArray}
end

function PrimalValuesCache()
    return PrimalValuesCache(
        Dict{VariableKey, AbstractArray}(),
        Dict{ExpressionKey, AbstractArray}(),
    )
end

function Base.isempty(pvc::PrimalValuesCache)
    return isempty(pvc.variables_cache) && isempty(pvc.expressions_cache)
end

Base.@kwdef mutable struct SingleOptimizationContainer <:
                           ISOPT.AbstractOptimizationContainer
    JuMPmodel::JuMP.Model
    time_steps::UnitRange{Int}
    time_steps_investments::UnitRange{Int}
    settings::Settings
    settings_copy::Settings
    variables::Dict{ISOPT.VariableKey, AbstractArray}
    aux_variables::Dict{ISOPT.AuxVarKey, AbstractArray}
    duals::Dict{ISOPT.ConstraintKey, AbstractArray}
    constraints::Dict{ISOPT.ConstraintKey, AbstractArray}
    objective_function::ObjectiveFunction
    expressions::Dict{ISOPT.ExpressionKey, AbstractArray}
    parameters::Dict{ISOPT.ParameterKey, ParameterContainer}
    primal_values_cache::PrimalValuesCache
    infeasibility_conflict::Dict{Symbol, Array}
    optimizer_stats::ISOPT.OptimizerStats
    metadata::ISOPT.OptimizationContainerMetadata
    #default_time_series_type::Type{<:PSY.TimeSeriesData}
end

function SingleOptimizationContainer(
    settings::Settings,
    jump_model::Union{Nothing, JuMP.Model},
)
    if jump_model !== nothing && get_direct_mode_optimizer(settings)
        throw(
            IS.ConflictingInputsError(
                "Externally provided JuMP models are not compatible with the direct model keyword argument. Use JuMP.direct_model before passing the custom model",
            ),
        )
    end

    return SingleOptimizationContainer(
        jump_model === nothing ? JuMP.Model() : jump_model,
        1:1,
        1:1,
        settings,
        copy_for_serialization(settings),
        Dict{VariableKey, AbstractArray}(),
        Dict{AuxVarKey, AbstractArray}(),
        Dict{ConstraintKey, AbstractArray}(),
        Dict{ConstraintKey, AbstractArray}(),
        ObjectiveFunction(),
        Dict{ExpressionKey, AbstractArray}(),
        Dict{ParameterKey, ParameterContainer}(),
        PrimalValuesCache(),
        Dict{Symbol, Array}(),
        ISOPT.OptimizerStats(),
        ISOPT.OptimizationContainerMetadata(),
    )
end

built_for_recurrent_solves(container::SingleOptimizationContainer) =
    container.built_for_recurrent_solves

get_default_time_series_type(container::SingleOptimizationContainer) =
    container.default_time_series_type
get_duals(container::SingleOptimizationContainer) = container.duals
get_expressions(container::SingleOptimizationContainer) = container.expressions
get_initial_conditions(container::SingleOptimizationContainer) =
    container.initial_conditions
get_initial_conditions_data(container::SingleOptimizationContainer) =
    container.initial_conditions_data
get_initial_time(container::SingleOptimizationContainer) =
    get_initial_time(container.settings)
get_jump_model(container::SingleOptimizationContainer) = container.JuMPmodel
get_metadata(container::SingleOptimizationContainer) = container.metadata
get_optimizer_stats(container::SingleOptimizationContainer) = container.optimizer_stats
get_parameters(container::SingleOptimizationContainer) = container.parameters
get_resolution(container::SingleOptimizationContainer) = get_resolution(container.settings)
get_settings(container::SingleOptimizationContainer) = container.settings
get_time_steps(container::SingleOptimizationContainer) = container.time_steps
get_time_steps_investments(container::SingleOptimizationContainer) =
    container.time_steps_investments
get_variables(container::SingleOptimizationContainer) = container.variables

set_initial_conditions_data!(container::SingleOptimizationContainer, data) =
    container.initial_conditions_data = data
get_objective_expression(container::SingleOptimizationContainer) =
    container.objective_function
is_synchronized(container::SingleOptimizationContainer) =
    container.objective_function.synchronized
set_time_steps!(container::SingleOptimizationContainer, time_steps::UnitRange{Int64}) =
    container.time_steps = time_steps
set_time_steps_investments!(
    container::SingleOptimizationContainer,
    time_steps::UnitRange{Int64},
) = container.time_steps_investments = time_steps

get_aux_variables(container::SingleOptimizationContainer) = container.aux_variables
get_base_power(container::SingleOptimizationContainer) = container.base_power
get_constraints(container::SingleOptimizationContainer) = container.constraints

function is_milp(container::SingleOptimizationContainer)::Bool
    !supports_milp(container) && return false
    if !isempty(
        JuMP.all_constraints(
            PSIN.get_jump_model(container),
            JuMP.VariableRef,
            JuMP.MOI.ZeroOne,
        ),
    )
        return true
    end
    return false
end

function supports_milp(container::SingleOptimizationContainer)
    jump_model = get_jump_model(container)
    return supports_milp(jump_model)
end

function _validate_warm_start_support(JuMPmodel::JuMP.Model, warm_start_enabled::Bool)
    !warm_start_enabled && return warm_start_enabled
    solver_supports_warm_start =
        MOI.supports(JuMP.backend(JuMPmodel), MOI.VariablePrimalStart(), MOI.VariableIndex)
    if !solver_supports_warm_start
        solver_name = JuMP.solver_name(JuMPmodel)
        @warn("$(solver_name) does not support warm start")
    end
    return solver_supports_warm_start
end

function _finalize_jump_model!(container::SingleOptimizationContainer, settings::Settings)
    @debug "Instantiating the JuMP model" _group = LOG_GROUP_OPTIMIZATION_CONTAINER

    if get_direct_mode_optimizer(settings)
        optimizer = () -> MOI.instantiate(get_optimizer(settings))
        container.JuMPmodel = JuMP.direct_model(optimizer())
    elseif get_optimizer(settings) === nothing
        @debug "The optimization model has no optimizer attached" _group =
            LOG_GROUP_OPTIMIZATION_CONTAINER
    else
        JuMP.set_optimizer(PSIN.get_jump_model(container), get_optimizer(settings))
    end

    JuMPmodel = PSIN.get_jump_model(container)
    @warn "possibly remove"
    warm_start_enabled = get_warm_start(settings)
    solver_supports_warm_start = _validate_warm_start_support(JuMPmodel, warm_start_enabled)
    set_warm_start!(settings, solver_supports_warm_start)

    JuMP.set_string_names_on_creation(JuMPmodel, get_store_variable_names(settings))

    @debug begin
        JuMP.set_string_names_on_creation(JuMPmodel, true)
    end
    if get_optimizer_solve_log_print(settings)
        JuMP.unset_silent(JuMPmodel)
        @debug "optimizer unset to silent" _group = LOG_GROUP_OPTIMIZATION_CONTAINER
    else
        JuMP.set_silent(JuMPmodel)
        @debug "optimizer set to silent" _group = LOG_GROUP_OPTIMIZATION_CONTAINER
    end
    return
end

function init_optimization_container!(
    container::SingleOptimizationContainer,
    transport_model::TransportModel{T},
    port::PSIP.Portfolio,
) where {T <: AbstractTransportAggregation}
    @warn "add system units back in"
    #PSY.set_units_base_system!(sys, "SYSTEM_BASE")
    # The order of operations matter
    settings = get_settings(container)

    #=
    if get_initial_time(settings) == UNSET_INI_TIME
        if get_default_time_series_type(container) <: PSY.AbstractDeterministic
            set_initial_time!(settings, PSY.get_forecast_initial_timestamp(sys))
        elseif get_default_time_series_type(container) <: PSY.SingleTimeSeries
            ini_time, _ = PSY.check_time_series_consistency(sys, PSY.SingleTimeSeries)
            set_initial_time!(settings, ini_time)
        end
    end
    =#

    if get_resolution(settings) == UNSET_RESOLUTION
        error("Resolution not set in the model. Can't continue with the build.")
    end

    horizon_count = (get_horizon(settings) ÷ get_resolution(settings))
    @assert horizon_count > 0
    container.time_steps = 1:horizon_count

    #=
    if T <: SingleRegionBalanceModel #|| T <: AreaBalancePowerModel
        total_number_of_devices =
            length(get_available_technologies(PSIP.SupplyTechnology, port))
    else
        total_number_of_devices =
            length(get_available_technologies(PSIP.SupplyTechnology, port))
        total_number_of_devices +=
            length(get_available_technologies(PSIP.TransportTechnology, port))
    end

    # The 10e6 limit is based on the sizes of the lp benchmark problems http://plato.asu.edu/ftp/lpcom.html
    # The maximum numbers of constraints and variables in the benchmark problems is 1,918,399 and 1,259,121,
    # respectively. See also https://prod-ng.sandia.gov/techlib-noauth/access-control.cgi/2013/138847.pdf
    variable_count_estimate = length(container.time_steps) * total_number_of_devices

    if variable_count_estimate > 10e6
        @warn(
            "The lower estimate of total number of variables that will be created in the model is $(variable_count_estimate). \\
            The total number of variables might be larger than 10e6 and could lead to large build or solve times."
        )
    end
    =#

    stats = get_optimizer_stats(container)
    stats.detailed_stats = get_detailed_optimizer_stats(settings)

    _finalize_jump_model!(container, settings)
    return
end

function check_parameter_multiplier_values(multiplier_array::DenseAxisArray)
    return !all(isnan.(multiplier_array.data))
end

function check_parameter_multiplier_values(multiplier_array::SparseAxisArray)
    return !all(isnan.(values(multiplier_array.data)))
end

function check_optimization_container(container::SingleOptimizationContainer)
    for (k, param_container) in container.parameters
        valid = check_parameter_multiplier_values(param_container.multiplier_array)
        if !valid
            error("The model container has invalid values in $(encode_key_as_string(k))")
        end
    end
    container.settings_copy = copy_for_serialization(container.settings)
    return
end

function _assign_container!(container::Dict, key::OptimizationContainerKey, value)
    if haskey(container, key)
        @error "$(IS.Optimization.encode_key(key)) is already stored" sort!(
            IS.Optimization.encode_key.(keys(container)),
        )
        throw(IS.InvalidValue("$key is already stored"))
    end
    container[key] = value
    #@debug "Added container entry $(typeof(key)) $(IS.Optimization.encode_key(key))" _group =
    #    LOG_GROUP_OPTIMZATION_CONTAINER
    return
end

function has_container_key(
    container::SingleOptimizationContainer,
    ::Type{T},
    ::Type{U},
    meta=IS.Optimization.CONTAINER_KEY_EMPTY_META,
) where {T <: ExpressionType, U <: Union{PSIP.Technology, PSIP.Portfolio}}
    key = ExpressionKey(T, U, meta)
    return haskey(container.expressions, key)
end

function has_container_key(
    container::SingleOptimizationContainer,
    ::Type{T},
    ::Type{U},
    meta=IS.Optimization.CONTAINER_KEY_EMPTY_META,
) where {T <: VariableType, U <: Union{PSIP.Technology, PSIP.Portfolio}}
    key = VariableKey(T, U, meta)
    return haskey(container.variables, key)
end

function has_container_key(
    container::SingleOptimizationContainer,
    ::Type{T},
    ::Type{U},
    meta=IS.Optimization.CONTAINER_KEY_EMPTY_META,
) where {T <: AuxVariableType, U <: Union{PSIP.Technology, PSIP.Portfolio}}
    key = AuxVarKey(T, U, meta)
    return haskey(container.aux_variables, key)
end

function has_container_key(
    container::SingleOptimizationContainer,
    ::Type{T},
    ::Type{U},
    meta=IS.Optimization.CONTAINER_KEY_EMPTY_META,
) where {T <: ConstraintType, U <: Union{PSIP.Technology, PSIP.Portfolio}}
    key = ConstraintKey(T, U, meta)
    return haskey(container.constraints, key)
end

function has_container_key(
    container::SingleOptimizationContainer,
    ::Type{T},
    ::Type{U},
    meta=IS.Optimization.CONTAINER_KEY_EMPTY_META,
) where {T <: ParameterType, U <: Union{PSIP.Technology, PSIP.Portfolio}}
    key = ParameterKey(T, U, meta)
    return haskey(container.parameters, key)
end

#=
function has_container_key(
    container:SingleOptimizationContainer,
    ::Type{T},
    ::Type{U},
    meta = IS.Optimization.CONTAINER_KEY_EMPTY_META,
) where {T <: InitialConditionType, U <: Union{PSIP.Technology, PSIP.Portfolio}}
    key = InitialConditionKey(T, U, meta)
    return haskey(container.initial_conditions, key)
end
=#

####################################### Variable Container #################################
function _add_variable_container!(
    container::SingleOptimizationContainer,
    var_key::VariableKey{T, U},
    sparse::Bool,
    axs...,
) where {T <: VariableType, U <: Union{PSIP.Technology, PSIP.Portfolio}}
    if sparse
        var_container = sparse_container_spec(JuMP.VariableRef, axs...)
    else
        var_container = container_spec(JuMP.VariableRef, axs...)
    end
    _assign_container!(container.variables, var_key, var_container)
    return var_container
end

function add_variable_container!(
    container::SingleOptimizationContainer,
    ::T,
    ::Type{U},
    axs...;
    sparse=false,
    meta=IS.Optimization.CONTAINER_KEY_EMPTY_META,
) where {T <: VariableType, U <: Union{PSIP.Technology, PSIP.Portfolio}}
    var_key = VariableKey(T, U, meta)
    return _add_variable_container!(container, var_key, sparse, axs...)
end

function add_variable_container!(
    container::SingleOptimizationContainer,
    ::T,
    ::Type{U},
    meta::String,
    axs...;
    sparse=false,
) where {T <: VariableType, U <: Union{PSIP.Technology, PSIP.Portfolio}}
    var_key = VariableKey(T, U, meta)
    return _add_variable_container!(container, var_key, sparse, axs...)
end

function _get_pwl_variables_container()
    contents = Dict{Tuple{String, Int, Int}, Any}()
    return SparseAxisArray(contents)
end

function add_variable_container!(
    container::SingleOptimizationContainer,
    ::T,
    ::Type{U};
    meta=IS.Optimization.CONTAINER_KEY_EMPTY_META,
) where {T <: SparseVariableType, U <: Union{PSIP.Technology, PSIP.Portfolio}}
    var_key = VariableKey(T, U, meta)
    _assign_container!(container.variables, var_key, _get_pwl_variables_container())
    return container.variables[var_key]
end

function get_variable_keys(container::SingleOptimizationContainer)
    return collect(keys(container.variables))
end

function get_variable(container::SingleOptimizationContainer, key::VariableKey)
    var = get(container.variables, key, nothing)
    if var === nothing
        name = IS.Optimization.encode_key(key)
        keys = IS.Optimization.encode_key.(get_variable_keys(container))
        throw(IS.InvalidValue("variable $name is not stored. $keys"))
    end
    return var
end

function get_variable(
    container::SingleOptimizationContainer,
    ::T,
    ::Type{U},
    meta::String=IS.Optimization.CONTAINER_KEY_EMPTY_META,
) where {T <: VariableType, U <: Union{PSIP.Technology, PSIP.Portfolio}}
    return get_variable(container, VariableKey(T, U, meta))
end

##################################### Constraint Container #################################
function _add_constraints_container!(
    container::SingleOptimizationContainer,
    cons_key::ConstraintKey,
    axs...;
    sparse=false,
)
    if sparse
        cons_container = sparse_container_spec(JuMP.ConstraintRef, axs...)
    else
        cons_container = container_spec(JuMP.ConstraintRef, axs...)
    end
    _assign_container!(container.constraints, cons_key, cons_container)
    return cons_container
end

function add_constraints_container!(
    container::SingleOptimizationContainer,
    ::T,
    ::Type{U},
    axs...;
    sparse=false,
    meta=IS.Optimization.CONTAINER_KEY_EMPTY_META,
) where {T <: ConstraintType, U <: Union{PSIP.Technology, PSIP.Portfolio}}
    cons_key = ConstraintKey(T, U, meta)
    return _add_constraints_container!(container, cons_key, axs...; sparse=sparse)
end

function get_constraint_keys(container::SingleOptimizationContainer)
    return collect(keys(container.constraints))
end

function get_constraint(container::SingleOptimizationContainer, key::ConstraintKey)
    var = get(container.constraints, key, nothing)
    if var === nothing
        name = IS.Optimization.encode_key(key)
        keys = IS.Optimization.encode_key.(get_constraint_keys(container))
        throw(IS.InvalidValue("constraint $name is not stored. $keys"))
    end

    return var
end

function get_constraint(
    container::SingleOptimizationContainer,
    ::T,
    ::Type{U},
    meta::String=IS.Optimization.CONTAINER_KEY_EMPTY_META,
) where {T <: ConstraintType, U <: Union{PSIP.Technology, PSIP.Portfolio}}
    return get_constraint(container, ConstraintKey(T, U, meta))
end

#=
function read_duals(container::SingleOptimizationContainer)
    return Dict(k => to_dataframe(jump_value.(v), k) for (k, v) in get_duals(container))
end
=#

##################################### Parameter Container ##################################
function _add_param_container!(
    container::SingleOptimizationContainer,
    key::ParameterKey{T, U},
    attribute::VariableValueAttributes{<:OptimizationContainerKey},
    param_type::DataType,
    axs...;
    sparse=false,
) where {T <: VariableValueParameter, U <: PSY.Component}
    if sparse
        param_array = sparse_container_spec(param_type, axs...)
        multiplier_array = sparse_container_spec(Float64, axs...)
    else
        param_array = DenseAxisArray{param_type}(undef, axs...)
        multiplier_array = fill!(DenseAxisArray{Float64}(undef, axs...), NaN)
    end
    param_container = ParameterContainer(attribute, param_array, multiplier_array)
    _assign_container!(container.parameters, key, param_container)
    return param_container
end

function _add_param_container!(
    container::SingleOptimizationContainer,
    key::ParameterKey{T, U},
    attribute::VariableValueAttributes{<:OptimizationContainerKey},
    axs...;
    sparse=false,
) where {T <: VariableValueParameter, U <: PSY.Component}
    if built_for_recurrent_solves(container) && !get_rebuild_model(get_settings(container))
        param_type = JuMP.VariableRef
    else
        param_type = Float64
    end
    return _add_param_container!(
        container,
        key,
        attribute,
        param_type,
        axs...;
        sparse=sparse,
    )
end

function _add_param_container!(
    container::SingleOptimizationContainer,
    key::ParameterKey{T, U},
    attribute::TimeSeriesAttributes{V},
    param_axs,
    multiplier_axs,
    time_steps;
    sparse=false,
) where {T <: TimeSeriesParameter, U <: PSY.Component, V <: PSY.TimeSeriesData}
    if built_for_recurrent_solves(container) && !get_rebuild_model(get_settings(container))
        param_type = JuMP.VariableRef
    else
        param_type = Float64
    end

    if sparse
        param_array = sparse_container_spec(param_type, param_axs, time_steps)
        multiplier_array = sparse_container_spec(Float64, multiplier_axs, time_steps)
    else
        param_array = DenseAxisArray{param_type}(undef, param_axs, time_steps)
        multiplier_array =
            fill!(DenseAxisArray{Float64}(undef, multiplier_axs, time_steps), NaN)
    end
    param_container = ParameterContainer(attribute, param_array, multiplier_array)
    _assign_container!(container.parameters, key, param_container)
    return param_container
end

function _add_param_container!(
    container::SingleOptimizationContainer,
    key::ParameterKey{T, U},
    attributes::CostFunctionAttributes{R},
    axs...;
    sparse=false,
) where {R, T <: ObjectiveFunctionParameter, U <: PSY.Component}
    if sparse
        param_array = sparse_container_spec(R, axs...)
        multiplier_array = sparse_container_spec(Float64, axs...)
    else
        param_array = DenseAxisArray{R}(undef, axs...)
        multiplier_array = fill!(DenseAxisArray{Float64}(undef, axs...), NaN)
    end
    param_container = ParameterContainer(attributes, param_array, multiplier_array)
    _assign_container!(container.parameters, key, param_container)
    return param_container
end

function add_param_container!(
    container::SingleOptimizationContainer,
    ::T,
    ::Type{U},
    ::Type{V},
    name::String,
    param_axs,
    multiplier_axs,
    time_steps;
    sparse=false,
    meta=IS.Optimization.CONTAINER_KEY_EMPTY_META,
) where {T <: TimeSeriesParameter, U <: PSY.Component, V <: PSY.TimeSeriesData}
    param_key = ParameterKey(T, U, meta)
    if isabstracttype(V)
        error("$V can't be abstract: $param_key")
    end
    attributes = TimeSeriesAttributes(V, name)
    return _add_param_container!(
        container,
        param_key,
        attributes,
        param_axs,
        multiplier_axs,
        time_steps;
        sparse=sparse,
    )
end

function add_param_container!(
    container::SingleOptimizationContainer,
    ::T,
    ::Type{U},
    variable_type::Type{W},
    sos_variable::SOSStatusVariable=NO_VARIABLE,
    uses_compact_power::Bool=false,
    data_type::DataType=Float64,
    axs...;
    sparse=false,
    meta=IS.Optimization.CONTAINER_KEY_EMPTY_META,
) where {T <: ObjectiveFunctionParameter, U <: PSY.Component, W <: VariableType}
    param_key = ParameterKey(T, U, meta)
    attributes =
        CostFunctionAttributes{data_type}(variable_type, sos_variable, uses_compact_power)
    return _add_param_container!(container, param_key, attributes, axs...; sparse=sparse)
end

function add_param_container!(
    container::SingleOptimizationContainer,
    ::T,
    ::Type{U},
    source_key::V,
    axs...;
    sparse=false,
    meta=IS.Optimization.CONTAINER_KEY_EMPTY_META,
) where {T <: VariableValueParameter, U <: PSY.Component, V <: OptimizationContainerKey}
    param_key = ParameterKey(T, U, meta)
    attributes = VariableValueAttributes(source_key)
    return _add_param_container!(container, param_key, attributes, axs...; sparse=sparse)
end

# FixValue parameters are created using Float64 since we employ JuMP.fix to fix the downstream
# variables.

function add_param_container!(
    container::SingleOptimizationContainer,
    ::T,
    ::Type{U},
    source_key::V,
    axs...;
    sparse=false,
    meta=IS.Optimization.CONTAINER_KEY_EMPTY_META,
) where {T <: FixValueParameter, U <: PSY.Component, V <: OptimizationContainerKey}
    if meta == IS.Optimization.CONTAINER_KEY_EMPTY_META
        error("$T parameters require passing the VariableType to the meta field")
    end
    param_key = ParameterKey(T, U, meta)
    attributes = VariableValueAttributes(source_key)
    return _add_param_container!(
        container,
        param_key,
        attributes,
        Float64,
        axs...;
        sparse=sparse,
    )
end

function get_parameter_keys(container::SingleOptimizationContainer)
    return collect(keys(container.parameters))
end

function get_parameter(container::SingleOptimizationContainer, key::ParameterKey)
    param_container = get(container.parameters, key, nothing)
    if param_container === nothing
        name = IS.Optimization.encode_key(key)
        throw(
            IS.InvalidValue(
                "parameter $name is not stored. $(collect(keys(container.parameters)))",
            ),
        )
    end
    return param_container
end

function get_parameter(
    container::SingleOptimizationContainer,
    ::T,
    ::Type{U},
    meta=IS.Optimization.CONTAINER_KEY_EMPTY_META,
) where {T <: ParameterType, U <: Union{PSIP.Technology, PSIP.Portfolio}}
    return get_parameter(container, ParameterKey(T, U, meta))
end

function get_parameter_array(container::SingleOptimizationContainer, key)
    return get_parameter_array(get_parameter(container, key))
end

function get_parameter_array(
    container::SingleOptimizationContainer,
    key::ParameterKey{T, U},
) where {T <: ParameterType, U <: Union{PSIP.Technology, PSIP.Portfolio}}
    return get_parameter_array(get_parameter(container, key))
end

function get_parameter_multiplier_array(
    container::SingleOptimizationContainer,
    key::ParameterKey{T, U},
) where {T <: ParameterType, U <: Union{PSIP.Technology, PSIP.Portfolio}}
    return get_multiplier_array(get_parameter(container, key))
end

function get_parameter_attributes(
    container::SingleOptimizationContainer,
    key::ParameterKey{T, U},
) where {T <: ParameterType, U <: Union{PSIP.Technology, PSIP.Portfolio}}
    return get_attributes(get_parameter(container, key))
end

function get_parameter_array(
    container::SingleOptimizationContainer,
    ::T,
    ::Type{U},
    meta=IS.Optimization.CONTAINER_KEY_EMPTY_META,
) where {T <: ParameterType, U <: Union{PSIP.Technology, PSIP.Portfolio}}
    return get_parameter_array(container, ParameterKey(T, U, meta))
end

function get_parameter_multiplier_array(
    container::SingleOptimizationContainer,
    ::T,
    ::Type{U},
    meta=IS.Optimization.CONTAINER_KEY_EMPTY_META,
) where {T <: ParameterType, U <: Union{PSIP.Technology, PSIP.Portfolio}}
    return get_multiplier_array(get_parameter(container, ParameterKey(T, U, meta)))
end

function get_parameter_attributes(
    container::SingleOptimizationContainer,
    ::T,
    ::Type{U},
    meta=IS.Optimization.CONTAINER_KEY_EMPTY_META,
) where {T <: ParameterType, U <: Union{PSIP.Technology, PSIP.Portfolio}}
    return get_attributes(get_parameter(container, ParameterKey(T, U, meta)))
end

##################################### Expression Container #################################

function _add_to_jump_expression!(
    expression::T,
    value::Float64,
) where {T <: JuMP.AbstractJuMPScalar}
    JuMP.add_to_expression!(expression, value)
    return
end

function _add_to_jump_expression!(
    expression::T,
    parameter::Float64,
    multiplier::Float64,
) where {T <: JuMP.AbstractJuMPScalar}
    _add_to_jump_expression!(expression, parameter * multiplier)
    return
end

function _add_to_jump_expression!(
    expression::T,
    var::JuMP.VariableRef,
    multiplier::Float64,
) where {T <: JuMP.AbstractJuMPScalar}
    JuMP.add_to_expression!(expression, multiplier, var)
    return
end

function _add_expression_container!(
    container::SingleOptimizationContainer,
    expr_key::ExpressionKey,
    ::Type{T},
    axs...;
    sparse=false,
) where {T <: JuMP.AbstractJuMPScalar}
    if sparse
        expr_container = sparse_container_spec(T, axs...)
    else
        expr_container = container_spec(T, axs...)
    end
    remove_undef!(expr_container)
    _assign_container!(container.expressions, expr_key, expr_container)
    return expr_container
end

function add_expression_container!(
    container::SingleOptimizationContainer,
    ::T,
    ::Type{U},
    axs...;
    sparse=false,
    meta=IS.Optimization.CONTAINER_KEY_EMPTY_META,
) where {T <: ExpressionType, U <: Union{PSIP.Technology, PSIP.Portfolio}}
    expr_key = ExpressionKey(T, U, meta)
    return _add_expression_container!(container, expr_key, GAE, axs...; sparse=sparse)
end

function get_expression_keys(container::SingleOptimizationContainer)
    return collect(keys(container.expressions))
end

function get_expression(container::SingleOptimizationContainer, key::ExpressionKey)
    var = get(container.expressions, key, nothing)
    if var === nothing
        throw(
            IS.InvalidValue(
                "constraint $key is not stored. $(collect(keys(container.expressions)))",
            ),
        )
    end

    return var
end

function get_expression(
    container::SingleOptimizationContainer,
    ::T,
    ::Type{U},
    meta=IS.Optimization.CONTAINER_KEY_EMPTY_META,
) where {T <: ExpressionType, U <: Union{PSIP.Technology, PSIP.Portfolio}}
    return get_expression(container, ExpressionKey(T, U, meta))
end

function get_expression(
    container::SingleOptimizationContainer,
    ::T,
    meta=IS.Optimization.CONTAINER_KEY_EMPTY_META,
) where {T <: ExpressionType}
    return get_expression(container, ExpressionKey(T, meta))
end

##################################### Objective Function Container #################################
function update_objective_function!(container::SingleOptimizationContainer)
    JuMP.@objective(
        get_jump_model(container),
        get_sense(container.objective_function),
        get_objective_expression(container.objective_function)
    )
    return
end

function add_to_objective_operations_expression!(
    container::SingleOptimizationContainer,
    cost_expr::T,
) where {T <: JuMP.AbstractJuMPScalar}
    T_cf = typeof(container.objective_function.operation_terms)
    if T_cf <: JuMP.GenericAffExpr && T <: JuMP.GenericQuadExpr
        container.objective_function.operation_terms += cost_expr
    else
        JuMP.add_to_expression!(container.objective_function.operation_terms, cost_expr)
    end
    return
end

function add_to_objective_investment_expression!(
    container::SingleOptimizationContainer,
    cost_expr::T,
) where {T <: JuMP.AbstractJuMPScalar}
    T_cf = typeof(container.objective_function.capital_terms)
    if T_cf <: JuMP.GenericAffExpr && T <: JuMP.GenericQuadExpr
        container.objective_function.capital_terms += cost_expr
    else
        JuMP.add_to_expression!(container.objective_function.capital_terms, cost_expr)
    end
    return
end

##### Initialize Expressions #####

function _make_container_array(ax...)
    return remove_undef!(DenseAxisArray{GAE}(undef, ax...))
end

function _make_system_expressions!(
    container::SingleOptimizationContainer,
    ::Type{SingleRegionBalanceModel},
)
    @error "Hard Code TimeSteps"
    time_steps = 1:48
    container.time_steps = 1:48
    container.time_steps_investments = 1:2
    container.expressions = Dict(
        ExpressionKey(EnergyBalance, PSIP.Portfolio) =>
            _make_container_array(["SingleRegion"], time_steps),
    )
    return
end

function initialize_system_expressions!(
    container::SingleOptimizationContainer,
    transport_model::TransportModel{T},
    port::PSIP.Portfolio,
) where {T <: SingleRegionBalanceModel}
    _make_system_expressions!(container, T)
    return
end

###################################Initial Conditions Containers############################

function calculate_aux_variables!(container::SingleOptimizationContainer, port::PSIP.Portfolio)
    aux_vars = get_aux_variables(container)
    for key in keys(aux_vars)
        calculate_aux_variable_value!(container, key, port)
    end
    return RunStatus.SUCCESSFULLY_FINALIZED
end

function _calculate_dual_variables_discrete_model!(
    container::SingleOptimizationContainer,
    ::PSIP.Portfolio,
)
    return _process_duals(container, container.settings.optimizer)
end

function calculate_dual_variables!(
    container::SingleOptimizationContainer,
    port::PSIP.Portfolio,
    is_milp::Bool,
)
    isempty(get_duals(container)) && return RunStatus.SUCCESSFULLY_FINALIZED
    if is_milp
        status = _calculate_dual_variables_discrete_model!(container, port)
    else
        status = _calculate_dual_variables_continous_model!(container, port)
    end
    return
end

##### Build Models #######

function build_model!(
    container::SingleOptimizationContainer,
    template::InvestmentModelTemplate,
    port::PSIP.Portfolio,
)
    #transmission = get_transport_formulation(template)
    transport_model = get_transport_model(template)
    initialize_system_expressions!(container, transport_model, port)

    tech_names = collect(values(template.technology_models))
    tech_templates = collect(keys(template.technology_models))
    # Order is required
    @error "Remember to restore availability code here"
    for (i, name_list) in enumerate(tech_names)
        tech_model = tech_templates[i]
        @show name_list
        @debug "Building Model for $(get_technology_type(tech_model)) with $(get_investment_formulation(tech_model)) investment formulation" _group =
        LOG_GROUP_OPTIMIZATION_CONTAINER
        TimerOutputs.@timeit BUILD_PROBLEMS_TIMER "$(get_technology_type(tech_model))" begin
            if validate_available_technologies(tech_model, port)
                for mod in [template.capital_model, template.operation_model] # template.feasibility_model
                    construct_technologies!(
                        container,
                        port,
                        name_list,
                        ArgumentConstructStage(),
                        mod,
                        tech_model,
                        #transmission_model,
                    )
                end
            end
            @debug "Problem size:" get_problem_size(container) _group =
                LOG_GROUP_OPTIMIZATION_CONTAINER
        end
    end

    # Requirements Arguments Eventually
    #=
    TimerOutputs.@timeit BUILD_PROBLEMS_TIMER "Services" begin
        construct_services!(
            container,
            sys,
            ArgumentConstructStage(),
            get_service_models(template),
            get_device_models(template),
            transmission_model,
        )
    end
    =#

    # Transportation Model Arguments
    #= Transportation Model Arguments
    for branch_model in values(template.branches)
        @debug "Building Arguments for $(get_component_type(branch_model)) with $(get_formulation(branch_model)) formulation" _group =
            LOG_GROUP_OPTIMIZATION_CONTAINER
        TimerOutputs.@timeit BUILD_PROBLEMS_TIMER "$(get_component_type(branch_model))" begin
            if validate_available_devices(branch_model, sys)
                construct_device!(
                    container,
                    sys,
                    ArgumentConstructStage(),
                    branch_model,
                    transmission_model,
                )
            end
            @debug "Problem size:" get_problem_size(container) _group =
                LOG_GROUP_OPTIMIZATION_CONTAINER
        end
    end
    =#

    # TODO: Add Constraints for this
    # iterate over tech_names and pull corresponding technologymodel
    # pass both tech model and name to construct_technologies

    for (i, name_list) in enumerate(tech_names)
        tech_model = tech_templates[i]
        @debug "Building Model for $(get_technology_type(tech_model)) with $(get_investment_formulation(tech_model)) investment formulation" _group =
            LOG_GROUP_OPTIMIZATION_CONTAINER
        TimerOutputs.@timeit BUILD_PROBLEMS_TIMER "$(get_technology_type(tech_model))" begin
            if validate_available_technologies(tech_model, port)
                for mod in [template.capital_model, template.operation_model] # template.feasibility_model
                    construct_technologies!(
                        container,
                        port,
                        name_list,
                        ModelConstructStage(),
                        mod,
                        tech_model,
                        #transmission_model,
                    )
                end
            end
            @debug "Problem size:" get_problem_size(container) _group =
                LOG_GROUP_OPTIMIZATION_CONTAINER
        end
    end
    #=
    # This function should be called after construct_device ModelConstructStage
    TimerOutputs.@timeit BUILD_PROBLEMS_TIMER "$(transport_model)" begin
        @debug "Building $(transport_model) transport formulation" _group =
            LOG_GROUP_OPTIMIZATION_CONTAINER
        construct_network!(container, sys, transport_model, template)
        @debug "Problem size:" get_problem_size(container) _group =
            LOG_GROUP_OPTIMIZATION_CONTAINER
    end

    for branch_model in values(template.branches)
        @debug "Building Model for $(get_component_type(branch_model)) with $(get_formulation(branch_model)) formulation" _group =
            LOG_GROUP_OPTIMIZATION_CONTAINER
        TimerOutputs.@timeit BUILD_PROBLEMS_TIMER "$(get_component_type(branch_model))" begin
            if validate_available_devices(branch_model, sys)
                construct_device!(
                    container,
                    sys,
                    ModelConstructStage(),
                    branch_model,
                    transmission_model,
                )
            end
            @debug "Problem size:" get_problem_size(container) _group =
                LOG_GROUP_OPTIMIZATION_CONTAINER
        end
    end
    
    TimerOutputs.@timeit BUILD_PROBLEMS_TIMER "Services" begin
        construct_services!(
            container,
            sys,
            ModelConstructStage(),
            get_service_models(template),
            get_device_models(template),
            transmission_model,
        )
    end
    =#
    TimerOutputs.@timeit BUILD_PROBLEMS_TIMER "Objective" begin
        @debug "Building Objective" _group = LOG_GROUP_OPTIMIZATION_CONTAINER
        update_objective_function!(container)
    end
    @debug "Total operation count $(PSI.get_jump_model(container).operator_counter)" _group =
        LOG_GROUP_OPTIMIZATION_CONTAINER

    check_optimization_container(container)
    return
end

"""
Default solve method for OptimizationContainer
"""
function solve_model!(
    container::SingleOptimizationContainer,
    port::PSIP.Portfolio
)
    optimizer_stats = get_optimizer_stats(container)

    jump_model = get_jump_model(container)

    model_status = MOI.NO_SOLUTION::MOI.ResultStatusCode
    conflict_status = MOI.COMPUTE_CONFLICT_NOT_CALLED

    try_count = 0
    while model_status != MOI.FEASIBLE_POINT::MOI.ResultStatusCode
        _,
        optimizer_stats.timed_solve_time,
        optimizer_stats.solve_bytes_alloc,
        optimizer_stats.sec_in_gc = @timed JuMP.optimize!(jump_model)
        model_status = JuMP.primal_status(jump_model)

        if model_status != MOI.FEASIBLE_POINT::MOI.ResultStatusCode
            if get_calculate_conflict(get_settings(container))
                @warn "Optimizer returned $model_status computing conflict"
                conflict_status = compute_conflict!(container)
                if conflict_status == MOI.CONFLICT_FOUND
                    return RunStatus.FAILED
                end
            else
                @warn "Optimizer returned $model_status trying optimize! again"
            end

            try_count += 1
            if try_count > MAX_OPTIMIZE_TRIES
                @error "Optimizer returned $model_status after $MAX_OPTIMIZE_TRIES optimize! attempts"
                return RunStatus.FAILED
            end
        end
    end

    _, optimizer_stats.timed_calculate_aux_variables =
        @timed calculate_aux_variables!(container, port)

    # Needs to be called here to avoid issues when getting duals from MILPs
    write_optimizer_stats!(container)

    _, optimizer_stats.timed_calculate_dual_variables =
        @timed calculate_dual_variables!(container, port, is_milp(container))

    status = RunStatus.SUCCESSFULLY_FINALIZED

    return status
end

function write_optimizer_stats!(container::SingleOptimizationContainer)
    write_optimizer_stats!(get_optimizer_stats(container), get_jump_model(container))
    return
end

"""
Exports the OpModel JuMP object in MathOptFormat
"""
function serialize_optimization_model(container::SingleOptimizationContainer, save_path::String)
    serialize_jump_optimization_model(get_jump_model(container), save_path)
    return
end
