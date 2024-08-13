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
Total installed capacity for a technology
"""
struct ActivePowerVariable <: OperationsVariableType end
