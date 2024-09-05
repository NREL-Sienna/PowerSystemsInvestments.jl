#const DeviceModelForBranches = DeviceModel{<:PSY.Branch, <:AbstractDeviceFormulation}
const TechnologiesModelContainer = Dict{Symbol, TechnologyModel}
#const BranchModelContainer = Dict{Symbol, DeviceModelForBranches}
#const ServicesModelContainer = Dict{Tuple{String, Symbol}, ServiceModel}

abstract type AbstractInvestmentModelTemplate end

mutable struct InvestmentModelTemplate <: AbstractInvestmentModelTemplate
    network_model::NetworkModel{<:PM.AbstractPowerModel}
    technologies::TechnologiesModelContainer
    function InvestmentModelTemplate(
        network::NetworkModel{T},
    ) where {T <: PM.AbstractPowerModel}
        new(network, TechnologiesModelContainer())
    end
end

function Base.isempty(template::InvestmentModelTemplate)
    if !isempty(template.technologies)
        return false
    else
        return true
    end
end

InvestmentModelTemplate(::Type{T}) where {T <: PM.AbstractPowerModel} =
    InvestmentModelTemplate(NetworkModel(T))
InvestmentModelTemplate() = InvestmentModelTemplate(SingleRegionPowerModel)

get_technology_models(template::InvestmentModelTemplate) = template.technologies
get_network_model(template::InvestmentModelTemplate) = template.network_model
get_network_formulation(template::InvestmentModelTemplate) =
    get_network_formulation(get_network_model(template))

"""
Sets the network model in a template.
"""
function set_network_model!(
    template::InvestmentModelTemplate,
    model::NetworkModel{<:PM.AbstractPowerModel},
)
    template.network_model = model
    return
end

function set_device_model!(
    template::InvestmentModelTemplate,
    component_type::Type{<:PSIP.Technology},
    investment_formulation::Type{<:InvestmentTechnologyFormulation},
    operations_formulation::Type{<:OperationsTechnologyFormulation},
)
    set_device_model!(
        template,
        TechnologyModel(component_type, investment_formulation, operations_formulation),
    )
    return
end

function set_device_model!(
    template::InvestmentModelTemplate,
    model::TechnologyModel{
        <:PSIP.Technology,
        <:InvestmentTechnologyFormulation,
        <:OperationsTechnologyFormulation,
    },
)
    _set_model!(template.technologies, model)
    return
end
