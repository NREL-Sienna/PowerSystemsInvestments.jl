function construct_technologies!(
    container::SingleOptimizationContainer,
    p::PSIP.Portfolio,
    ::ArgumentConstructStage,
    ::CapitalCostModel,
    technology_model::TechnologyModel{T,B,C,D},
    # network_model::NetworkModel{<:PM.AbstractActivePowerModel},
) where {T<:PSIP.StorageTechnology,B<:ContinuousInvestment,C<:BasicDispatch,
    D<:FeasibilityTechnologyFormulation,}

    #TODO: Port get_available_component functions from PSY
    devices = PSIP.get_technologies(T, p)

    # BuildCapacity variables
    add_variable!(container, BuildEnergyCapacity(), devices, B())
    add_variable!(container, BuildPowerCapacity(), devices, B())

    # CumulativeCapacity expressions
    add_expression!(container, CumulativePowerCapacity(), devices, B())
    add_expression!(container, CumulativeEnergyCapacity(), devices, B())
    return
end

function construct_technologies!(
    container::SingleOptimizationContainer,
    p::PSIP.Portfolio,
    ::ArgumentConstructStage,
    model::OperationCostModel,
    technology_model::TechnologyModel{T,B,C,D},
    # network_model::NetworkModel{<:PM.AbstractActivePowerModel},
) where {T<:PSIP.StorageTechnology,B<:ContinuousInvestment,C<:BasicDispatch,
    D<:FeasibilityTechnologyFormulation,}

    #TODO: Port get_available_component functions from PSY
    devices = PSIP.get_technologies(T, p)
    #ActivePowerVariables
    add_variable!(container, ActiveInPowerVariable(), devices, C())
    add_variable!(container, ActiveOutPowerVariable(), devices, C())

    #EnergyVariable
    add_variable!(container, EnergyVariable(), devices, C())

    # EnergyBalance
    add_to_expression!(container, EnergyBalance(), devices, C())
    # add_to_expression!(container, DemandTotal(), devices, C())

    return
end

function construct_technologies!(
    container::SingleOptimizationContainer,
    p::PSIP.Portfolio,
    ::ArgumentConstructStage,
    model::FeasibilityModel,
    technology_model::TechnologyModel{T,B,C,D},
    # network_model::NetworkModel{<:PM.AbstractActivePowerModel},
) where {T<:PSIP.StorageTechnology,B<:ContinuousInvestment,C<:BasicDispatch,
    D<:FeasibilityTechnologyFormulation,}

    #TODO: Port get_available_component functions from PSY
    devices = PSIP.get_technologies(T, p)

    return
end

function construct_technologies!(
    container::SingleOptimizationContainer,
    p::PSIP.Portfolio,
    ::ModelConstructStage,
    model::CapitalCostModel,
    technology_model::TechnologyModel{T,B,C,D},
    # network_model::NetworkModel{<:PM.AbstractActivePowerModel},
) where {T<:PSIP.StorageTechnology,B<:ContinuousInvestment,C<:BasicDispatch,
    D<:FeasibilityTechnologyFormulation,}
    devices = PSIP.get_technologies(T, p)


    # Capital Component of objective function
    objective_function!(container, devices, B())

    # Add objective function from container to JuMP model
    update_objective_function!(container)

    # Capacity constraints
    add_constraints!(
        container,
        MaximumCumulativePowerCapacity(),
        CumulativePowerCapacity(),
        devices,
    )

    add_constraints!(
        container,
        MaximumCumulativeEnergyCapacity(),
        CumulativeEnergyCapacity(),
        devices,
    )
    return
end

function construct_technologies!(
    container::SingleOptimizationContainer,
    p::PSIP.Portfolio,
    ::ModelConstructStage,
    model::OperationCostModel,
    technology_model::TechnologyModel{T,B,C,D},
    # network_model::NetworkModel{<:PM.AbstractActivePowerModel},
) where {T<:PSIP.StorageTechnology,B<:ContinuousInvestment,C<:BasicDispatch,
    D<:FeasibilityTechnologyFormulation,}
    devices = PSIP.get_technologies(T, p)

    # Operations Component of objective function
    objective_function!(container, devices, C())

    # Add objective function from container to JuMP model
    update_objective_function!(container)

    # Dispatch input power constraint
    add_constraints!(
        container,
        InputActivePowerVariableLimitsConstraint(),
        ActiveInPowerVariable(),
        devices,
    )

    # Dispatch output power constraint
    add_constraints!(
        container,
        OutputActivePowerVariableLimitsConstraint(),
        ActiveOutPowerVariable(),
        devices,
    )

    # Energy storage constraint
    add_constraints!(container, StateofChargeLimitsConstraint(), EnergyVariable(), devices)

    #State of charge constraint
    add_constraints!(container, EnergyBalanceConstraint(), EnergyVariable(), devices)

    return
end

function construct_technologies!(
    container::SingleOptimizationContainer,
    p::PSIP.Portfolio,
    ::ModelConstructStage,
    model::FeasibilityModel,
    technology_model::TechnologyModel{T,B,C,D},
    # network_model::NetworkModel{<:PM.AbstractActivePowerModel},
) where {T<:PSIP.StorageTechnology,B<:ContinuousInvestment,C<:BasicDispatch,
    D<:FeasibilityTechnologyFormulation,}
    devices = PSIP.get_technologies(T, p)


    return
end
