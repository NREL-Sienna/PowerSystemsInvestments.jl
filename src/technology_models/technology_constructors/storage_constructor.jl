function construct_technologies!(
    container::SingleOptimizationContainer,
    p::PSIP.Portfolio,
    names::Vector{String},
    ::ArgumentConstructStage,
    ::CapitalCostModel,
    technology_model::TechnologyModel{T,B,C,D},
    # network_model::NetworkModel{<:PM.AbstractActivePowerModel},
) where {T<:PSIP.StorageTechnology,B<:ContinuousInvestment,C<:BasicDispatch,
    D<:FeasibilityTechnologyFormulation,}

    #TODO: Port get_available_component functions from PSY
    #devices = PSIP.get_technologies(T, p)
    devices = [PSIP.get_technology(T, p, n) for n in names]

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
    names::Vector{String},
    ::ArgumentConstructStage,
    model::OperationCostModel,
    technology_model::TechnologyModel{T,B,C,D},
    # network_model::NetworkModel{<:PM.AbstractActivePowerModel},
) where {T<:PSIP.StorageTechnology,B<:ContinuousInvestment,C<:BasicDispatch,
    D<:FeasibilityTechnologyFormulation,}

    #TODO: Port get_available_component functions from PSY
    #devices = PSIP.get_technologies(T, p)
    devices = [PSIP.get_technology(T, p, n) for n in names]
    #ActivePowerVariables
    add_variable!(container, ActiveInPowerVariable(), devices, C())
    add_variable!(container, ActiveOutPowerVariable(), devices, C())

    #EnergyVariable
    add_variable!(container, EnergyVariable(), devices, C())

    # EnergyBalance
    add_to_expression!(container, EnergyBalance(), ActiveInPowerVariable(), devices, C())
    add_to_expression!(container, EnergyBalance(), ActiveOutPowerVariable(), devices, C())
    # add_to_expression!(container, DemandTotal(), devices, C())

    return
end

function construct_technologies!(
    container::SingleOptimizationContainer,
    p::PSIP.Portfolio,
    names::Vector{String},
    ::ArgumentConstructStage,
    model::FeasibilityModel,
    technology_model::TechnologyModel{T,B,C,D},
    # network_model::NetworkModel{<:PM.AbstractActivePowerModel},
) where {T<:PSIP.StorageTechnology,B<:ContinuousInvestment,C<:BasicDispatch,
    D<:FeasibilityTechnologyFormulation,}

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
    technology_model::TechnologyModel{T,B,C,D},
    # network_model::NetworkModel{<:PM.AbstractActivePowerModel},
) where {T<:PSIP.StorageTechnology,B<:ContinuousInvestment,C<:BasicDispatch,
    D<:FeasibilityTechnologyFormulation,}
    #devices = PSIP.get_technologies(T, p)
    devices = [PSIP.get_technology(T, p, n) for n in names]


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
    names::Vector{String},
    ::ModelConstructStage,
    model::OperationCostModel,
    technology_model::TechnologyModel{T,B,C,D},
    # network_model::NetworkModel{<:PM.AbstractActivePowerModel},
) where {T<:PSIP.StorageTechnology,B<:ContinuousInvestment,C<:BasicDispatch,
    D<:FeasibilityTechnologyFormulation,}
    #devices = PSIP.get_technologies(T, p)
    devices = [PSIP.get_technology(T, p, n) for n in names]

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
    names::Vector{String},
    ::ModelConstructStage,
    model::FeasibilityModel,
    technology_model::TechnologyModel{T,B,C,D},
    # network_model::NetworkModel{<:PM.AbstractActivePowerModel},
) where {T<:PSIP.StorageTechnology,B<:ContinuousInvestment,C<:BasicDispatch,
    D<:FeasibilityTechnologyFormulation,}
    #devices = PSIP.get_technologies(T, p)
    devices = [PSIP.get_technology(T, p, n) for n in names]


    return
end
