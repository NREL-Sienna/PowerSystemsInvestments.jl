function construct_transport!(
    container::SingleOptimizationContainer,
    p::PSIP.Portfolio,
    model::TransportModel{SingleRegionBalanceModel},
    #names::Vector{String},
    #::ArgumentConstructStage,
)

    add_constraints!(container, SingleRegionBalanceConstraint, p)

end

function construct_transport!(
    container::SingleOptimizationContainer,
    p::PSIP.Portfolio,
    model::TransportModel{MultiRegionBalanceModel},
    #names::Vector{String},
    #::ArgumentConstructStage,
)

    add_constraints!(container, MultiRegionBalanceConstraint(), p)

end