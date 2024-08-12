abstract type SparseVariableType <: ISOPT.VariableType end

abstract type InvestmentVariableType <: ISOPT.VariableType end
abstract type OperationsVariableType <: ISOPT.VariableType end

"""
Total installed capacity for a technology
"""
struct BuildCapacity <: InvestmentVariableType end
