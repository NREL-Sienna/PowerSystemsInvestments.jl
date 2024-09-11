function construct_technologies!(
    container::SingleOptimizationContainer,
    p::PSIP.Portfolio,
    ::ArgumentConstructStage,
    technology_model::TechnologyModel{T, B, C},
    # network_model::NetworkModel{<:PM.AbstractActivePowerModel},
) where {T <: PSIP.StorageTechnology, B <: ContinuousInvestment, C <: BasicDispatch}

    #TODO: Port get_available_component functions from PSY
    devices = PSIP.get_technologies(T, p)

    # BuildCapacity variables
    add_variable!(container, BuildEnergyCapacity(), devices, B())
    add_variable!(container, BuildPowerCapacity(), devices, B())

    # CumulativeCapacity expressions
    add_expression!(container, CumulativePowerCapacity(), devices, B())
    add_expression!(container, CumulativeEnergyCapacity(), devices, B())

    #ActivePowerVariables
    add_variable!(container, ActiveInPowerVariable(), devices, C())
    add_variable!(container, ActiveOutPowerVariable(), devices, C())

    #EnergyVariable
    add_variable!(container, EnergyVariable(), devices, C())

    # SupplyTotal
    #add_expression!(container, SupplyTotal(), devices, C())

    add_to_expression!(container, SupplyTotal(), devices, C())
    add_to_expression!(container, DemandTotal(), devices, C())

    return
end

function construct_technologies!(
    container::SingleOptimizationContainer,
    p::PSIP.Portfolio,
    ::ModelConstructStage,
    technology_model::TechnologyModel{T, B, C},
    # network_model::NetworkModel{<:PM.AbstractActivePowerModel},
) where {T <: PSIP.SupplyTechnology, B <: ContinuousInvestment, C <: BasicDispatch}
    devices = PSIP.get_technologies(T, p)

    # Capital Component of objective function
    objective_function!(container, devices, B())

    # Operations Component of objective function
    objective_function!(container, devices, C())

    # Add objective function from container to JuMP model
    update_objective_function!(container)

    # Capacity constraint
    add_constraints!(container, MaximumCumulativeCapacity(), CumulativeCapacity(), devices)

    # Dispatch constraint
    add_constraints!(
        container,
        ActivePowerLimitsConstraint(),
        ActivePowerVariable(),
        devices,
    )

    return
end
