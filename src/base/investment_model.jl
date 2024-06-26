mutable struct InvestmentModel{I <: InvestmentProblem, S <: SolutionAlgorithm}
    name::Symbol
    portfolio::PSIP.Portfolio
    internal::Union{Nothing, ISOPT.ModelInternal}
    store::InvestmentModelStore
    ext::Dict{String, Any}
end
