abstract type AbstractTechnologyFormulation end

abstract type InvestmentTechnologyFormulation <: AbstractTechnologyFormulation end
abstract type OperationsTechnologyFormulation <: AbstractTechnologyFormulation end



### Investment Formulations ###

struct ContinuousInvestment <: InvestmentTechnologyFormulation end
struct IntegerInvestment <: InvestmentTechnologyFormulation end

### Operations Formulations ###

struct BasicDispatch <: OperationsTechnologyFormulation end
struct ThermalNoDispatch <: OperationsTechnologyFormulation end
struct RenewableNoDispatch <: OperationsTechnologyFormulation end

"""
Infinite capacity approximation of network flow to represent entire system with a single node.
"""
struct CopperPlatePowerModel <: PM.AbstractActivePowerModel end