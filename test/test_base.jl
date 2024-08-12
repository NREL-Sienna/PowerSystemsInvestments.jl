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
