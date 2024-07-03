mutable struct InvestmentModel{I <: InvestmentProblem, S <: SolutionAlgorithm}
    name::Symbol
    portfolio::PSIP.Portfolio
    internal::Union{Nothing, ISOPT.ModelInternal}
    store::InvestmentModelStore
    ext::Dict{String, Any}
end

function InvestmentModel{M}(
    template::AbstractInvestmentProblemTemplate,
    portfolio::PSIP.Portfolio,
    settings::Settings,
    jump_model::Union{Nothing, JuMP.Model}=nothing;
    name=nothing,
) where {M <: InvestmentProblem}
    if name === nothing
        name = nameof(M)
    elseif name isa String
        name = Symbol(name)
    end
    internal = ISOPT.ModelInternal(
        MultiOptimizationContainer(portfolio, settings, jump_model, PSY.Deterministic),
    )

    template_ = deepcopy(template)
    finalize_template!(template_, sys)
    model = DecisionModel{M}(
        name,
        template_,
        sys,
        internal,
        SimulationInfo(),
        DecisionModelStore(),
        Dict{String, Any}(),
    )
    #PSI.validate_time_series!(model)
    return model
end

function InvestmentModel{M}(
    template::AbstractInvestmentProblemTemplate,
    portfolio::PSIP.Portfolio,
    jump_model::Union{Nothing, JuMP.Model}=nothing;
    name=nothing,
    optimizer=nothing,
    horizon=UNSET_HORIZON,
    resolution=UNSET_RESOLUTION,
    portfolio_to_file=true,
    export_pwl_vars=false,
    optimizer_solve_log_print=false,
    detailed_optimizer_stats=false,
    calculate_conflict=false,
    direct_mode_optimizer=false,
    store_variable_names=false,
    check_numerical_bounds=true,
    initial_time=UNSET_INI_TIME,
    time_series_cache_size::Int=IS.TIME_SERIES_CACHE_SIZE_BYTES,
) where {M <: InvestmentProblem}
    settings = Settings(
        portfolio;
        initial_time=initial_time,
        time_series_cache_size=time_series_cache_size,
        horizon=horizon,
        resolution=resolution,
        optimizer=optimizer,
        direct_mode_optimizer=direct_mode_optimizer,
        optimizer_solve_log_print=optimizer_solve_log_print,
        detailed_optimizer_stats=detailed_optimizer_stats,
        calculate_conflict=calculate_conflict,
        portfolio_to_file=portfolio_to_file,
        export_pwl_vars=export_pwl_vars,
        check_numerical_bounds=check_numerical_bounds,
        store_variable_names=store_variable_names,
    )
    return DecisionModel{M}(template, sys, settings, jump_model; name=name)
end

function InvestmentModel(
    ::Type{I},
    ::Type{S},
    template::AbstractInvestmentProblemTemplate,
    portfolio::PSIP.Portfolio,
    jump_model::Union{Nothing, JuMP.Model}=nothing;
    kwargs...,
) where {I <: InvestmentProblem, S <: SolutionAlgorithm}
    return InvestmentModel{I, S}(template, portfolio, jump_model; kwargs...)
end

function InvestmentModel(
    template::AbstractInvestmentProblemTemplate,
    portfolio::PSIP.Portfolio,
    jump_model::Union{Nothing, JuMP.Model}=nothing;
    kwargs...,
)
    return InvestmentModel{GenericCapacityExpansion, SingleInstanceSolve}(
        template,
        portfolio,
        jump_model;
        kwargs...,
    )
end
