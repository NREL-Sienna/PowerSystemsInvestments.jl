using Pkg
Pkg.activate("")
Pkg.instantiate()
using Revise
import InfrastructureSystems
using PowerSystemsInvestmentsPortfolios
using PowerSystemsInvestments
using PowerSystems
using JuMP
const IS = InfrastructureSystems
const PSIP = PowerSystemsInvestmentsPortfolios
const PSY = PowerSystems
const PSIN = PowerSystemsInvestments
