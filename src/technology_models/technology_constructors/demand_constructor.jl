function construct_technologies!(
    container::SingleOptimizationContainer,
    p::PSIP.Portfolio,
    ::ArgumentConstructStage,
    model::CapitalCostModel,
    technology_model::TechnologyModel{T, B, C, D},
    # network_model::NetworkModel{<:PM.AbstractActivePowerModel},
) where {
    T <: PSIP.DemandRequirement,
    B <: StaticLoadInvestment,
    C <: BasicDispatch,
    D <: FeasibilityTechnologyFormulation,
}

    #TODO: Port get_available_component functions from PSY
    devices = PSIP.get_technologies(T, p)
    return
end

function construct_technologies!(
    container::SingleOptimizationContainer,
    p::PSIP.Portfolio,
    ::ArgumentConstructStage,
    model::OperationCostModel,
    technology_model::TechnologyModel{T, B, C, D},
    # network_model::NetworkModel{<:PM.AbstractActivePowerModel},
) where {
    T <: PSIP.DemandRequirement,
    B <: StaticLoadInvestment,
    C <: BasicDispatch,
    D <: FeasibilityTechnologyFormulation,
}

    #TODO: Port get_available_component functions from PSY
    devices = PSIP.get_technologies(T, p)
    # SupplyTotal, initialize expression, then add ActivePowerVariable in supply_constructor
    add_to_expression!(container, EnergyBalance(), devices, C())

    # DemandTotal
    # add_expression!(container, DemandTotal(), devices, C())

    return
end

function construct_technologies!(
    container::SingleOptimizationContainer,
    p::PSIP.Portfolio,
    ::ArgumentConstructStage,
    model::FeasibilityModel,
    technology_model::TechnologyModel{T, B, C, D},
    # network_model::NetworkModel{<:PM.AbstractActivePowerModel},
) where {
    T <: PSIP.DemandRequirement,
    B <: StaticLoadInvestment,
    C <: BasicDispatch,
    D <: FeasibilityTechnologyFormulation,
}

    #TODO: Port get_available_component functions from PSY
    devices = PSIP.get_technologies(T, p)

    return
end

function construct_technologies!(
    container::SingleOptimizationContainer,
    p::PSIP.Portfolio,
    ::ModelConstructStage,
    model::CapitalCostModel,
    technology_model::TechnologyModel{T, B, C, D},
    # network_model::NetworkModel{<:PM.AbstractActivePowerModel},
) where {
    T <: PSIP.DemandRequirement,
    B <: StaticLoadInvestment,
    C <: BasicDispatch,
    D <: FeasibilityTechnologyFormulation,
}
    return
end

function construct_technologies!(
    container::SingleOptimizationContainer,
    p::PSIP.Portfolio,
    ::ModelConstructStage,
    model::OperationCostModel,
    ::ModelConstructStage,
    technology_model::TechnologyModel{T, B, C, D},
    # network_model::NetworkModel{<:PM.AbstractActivePowerModel},
) where {
    T <: PSIP.DemandRequirement,
    B <: StaticLoadInvestment,
    C <: BasicDispatch,
    D <: FeasibilityTechnologyFormulation,
}

    #power balance
    add_constraints!(container, SupplyDemandBalance, T)

    return
end

function construct_technologies!(
    container::SingleOptimizationContainer,
    p::PSIP.Portfolio,
    ::ModelConstructStage,
    model::FeasibilityModel,
    technology_model::TechnologyModel{T, B, C, D},
    # network_model::NetworkModel{<:PM.AbstractActivePowerModel},
) where {
    T <: PSIP.DemandRequirement,
    B <: StaticLoadInvestment,
    C <: BasicDispatch,
    D <: FeasibilityTechnologyFormulation,
}
    return
end
