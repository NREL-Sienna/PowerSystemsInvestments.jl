abstract type SparseVariableType <: ISOPT.VariableType end

abstract type InvestmentVariableType <: ISOPT.VariableType end
abstract type OperationsVariableType <: ISOPT.VariableType end

### Investment Variables ###

"""
Total installed capacity for a technology
"""
struct BuildCapacity <: InvestmentVariableType end

### Operations Variables ###

"""
Dispatch of a technology at a timepoint
"""
struct ActivePowerVariable <: OperationsVariableType end
