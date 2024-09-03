function construct_device!(
    container::OptimizationContainer,
    sys::PSY.System,
    ::ArgumentConstructStage,
    device_model::TechnologyModel{T, FixedOutput},
    # network_model::NetworkModel{<:PM.AbstractActivePowerModel},
) where {T <: PSY.ThermalGen}

    settings = PSIN.Settings(p_5bus)
    model = JuMP.Model(HiGHS.Optimizer)
    container = PSIN.SingleOptimizationContainer(settings, model)
    PSIN.set_time_steps!(container, 1:48)
    PSIN.set_time_steps_investments!(container, 1:2)

    devices = PSIP.get_technologies(SupplyTechnology{RenewableDispatch}, p_5bus)
    variable_type = PSIN.BuildCapacity()
    formulation = PSIN.ContinuousInvestment()
    D = PSIP.SupplyTechnology
    time_steps = PSIN.get_time_steps(container)
    PSIN.add_variable!(container, variable_type, devices, formulation)
    add_expression!(container, CumulativeCapacity(), devices, formulation)#, PSIN.AbstractTechnologyFormulation())
    objective_function!(container, devices, formulation)

    devices = PSIP.get_technologies(SupplyTechnology{RenewableDispatch}, p_5bus)
    variable_type = ActivePowerVariable()
    formulation = PSIN.BasicDispatch()
    D = PSIP.SupplyTechnology
    time_steps = PSIN.get_time_steps(container)
    PSIN.add_variable!(container, variable_type, devices, formulation)

    return
end

function construct_device!(
    ::SingleOptimizationContainer,
    ::PSY.System,
    ::ModelConstructStage,
    ::TechnologyModel{<:PSY.ThermalGen, FixedOutput},
    # network_model::NetworkModel{<:PM.AbstractPowerModel},
)

    devices = PSIP.get_technologies(SupplyTechnology{RenewableDispatch}, p_5bus)
    variable_type = ActivePowerVariable()
    objective_function!(container, devices, formulation)

    PSIN.update_objective_function!(container)

    #testing SupplyTotal
    add_expression!(container, SupplyTotal(), devices, formulation)

    #testing DemandTotal
    devices = PSIP.get_technologies(DemandRequirement{PowerLoad}, p_5bus)
    add_expression!(container, DemandTotal(), devices, formulation)

    #power balance
    PSIN.add_constraints!(
        container,
        PSIN.SupplyDemandBalance,
        PSIP.DemandRequirement{PowerLoad},
    )

    return
end
