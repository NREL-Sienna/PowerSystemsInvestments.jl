function construct_technologies!(
    container::SingleOptimizationContainer,
    p::PSIP.Portfolio,
    names::Vector{String},
    ::ArgumentConstructStage,
    ::CapitalCostModel,
    technology_model::TechnologyModel{T,B,C,D},
    # network_model::NetworkModel{<:PM.AbstractActivePowerModel},
) where {
    T<:PSIP.SupplyTechnology,
    B<:ContinuousInvestment,
    C<:BasicDispatch,
    D<:FeasibilityTechnologyFormulation,
}

    #TODO: Port get_available_component functions from PSY
    # filter based on technology names passed
    devices = [PSIP.get_technology(T, p, n) for n in names]
    #PSIP.get_technologies(T, p)

    # BuildCapacity variable
    # This should break if a name is passed here a second time
    add_variable!(container, BuildCapacity(), devices, B())

    # CumulativeCapacity
    add_expression!(container, CumulativeCapacity(), devices, B())
    return
end

function construct_technologies!(
    container::SingleOptimizationContainer,
    p::PSIP.Portfolio,
    names::Vector{String},
    ::ArgumentConstructStage,
    ::OperationCostModel,
    technology_model::TechnologyModel{T,B,C,D},
    # network_model::NetworkModel{<:PM.AbstractActivePowerModel},
) where {
    T<:PSIP.SupplyTechnology,
    B<:ContinuousInvestment,
    C<:BasicDispatch,
    D<:FeasibilityTechnologyFormulation,
}

    #TODO: Port get_available_component functions from PSY
    #devices = PSIP.get_technologies(T, p)
    devices = [PSIP.get_technology(T, p, n) for n in names]

    #ActivePowerVariable
    add_variable!(container, ActivePowerVariable(), devices, C())

    # SupplyTotal
    add_to_expression!(container, EnergyBalance(), devices, C())

    return
end

function construct_technologies!(
    container::SingleOptimizationContainer,
    p::PSIP.Portfolio,
    names::Vector{String},
    ::ArgumentConstructStage,
    ::FeasibilityModel,
    technology_model::TechnologyModel{T,B,C,D},
    # network_model::NetworkModel{<:PM.AbstractActivePowerModel},
) where {
    T<:PSIP.SupplyTechnology,
    B<:ContinuousInvestment,
    C<:BasicDispatch,
    D<:FeasibilityTechnologyFormulation,
}

    #TODO: Port get_available_component functions from PSY
    #devices = PSIP.get_technologies(T, p)
    devices = [PSIP.get_technology(T, p, n) for n in names]
    #add_expression!(container, SupplyTotal(), devices, C())
    add_variable!(container, ActivePowerVariable(), devices, C(), meta="F_var")
    # add_to_expression!(container, SupplyTotal(), devices, C())
    return
end

function construct_technologies!(
    container::SingleOptimizationContainer,
    p::PSIP.Portfolio,
    names::Vector{String},
    ::ModelConstructStage,
    model::CapitalCostModel,
    technology_model::TechnologyModel{T,B,C,D},
    # network_model::NetworkModel{<:PM.AbstractActivePowerModel},
) where {
    T<:PSIP.SupplyTechnology,
    B<:ContinuousInvestment,
    C<:BasicDispatch,
    D<:FeasibilityTechnologyFormulation,
}
    #devices = PSIP.get_technologies(T, p)
    devices = [PSIP.get_technology(T, p, n) for n in names]

    # Capital Component of objective function
    objective_function!(container, devices, B())
    # Add objective function from container to JuMP model
    update_objective_function!(container)

    # Capacity constraint
    add_constraints!(container, MaximumCumulativeCapacity(), CumulativeCapacity(), devices)

    return
end

function construct_technologies!(
    container::SingleOptimizationContainer,
    p::PSIP.Portfolio,
    names::Vector{String},
    ::ModelConstructStage,
    model::OperationCostModel,
    technology_model::TechnologyModel{T,B,C,D},
    # network_model::NetworkModel{<:PM.AbstractActivePowerModel},
) where {
    T<:PSIP.SupplyTechnology,
    B<:ContinuousInvestment,
    C<:BasicDispatch,
    D<:FeasibilityTechnologyFormulation,
}
    #devices = PSIP.get_technologies(T, p)
    devices = [PSIP.get_technology(T, p, n) for n in names]
    # Operations Component of objective function
    objective_function!(container, devices, C())

    # Add objective function from container to JuMP model
    update_objective_function!(container)
    # Capacity constraint
    # add_constraints!(container, MaximumCumulativeCapacity(), CumulativeCapacity(), devices)
    # Dispatch constraint
    add_constraints!(
        container,
        ActivePowerLimitsConstraint(),
        ActivePowerVariable(),
        devices,
    )

    return
end

function construct_technologies!(
    container::SingleOptimizationContainer,
    p::PSIP.Portfolio,
    names::Vector{String},
    ::ModelConstructStage,
    model::FeasibilityModel,
    technology_model::TechnologyModel{T,B,C,D},
    # network_model::NetworkModel{<:PM.AbstractActivePowerModel},
) where {
    T<:PSIP.SupplyTechnology,
    B<:ContinuousInvestment,
    C<:BasicDispatch,
    D<:FeasibilityTechnologyFormulation,
}
    #devices = PSIP.get_technologies(T, p)
    devices = [PSIP.get_technology(T, p, n) for n in names]

    return
end
