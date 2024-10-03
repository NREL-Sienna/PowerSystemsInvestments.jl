function construct_technologies!(
    container::SingleOptimizationContainer,
    p::PSIP.Portfolio,
    name::String,
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
    #devices = PSIP.get_technologies(T, p)
    devices = PSIP.get_technology(T, p, name)

    return
end

function construct_technologies!(
    container::SingleOptimizationContainer,
    p::PSIP.Portfolio,
    name::String,
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
    #devices = PSIP.get_technologies(T, p)
    devices = PSIP.get_technology(T, p, name)

    # SupplyTotal, initialize expression, then add ActivePowerVariable in supply_constructor
    add_to_expression!(container, EnergyBalance(), devices, C())

    # DemandTotal
    # add_to_expression!(container, DemandTotal(), devices, C())

    return
end

function construct_technologies!(
    container::SingleOptimizationContainer,
    p::PSIP.Portfolio,
    name::String,
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
    #devices = PSIP.get_technologies(T, p)
    devices = PSIP.get_technology(T, p, name)


    return
end

function construct_technologies!(
    container::SingleOptimizationContainer,
    p::PSIP.Portfolio,
    name::String,
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
    name::String,
    ::ModelConstructStage,
    model::OperationCostModel,
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
    name::String,
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
