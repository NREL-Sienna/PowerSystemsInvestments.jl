abstract type AbstractTransportModel end

struct SingleRegionBalanceModel <: AbstractTransportModel end
struct MultiRegionBalanceModel <: AbstractTransportModel end
struct NodalBalanceModel <: AbstractTransportModel end

function _check_pm_formulation(::Type{T}) where {T <: AbstractTransportModel}
    if !isconcretetype(T)
        throw(
            ArgumentError(
                "The network model must contain only concrete types, $(T) is an Abstract Type",
            ),
        )
    end
end

mutable struct TransportModel{T <: AbstractTransportModel}
    use_slacks::Bool
    PTDF_matrix::Union{Nothing, PNM.PowerNetworkMatrix}
    subnetworks::Union{Nothing, Dict{Int, Set{Int}}}
    bus_area_map::Union{Nothing, Dict{PSY.ACBus, Int}}
    duals::Vector{DataType}
    subsystem::Union{Nothing, String}
    modeled_branch_types::Vector{DataType}

    function TransportModel(
        ::Type{T};
        use_slacks=false,
        PTDF_matrix=nothing,
        subnetworks=Dict{Int, Set{Int}}(),
        duals=Vector{DataType}(),
    ) where {T <: AbstractTransportModel}
        _check_pm_formulation(T)
        new{T}(
            use_slacks,
            PTDF_matrix,
            subnetworks,
            Dict{PSY.ACBus, Int}(),
            duals,
            nothing,
            Vector{DataType}(),
        )
    end
end

get_use_slacks(m::TransportModel) = m.use_slacks
get_PTDF_matrix(m::TransportModel) = m.PTDF_matrix
get_duals(m::TransportModel) = m.duals
get_network_formulation(::TransportModel{T}) where {T} = T

function instantiate_network_model(
    ::TransportModel{SingleRegionBalanceModel},
    ::PSIP.Portfolio,
)
    #=
    if isempty(model.subnetworks)
        model.subnetworks = PNM.find_subnetworks(sys)
    end

    if length(model.subnetworks) > 1
        @debug "System Contains Multiple Subnetworks. Assigning buses to subnetworks."
        _assign_subnetworks_to_buses(model, sys)
    end
    =#
    return
end
