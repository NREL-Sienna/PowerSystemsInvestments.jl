@testset "Objective Function" begin
    test_obj = PSINV.ObjectiveFunction()
    @test PSINV.get_capital_terms(test_obj) == zero(AffExpr)
    @test PSINV.get_operation_terms(test_obj) == zero(AffExpr)
    @test PSINV.get_objective_expression(test_obj) == zero(AffExpr)
    @test PSINV.get_sense(test_obj) == JuMP.MOI.MIN_SENSE

    test_obj = PSINV.ObjectiveFunction()
    PSINV.add_to_capital_terms(test_obj, 10.0)
    m = JuMP.Model()
    x = JuMP.@variable(m)
    PSINV.add_to_capital_terms(test_obj, 5.0 * x)
    @test PSINV.get_capital_terms(test_obj) == 5.0 * x + 10.0

    PSINV.add_to_operation_terms(test_obj, 50.0)
    y = JuMP.@variable(m)
    PSINV.add_to_operation_terms(test_obj, 10.0 * x^2)
    @test PSINV.get_operation_terms(test_obj) == 10.0 * x^2 + 50.0

    @test PSINV.get_objective_expression(test_obj) == 10.0 * x^2 + 5.0 * x + 60.0
end

@testset "Constructor" begin
    p_5bus = test_data()

    settings = PSINV.Settings(p_5bus)
    model = JuMP.Model(HiGHS.Optimizer)
    container = PSINV.SingleOptimizationContainer(settings, model)
    PSINV.set_time_steps!(container, 1:48)
    PSINV.set_time_steps_investments!(container, 1:2)

    template = InvestmentModelTemplate(
        DiscountedCashFlow(0.07),
        AggregateOperatingCost(),
        RepresentativePeriods([now()]),
        TransportModel(SingleRegionBalanceModel, use_slacks=false),
    )

    #transmission = get_transport_formulation(template)
    transport_model = PSINV.get_transport_model(template)
    PSINV.initialize_system_expressions!(container, transport_model, p_5bus)

    #Define technology models
    demand_model = PSINV.TechnologyModel(
        PSIP.DemandRequirement{PSY.PowerLoad},
        PSINV.StaticLoadInvestment,
        PSINV.BasicDispatch,
        PSINV.BasicDispatchFeasibility
    )
    vre_model = PSINV.TechnologyModel(
        PSIP.SupplyTechnology{PSY.RenewableDispatch},
        PSINV.ContinuousInvestment,
        PSINV.BasicDispatch,
        PSINV.BasicDispatchFeasibility
    )
    thermal_model = PSINV.TechnologyModel(
        PSIP.SupplyTechnology{PSY.ThermalStandard},
        PSINV.ContinuousInvestment,
        PSINV.BasicDispatch,
        PSINV.BasicDispatchFeasibility
    )

    # Argument Stage

    #DemandRequirements
    PSINV.construct_technologies!(container, p_5bus, ["demand"], PSINV.ArgumentConstructStage(), DiscountedCashFlow(0.07), demand_model)
    PSINV.construct_technologies!(container, p_5bus, ["demand"], PSINV.ArgumentConstructStage(), AggregateOperatingCost(), demand_model)

    @test length(container.expressions) == 1
    @test length(container.variables) == 0

    #SupplyTechnology{RenewableDispatch}
    PSINV.construct_technologies!(container, p_5bus, ["wind"], PSINV.ArgumentConstructStage(), DiscountedCashFlow(0.07), vre_model)
    PSINV.construct_technologies!(container, p_5bus, ["wind"], PSINV.ArgumentConstructStage(), AggregateOperatingCost(), vre_model)

    @test length(container.expressions) == 2
    @test length(container.variables) == 2

    v = PSINV.get_variable(
        container,
        PSINV.BuildCapacity(),
        PSIP.SupplyTechnology{PSY.RenewableDispatch},
    )
    @test length(v) == 2

    v = PSINV.get_variable(
        container,
        PSINV.ActivePowerVariable(),
        PSIP.SupplyTechnology{PSY.RenewableDispatch},
    )
    @test length(v["wind", :]) == length(PSINV.get_time_steps(container))

    e = PSINV.get_expression(
        container,
        PSINV.CumulativeCapacity(),
        PSIP.SupplyTechnology{PSY.RenewableDispatch},
    )
    @test length(e["wind", :]) == length(PSINV.get_time_steps_investments(container))

    #SupplyTechnology{ThermalStandard}
    PSINV.construct_technologies!(container, p_5bus, ["cheap_thermal", "expensive_thermal"], PSINV.ArgumentConstructStage(), DiscountedCashFlow(0.07), thermal_model)
    PSINV.construct_technologies!(container, p_5bus, ["cheap_thermal", "expensive_thermal"], PSINV.ArgumentConstructStage(), AggregateOperatingCost(), thermal_model)

    @test length(container.expressions) == 3
    @test length(container.variables) == 4

    v = PSINV.get_variable(
        container,
        PSINV.BuildCapacity(),
        PSIP.SupplyTechnology{PSY.ThermalStandard},
    )
    @test length(v) == 4

    v = PSINV.get_variable(
        container,
        PSINV.ActivePowerVariable(),
        PSIP.SupplyTechnology{PSY.ThermalStandard},
    )
    @test length(v["expensive_thermal", :]) == length(PSINV.get_time_steps(container))
    @test length(v["cheap_thermal", :]) == length(PSINV.get_time_steps(container))

    e = PSINV.get_expression(
        container,
        PSINV.CumulativeCapacity(),
        PSIP.SupplyTechnology{PSY.ThermalStandard},
    )
    @test length(e["expensive_thermal", :]) ==
          length(PSINV.get_time_steps_investments(container))
    @test length(e["cheap_thermal", :]) ==
          length(PSINV.get_time_steps_investments(container))

    # Model Stage

    #DemandRequirement{PowerLoad}
    PSINV.construct_technologies!(container, p_5bus, ["demand"], PSINV.ArgumentConstructStage(), DiscountedCashFlow(0.07), demand_model)
    PSINV.construct_technologies!(container, p_5bus, ["demand"], PSINV.ArgumentConstructStage(), AggregateOperatingCost(), demand_model)

    @test length(container.constraints) == 0

    #SupplyTechnology{RenewableDispatch}
    PSINV.construct_technologies!(container, p_5bus, ["wind"], PSINV.ModelConstructStage(), DiscountedCashFlow(0.07), vre_model)
    PSINV.construct_technologies!(container, p_5bus, ["wind"], PSINV.ModelConstructStage(), AggregateOperatingCost(), vre_model)

    @test length(container.constraints) == 2

    c = PSINV.get_constraint(
        container,
        PSINV.ActivePowerLimitsConstraint(),
        PSIP.SupplyTechnology{PSY.RenewableDispatch},
    )
    @test length(c) == length(PSINV.get_time_steps(container))

    c = PSINV.get_constraint(
        container,
        PSINV.MaximumCumulativeCapacity(),
        PSIP.SupplyTechnology{PSY.RenewableDispatch},
    )
    @test length(c) == length(PSINV.get_time_steps_investments(container))

    #SupplyTechnology{RenewableDispatch}
    PSINV.construct_technologies!(container, p_5bus, ["cheap_thermal", "expensive_thermal"], PSINV.ModelConstructStage(), DiscountedCashFlow(0.07), thermal_model)
    PSINV.construct_technologies!(container, p_5bus, ["cheap_thermal", "expensive_thermal"], PSINV.ModelConstructStage(), AggregateOperatingCost(), thermal_model)

    @test length(container.constraints) == 4

    c = PSINV.get_constraint(
        container,
        PSINV.MaximumCumulativeCapacity(),
        PSIP.SupplyTechnology{PSY.ThermalStandard},
    )
    @test length(c["expensive_thermal", :]) ==
          length(PSINV.get_time_steps_investments(container))
    @test length(c["cheap_thermal", :]) ==
          length(PSINV.get_time_steps_investments(container))

    #passing same technology name with different model to constructor
    unit_thermal_model = PSINV.TechnologyModel(
        PSIP.SupplyTechnology{PSY.ThermalStandard},
        PSINV.IntegerInvestment,
        PSINV.BasicDispatch,
        PSINV.BasicDispatchFeasibility;
    )

    @test_throws ArgumentError PSINV.construct_technologies!(container, p_5bus, ["cheap_thermal"], PSINV.ArgumentConstructStage(), DiscountedCashFlow(0.07), unit_thermal_model)

end
