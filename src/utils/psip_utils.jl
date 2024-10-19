function get_available_technologies(
    model::TechnologyModel{D, A, B, C},
    port::PSIP.Portfolio,
) where {
    D <: PSIP.Technology,
    A <: InvestmentTechnologyFormulation,
    B <: OperationsTechnologyFormulation,
    C <: FeasibilityTechnologyFormulation,
}
    #subsystem = get_subsystem(model)
    #filter_function = get_attribute(model, "filter_function")
    return PSIP.get_technologies(
        PSIP.get_available,
        D,
        port;
        #subsystem_name = subsystem,
    )

end

make_portfolio_filename(port::PSIP.Portfolio) = make_portfolio_filename(IS.get_uuid(port))
make_portfolio_filename(port_uuid::Union{Base.UUID, AbstractString}) = "portfolio-$(port_uuid).json"