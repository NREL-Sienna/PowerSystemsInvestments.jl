Base.@kwdef mutable struct SingleOptimizationContainer <:
                           ISOPT.AbstractOptimizationContainer
    JuMPmodel::JuMP.Model
    time_steps::UnitRange{Int}
    settings::Settings
    settings_copy::Settings
    variables::Dict{ISOPT.VariableKey, AbstractArray}
    aux_variables::Dict{ISOPT.AuxVarKey, AbstractArray}
    duals::Dict{ISOPT.ConstraintKey, AbstractArray}
    constraints::Dict{ISOPT.ConstraintKey, AbstractArray}
    objective_function::ObjectiveFunction
    expressions::Dict{ISOPT.ExpressionKey, AbstractArray}
    parameters::Dict{ISOPT.ParameterKey, ParameterContainer}
    infeasibility_conflict::Dict{Symbol, Array}
    optimizer_stats::ISOPT.OptimizerStats
    metadata::ISOPT.OptimizationContainerMetadata
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
        settings,
        copy_for_serialization(settings),
        Dict{VariableKey, AbstractArray}(),
        Dict{AuxVarKey, AbstractArray}(),
        Dict{ConstraintKey, AbstractArray}(),
        Dict{ConstraintKey, AbstractArray}(),
        ObjectiveFunction(),
        Dict{ExpressionKey, AbstractArray}(),
        Dict{ParameterKey, ParameterContainer}(),
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
get_resolution(container::SingleOptimizationContainer) = container.resolution
get_settings(container::SingleOptimizationContainer) = container.settings
get_time_steps(container::SingleOptimizationContainer) = container.time_steps
get_variables(container::SingleOptimizationContainer) = container.variables

set_initial_conditions_data!(container::SingleOptimizationContainer, data) =
    container.initial_conditions_data = data
get_objective_expression(container::SingleOptimizationContainer) =
    container.objective_function
is_synchronized(container::SingleOptimizationContainer) =
    container.objective_function.synchronized
set_time_steps!(container::SingleOptimizationContainer, time_steps::UnitRange{Int64}) =
    container.time_steps = time_steps

get_aux_variables(container::SingleOptimizationContainer) = container.aux_variables
get_base_power(container::SingleOptimizationContainer) = container.base_power
get_constraints(container::SingleOptimizationContainer) = container.constraints

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
