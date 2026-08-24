"""
Return the available technologies attached to `requirement` that participate on
the generation side — `PSIP.ResourceTechnology` subtypes (`SupplyTechnology`,
`StorageTechnology`, `ColocatedSupplyStorageTechnology`). Generic over any
`PSIP.Requirement` so it is shared by all requirement models.
"""
function _safe_has_requirement(t, requirement::PSIP.Requirement)
    try
        return PSIP.has_requirement(t, requirement)
    catch e
        if e isa MethodError
            return false
        end
        rethrow(e)
    end
end

function _contributing_resources(p::PSIP.Portfolio, requirement::PSIP.Requirement)
    return [
        t for t in [
            PSIP.get_technologies(PSIP.get_available, PSIP.SupplyTechnology, p)...,
            PSIP.get_technologies(PSIP.get_available, PSIP.StorageTechnology, p)...,
            PSIP.get_technologies(
                PSIP.get_available,
                PSIP.ColocatedSupplyStorageTechnology,
                p,
            )...,
        ] if _safe_has_requirement(t, requirement)
    ]
end

"""
Return the available technologies attached to `requirement` that participate on
the demand side — `PSIP.DemandTechnology` subtypes (`DemandRequirement`,
`DemandSideTechnology`). Generic over any `PSIP.Requirement`.
"""
function _contributing_demands(p::PSIP.Portfolio, requirement::PSIP.Requirement)
    return [
        t for t in [
            PSIP.get_technologies(PSIP.get_available, PSIP.DemandRequirement, p)...,
            PSIP.get_technologies(PSIP.get_available, PSIP.DemandSideTechnology, p)...,
        ] if _safe_has_requirement(t, requirement)
    ]
end
