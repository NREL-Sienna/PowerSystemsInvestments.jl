abstract type AbstractTransportModel end

struct SingleRegionBalanceModel <: AbstractTransportModel end
struct MultiRegionBalanceModel <: AbstractTransportModel end
struct NodalBalanceModel <: AbstractTransportModel end

mutable struct TransportModel{T <: AbstractTransportModel}
    use_slacks::Bool
    function TransportModel(::Type{T}; use_slacks=false) where {T <: AbstractTransportModel}
        _check_pm_formulation(T)
        new{T}(use_slacks)
    end
end

get_use_slacks(m::TransportModel) = m.use_slacks
