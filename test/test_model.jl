@testset "Build and solve" begin

    p_5bus = test_data()

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

    thermal_model = PSINV.TechnologyModel(
        PSIP.SupplyTechnology{PSY.ThermalStandard},
        PSINV.ContinuousInvestment,
        PSINV.BasicDispatch,
        PSINV.BasicDispatchFeasibility,
    )

    @test_throws MethodError InvestmentModel(template, PSINV.SingleInstanceSolve, p_5bus; bad_kwarg = 10)

    m = InvestmentModel(template, PSINV.SingleInstanceSolve, p_5bus; horizon=Dates.Millisecond(100), resolution=Dates.Millisecond(1), optimizer=HiGHS.Optimizer, portfolio_to_file=false);

    tech_models = template.technology_models
    tech_models[thermal_model] = ["cheap_thermal", "expensive_thermal"]
    tech_models[vre_model] = ["wind"]
    tech_models[demand_model] = ["demand"]

    @test build!(m; output_dir= mktempdir(; cleanup = true)) == PSINV.ModelBuildStatus.BUILT

    @test solve!(m) == PSINV.RunStatus.SUCCESSFULLY_FINALIZED

    res = OptimizationProblemResults(m)
    obj = res.optimizer_stats[1, :objective_value] #IS.get_objective_value(res) not working for some reason?
    @test isapprox(obj, 191957656.0; atol = 1000000.0)

    vars = res.variable_values
    @test PSINV.VariableKey(ActivePowerVariable, PSIP.SupplyTechnology{ThermalStandard}) in keys(vars)
    @test PSINV.VariableKey(ActivePowerVariable, PSIP.SupplyTechnology{RenewableDispatch}) in keys(vars)
    # Note that a lot of the read variable functions and stuff from IS don't work for investment variables because they are trying to use the operations timesteps
    #@test size(IS.Optimization.read_variable(res, PSINV.VariableKey(BuildCapacity, PSIP.SupplyTechnology{ThermalStandard}))) == (2, 2)
    #@test size(IS.Optimization.read_variable(res, PSINV.VariableKey(BuildCapacity, PSIP.SupplyTechnology{RenewableDispatch}))) == (2, 1)
    # Extra column for datetime
    @test size(IS.Optimization.read_variable(res, PSINV.VariableKey(ActivePowerVariable, PSIP.SupplyTechnology{ThermalStandard}))) == (48, 3)
    @test size(IS.Optimization.read_variable(res, PSINV.VariableKey(ActivePowerVariable, PSIP.SupplyTechnology{RenewableDispatch}))) == (48, 2)
    #@test size(IS.Optimization.read_expression(res, PSINV.VariableKey(CumulativeCapacity, PSIP.SupplyTechnology{RenewableDispatch}))) == (2, 2)

end

@testset "Test OptimizationProblemResults interfaces" begin
    p_5bus = test_data()

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

    thermal_model = PSINV.TechnologyModel(
        PSIP.SupplyTechnology{PSY.ThermalStandard},
        PSINV.ContinuousInvestment,
        PSINV.BasicDispatch,
        PSINV.BasicDispatchFeasibility,
    )

    m = InvestmentModel(template, PSINV.SingleInstanceSolve, p_5bus; horizon=Dates.Millisecond(100), resolution=Dates.Millisecond(1), optimizer=HiGHS.Optimizer, portfolio_to_file=false);

    tech_models = template.technology_models
    tech_models[thermal_model] = ["cheap_thermal", "expensive_thermal"]
    tech_models[vre_model] = ["wind"]
    tech_models[demand_model] = ["demand"]

    @test build!(m; output_dir= mktempdir(; cleanup = true)) == PSINV.ModelBuildStatus.BUILT
    @test solve!(m) == PSINV.RunStatus.SUCCESSFULLY_FINALIZED

    res = OptimizationProblemResults(m)
    @test length(IS.Optimization.list_variable_names(res)) == 4
    @test length(IS.Optimization.list_dual_names(res)) == 0
    #@test get_model_base_power(res) == 100.0
    @test isa(IS.Optimization.get_objective_value(res), Float64)
    @test isa(res.variable_values, Dict{PSINV.VariableKey, DataFrames.DataFrame})
    #@test isa(IS.Optimization.read_variables(res), Dict{String, DataFrames.DataFrame})
    @test isa(IS.Optimization.get_total_cost(res), Float64)
    @test isa(IS.Optimization.get_optimizer_stats(res), DataFrames.DataFrame)
    @test isa(res.dual_values, Dict{PSINV.ConstraintKey, DataFrames.DataFrame})
    @test isa(IS.Optimization.read_duals(res), Dict{String, DataFrames.DataFrame})
    #@test isa(PSINV.get_resolution(res), Dates.TimePeriod)
    @test isa(IS.Optimization.get_source_data(res), PSIP.Portfolio)
    @test length(PSINV.get_timestamps(res)) == 48

end