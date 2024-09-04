function construct_device!(
    container::SingleOptimizationContainer,
    p::PSIP.Portfolio,
    ::ArgumentConstructStage,
    technology_model::TechnologyModel{T, B, C},
    # network_model::NetworkModel{<:PM.AbstractActivePowerModel},
) where {
    T <: PSIP.SupplyTechnology,
    B <: ContinuousInvestment,
    C <: BasicDispatch
}

    #TODO: Port get_available_component functions from PSY
    devices = PSIP.get_technologies(T, p)

    #This goes in test function to build portfolio
    #settings = PSIN.Settings(p_5bus)
    #model = JuMP.Model(HiGHS.Optimizer)
    #container = PSIN.SingleOptimizationContainer(settings, model)
    #PSIN.set_time_steps!(container, 1:48)
    #PSIN.set_time_steps_investments!(container, 1:2)

    # BuildCapacity variable
    add_variable!(container, BuildCapacity(), devices, B())

    # CumulativeCapacity
    add_expression!(container, CumulativeCapacity(), devices, B())

    #ActivePowerVariable
    add_variable!(container, ActivePowerVariable(), devices, C())

    return
end

function construct_device!(
    container::SingleOptimizationContainer,
    p::PSIP.Portfolio,
    ::ModelConstructStage,
    technology_model::TechnologyModel{T, B, C},
    # network_model::NetworkModel{<:PM.AbstractActivePowerModel},
) where {
    T <: PSIP.SupplyTechnology,
    B <: ContinuousInvestment,
    C <: BasicDispatch
}

    devices = PSIP.get_technologies(T, p)

    # Capital Component of objective function
    objective_function!(container, devices, B())

    # Operations Component of objective function
    objective_function!(container, devices, D())

    # Add objective function from container to JuMP model
    update_objective_function!(container)

    # Capacity constraint
    add_constraints!(container, MaximumCumulativeCapacity(), CumulativeCapacity(), devices)

    # Dispatch constraint
    add_constraints!(container, ActivePowerLimitsConstraint(), ActivePowerVariable(), devices)

    # SupplyTotal
    add_expression!(container, SupplyTotal(), devices, C())

    # DemandTotal
    # TODO: Move to separate constructor for DemandRequirements
    devices = PSIP.get_technologies(DemandRequirement{PowerLoad}, p)
    add_expression!(container, DemandTotal(), devices, C())

    #power balance
    # TODO: Possibly move to DemandRequirements. Where should this be defined when it relies on SupplyTechnology and DemandRequirements?
    add_constraints!(
        container,
        PSIN.SupplyDemandBalance,
        PSIP.DemandRequirement{PowerLoad},
    )

    return
end
