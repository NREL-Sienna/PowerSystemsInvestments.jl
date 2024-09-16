mutable struct InvestmentModel{S <: SolutionAlgorithm}
    name::Symbol
    template::InvestmentModelTemplate
    portfolio::PSIP.Portfolio
    internal::Union{Nothing, ISOPT.ModelInternal}
    store::InvestmentModelStore
    ext::Dict{String, Any}
end

function InvestmentModel(
    template::AbstractInvestmentModelTemplate,
    ::Type{SingleInstanceSolve},
    portfolio::PSIP.Portfolio,
    settings::Settings,
    jump_model::Union{Nothing, JuMP.Model}=nothing;
    name=nothing,
)
    if name === nothing
        name = nameof(M)
    elseif name isa String
        name = Symbol(name)
    end
    internal = ISOPT.ModelInternal(
        SingleOptimizationContainer(portfolio, settings, jump_model, PSY.Deterministic),
    )

    model = InvestmentModel(
        name,
        template,
        portfolio,
        internal,
        InvestmentsModelStore(),
        Dict{String, Any}(),
    )
    #PSI.validate_time_series!(model)
    return model
end

function InvestmentModel(
    template::AbstractInvestmentModelTemplate,
    portfolio::PSIP.Portfolio,
    jump_model::Union{Nothing, JuMP.Model}=nothing;
    name=nothing,
    optimizer=nothing,
    horizon=UNSET_HORIZON,
    resolution=UNSET_RESOLUTION,
    portfolio_to_file=true,
    optimizer_solve_log_print=false,
    detailed_optimizer_stats=false,
    calculate_conflict=false,
    direct_mode_optimizer=false,
    store_variable_names=false,
    check_numerical_bounds=true,
    initial_time=UNSET_INI_TIME,
    time_series_cache_size::Int=IS.TIME_SERIES_CACHE_SIZE_BYTES,
)
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
        check_numerical_bounds=check_numerical_bounds,
        store_variable_names=store_variable_names,
    )
    return InvestmentModel(template, sys, settings, jump_model; name=name)
end
