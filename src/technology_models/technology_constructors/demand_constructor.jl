function construct_technologies!(
    container::SingleOptimizationContainer,
    p::PSIP.Portfolio,
    names::Vector{String},
    ::ArgumentConstructStage,
    model::CapitalCostModel,
    technology_model::TechnologyModel{T, B, C, D},
    transport_model::TransportModel{<:AbstractTransportAggregation},
) where {
    T <: PSIP.DemandRequirement,
    B <: StaticLoadInvestment,
    C <: BasicDispatch,
    D <: FeasibilityTechnologyFormulation,
}

    #TODO: Port get_available_component functions from PSY
    #devices = PSIP.get_technologies(T, p)
    devices = [PSIP.get_technology(T, p, n) for n in names]

    return
end

function construct_technologies!(
    container::SingleOptimizationContainer,
    p::PSIP.Portfolio,
    names::Vector{String},
    ::ArgumentConstructStage,
    model::OperationCostModel,
    technology_model::TechnologyModel{T, B, C, D},
    transport_model::TransportModel{<:AbstractTransportAggregation},
    # network_model::NetworkModel{<:PM.AbstractActivePowerModel},
) where {
    T <: PSIP.DemandRequirement,
    B <: StaticLoadInvestment,
    C <: BasicDispatch,
    D <: FeasibilityTechnologyFormulation,
}

    #TODO: Port get_available_component functions from PSY
    #devices = PSIP.get_technologies(T, p)
    devices = [PSIP.get_technology(T, p, n) for n in names]

    # SupplyTotal, initialize expression, then add ActivePowerVariable in supply_constructor
    add_to_expression!(container, EnergyBalance(), devices, C(), transport_model)

    # DemandTotal
    # add_to_expression!(container, DemandTotal(), devices, C())

    return
end

function construct_technologies!(
    container::SingleOptimizationContainer,
    p::PSIP.Portfolio,
    names::Vector{String},
    ::ArgumentConstructStage,
    model::FeasibilityModel,
    technology_model::TechnologyModel{T, B, C, D},
    transport_model::TransportModel{<:AbstractTransportAggregation},
    # network_model::NetworkModel{<:PM.AbstractActivePowerModel},
) where {
    T <: PSIP.DemandRequirement,
    B <: StaticLoadInvestment,
    C <: BasicDispatch,
    D <: FeasibilityTechnologyFormulation,
}

    #TODO: Port get_available_component functions from PSY
    #devices = PSIP.get_technologies(T, p)
    devices = [PSIP.get_technology(T, p, n) for n in names]

    return
end

function construct_technologies!(
    container::SingleOptimizationContainer,
    p::PSIP.Portfolio,
    names::Vector{String},
    ::ModelConstructStage,
    model::CapitalCostModel,
    technology_model::TechnologyModel{T, B, C, D},
    transport_model::TransportModel{<:AbstractTransportAggregation},
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
    names::Vector{String},
    ::ModelConstructStage,
    model::OperationCostModel,
    technology_model::TechnologyModel{T, B, C, D},
    transport_model::TransportModel{<:AbstractTransportAggregation},
) where {
    T <: PSIP.DemandRequirement,
    B <: StaticLoadInvestment,
    C <: BasicDispatch,
    D <: FeasibilityTechnologyFormulation,
}

    #power balance
    #add_constraints!(container, SupplyDemandBalance, T)

    return
end

function construct_technologies!(
    container::SingleOptimizationContainer,
    p::PSIP.Portfolio,
    names::Vector{String},
    ::ModelConstructStage,
    model::FeasibilityModel,
    technology_model::TechnologyModel{T, B, C, D},
    transport_model::TransportModel{<:AbstractTransportAggregation},
) where {
    T <: PSIP.DemandRequirement,
    B <: StaticLoadInvestment,
    C <: BasicDispatch,
    D <: FeasibilityTechnologyFormulation,
}
    return
end
