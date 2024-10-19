function build_impl!(model::InvestmentModel{SingleInstanceSolve})
    build_pre_step!(model)
    
    build_model!(
        get_optimization_container(model),
        get_template(model),
        get_portfolio(model),
    )
    return
end