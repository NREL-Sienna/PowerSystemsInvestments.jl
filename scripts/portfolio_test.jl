using Pkg
Pkg.activate("")
Pkg.instantiate()
using Revise
using PowerSystems
import InfrastructureSystems
using PowerSystemsInvestmentsPortfolios
const IS = InfrastructureSystems
const PSY = PowerSystems
const PSIP = PowerSystemsInvestmentsPortfolios

#data = PSY._create_system_data_from_kwargs()

#bus = ACBus(nothing)
#discount_rate = 0.07
#investment_schedule = Dict()
#port_metadata = PSIP.PortfolioMetadata("portfolio_test", nothing, nothing)

p = Portfolio(0.07)

t_th = SupplyTechnology{ThermalStandard}(
    name="thermal_tech",
    available=true,
    fuel=PSY.ThermalFuels.COAL,
    prime_mover=PSY.PrimeMovers.ST,
    capacity_factor=0.98, # cap factor
    capital_cost=nothing,
    operational_cost=nothing,
)

t_th_ext = t_th.ext
t_th_ext["capital_cost"] = [50.0, 125.0]
t_th_ext["operations_cost"] = [5.0, 2.5]
t_th_ext["variable_cost"] = [1.0, 1.0]
t_th_ext["investment_periods"] = [2030, 2040]
# one option is to repeat these for each investment
t_th_ext["operational_periods"] = [1, 2, 3]
t_th_ext["operational_periods_2"] = [
    1,
    2,
    3, # first investment period
    4,
    5,
    6,  # second investment period
]
t_th_ext["investment_operational_periods_map"] =
    Dict(1 => 2030, 2 => 2030, 3 => 2030, 4 => 2040, 5 => 2040, 6 => 2040)
t_th_ext["initial_capacity"] = 200.0 # Data in MW
t_th_ext["maximum_capacity"] = 10000.0
t_th_ext["minimum_required_capacity"] = [0.0, 0.0]

t_th_exp = SupplyTechnology{ThermalStandard}(
    name="thermal_tech_expensive",
    available=true,
    fuel=PSY.ThermalFuels.WASTE_OIL,
    prime_mover=PSY.PrimeMovers.ST,
    capacity_factor=0.92, # cap factor
    capital_cost=nothing,
    operational_cost=nothing,
)

t_th_exp_ext = t_th_exp.ext
t_th_exp_ext["capital_cost"] = [150.0, 100.0]
t_th_exp_ext["operations_cost"] = [15.0, 10.0]
t_th_exp_ext["variable_cost"] = [1.0, 1.0]
t_th_exp_ext["investment_periods"] = [2030, 2040]
# one option is to repeat these for each investment
t_th_exp_ext["operational_periods"] = [1, 2, 3]
t_th_exp_ext["operational_periods_2"] = [
    1,
    2,
    3, # first investment period
    4,
    5,
    6,  # second investment period
]

t_th_exp_ext["investment_operational_periods_map"] =
    Dict(1 => 2030, 2 => 2030, 3 => 2030, 4 => 2040, 5 => 2040, 6 => 2040)
t_th_exp_ext["initial_capacity"] = 200.0 # Data in MW
t_th_exp_ext["maximum_capacity"] = 10000.0
t_th_exp_ext["minimum_required_capacity"] = [0.0, 0.0]

# Renewable Technology

t_re = SupplyTechnology{RenewableDispatch}(
    name="renewable_tech",
    available=true,
    fuel=PSY.ThermalFuels.OTHER,
    prime_mover=PSY.PrimeMovers.WT,
    capacity_factor=0.98, # cap factor
    capital_cost=nothing,
    operational_cost=nothing,
)

t_re_ext = t_re.ext
t_re_ext["capital_cost"] = [100.0, 75.0]
t_re_ext["operations_cost"] = [10.0, 6.5]
t_re_ext["variable_cost"] = [0, 0]
t_re_ext["variable_capacity_factor"] = [0.8, 0.6, 0.3, 0.5, 0.9, 0.4]
t_re_ext["investment_periods"] = [2030, 2040]
# one option is to repeat these for each investment
t_re_ext["operational_periods"] = [1, 2, 3]
t_re_ext["operational_periods_2"] = [
    1,
    2,
    3, # first investment period
    4,
    5,
    6,  # second investment period
]
t_re_ext["investment_operational_periods_map"] =
    Dict(1 => 2030, 2 => 2030, 3 => 2030, 4 => 2040, 5 => 2040, 6 => 2040)
t_re_ext["initial_capacity"] = 200.0 # Data in MW
t_re_ext["maximum_capacity"] = 10000.0
t_re_ext["minimum_required_capacity"] = [0.0, 0.0]

# Demand side technologies
d_1 = DemandSideTechnology{ElectricLoad}(name="demand", available=true, capital_cost)

PSIP.add_technology!(p, t_th)
PSIP.add_technology!(p, t_re)
PSIP.add_technology!(p, t_th_exp)

IS.serialize(t_th)
IS.serialize(t_re)
IS.serialize(t_th_exp)
IS.serialize(p)

#get_technologies(x -> (!get_available(x)), SupplyTechnology{ThermalStandard}, p)

#get_technologies(SupplyTechnology{ThermalStandard}, p)
#PSIP.remove_technology!(SupplyTechnology{ThermalStandard}, p, "thermal_tech")

#get_available(t_th)
#get_available(t_re)
#get_available(t_th_exp)
#IS.deserialize(p)
