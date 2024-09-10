function construct_device!(
    container::SingleOptimizationContainer,
    p::PSIP.Portfolio,
    ::ArgumentConstructStage,
    technology_model::TechnologyModel{T, B, C},
    # network_model::NetworkModel{<:PM.AbstractActivePowerModel},
) where {
    T <: PSIP.DemandRequirement,
    B <: ContinuousInvestment,
    C <: BasicDispatch
}

    #TODO: Port get_available_component functions from PSY
    devices = PSIP.get_technologies(T, p)

    # SupplyTotal, initialize expression, then add ActivePowerVariable in supply_constructor
    add_expression!(container, SupplyTotal(), C())

    # DemandTotal
    add_expression!(container, SupplyTotal(), C())

    return
end

function construct_device!(
    container::SingleOptimizationContainer,
    p::PSIP.Portfolio,
    ::ModelConstructStage,
    technology_model::TechnologyModel{T, B, C},
    # network_model::NetworkModel{<:PM.AbstractActivePowerModel},
) where {
    T <: PSIP.DemandRequirement,
    B <: ContinuousInvestment,
    C <: BasicDispatch
}

    devices = PSIP.get_technologies(T, p)

    #power balance
    add_constraints!(
        container,
        PSIN.SupplyDemandBalance,
        PSIP.DemandRequirement{PowerLoad},
    )

    return
end
