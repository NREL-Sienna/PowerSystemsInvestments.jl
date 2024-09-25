@testset "Test model build" begin

    template = InvestmentModelTemplate(
        DiscountedCashFlow(0.07),
        AggregateOperatingCost(),
        RepresentativePeriods([now()]),
        TransportModel(SingleRegionBalanceModel, use_slacks=false),
    )

    demand_model = PSINV.TechnologyModel(
        PSIP.DemandRequirement{PSY.PowerLoad},
        PSINV.StaticLoadInvestment,
        PSINV.BasicDispatch,
        PSINV.BasicDispatchFeasibility,
    )

    vre_model = PSINV.TechnologyModel(
        PSIP.SupplyTechnology{PSY.RenewableDispatch},
        PSINV.ContinuousInvestment,
        PSINV.BasicDispatch,
        PSINV.BasicDispatchFeasibility,
    )

    thermal_modelA = PSINV.TechnologyModel(
        PSIP.SupplyTechnology{PSY.ThermalStandard},
        PSINV.ContinuousInvestment,
        PSINV.BasicDispatch,
        PSINV.BasicDispatchFeasibility,
    )

    @test_throws MethodError InvestmentModel(template, PSINV.SingleInstanceSolve, p_5bus; bad_kwarg = 10)

    m = InvestmentModel(template, PSINV.SingleInstanceSolve, p_5bus; horizon=Dates.Millisecond(100), resolution=Dates.Millisecond(1), optimizer=HiGHS.Optimizer, portfolio_to_file=false);

    tech_models = template.technology_models
    tech_models[thermal_modelA] = ["cheap_thermal", "expensive_thermal"]
    tech_models[vre_model] = ["wind"]
    tech_models[demand_model] = ["demand"]

    @test build!(m; output_dir= mktempdir(; cleanup = true)) == PSINV.ModelBuildStatus.BUILT

    @test solve!(m) == PSINV.RunStatus.SUCCESSFULLY_FINALIZED


end