struct InvestmentIntervals
    time_stamps::Vector{NTuple{2, Dates.Date}}
    map_to_operational_slices::Dict{Int, Vector{Int}}
    map_to_feasibility_slices::Dict{Int, Vector{Int}}
end

struct OperationalPeriods
    time_stamps::Vector{Dates.DateTime}
    consecutive_slices::Vector{Vector{Int}}
    inverse_invest_mapping::Vector{Int}
    feasibility_indexes::Vector{Int}
    operational_indexes::Vector{Int}
end

struct TimeMapping
    investment::InvestmentIntervals
    operation::OperationalPeriods

    function TimeMapping(
        investment_intervals::Vector{NTuple{2, Dates.Date}},
        operational_periods::Vector{Vector{Dates.DateTime}},
        feasibility_periods::Vector{Vector{Dates.DateTime}},
    )
        # TODO:
        # Validation of the dates to avoid overlaps
        # Validation of the dates to avoid gaps in the operational periods

        op_index_last_slice = length(operational_periods)
        all_operation_slices = union(operational_periods, feasibility_periods)
        total_count = sum(length(x) for x in all_operation_slices)
        total_slice_count = length(operational_periods) + length(feasibility_periods)
        time_stamps = Vector{Dates.DateTime}(undef, total_count)
        consecutive_slices = Vector{Vector{Int}}(undef, total_slice_count)
        inverse_invest_mapping = Vector{Vector{Int}}(undef, total_slice_count)
        map_to_operational_slices = Dict{Int, Vector{Int}}(
            i => Vector{Int}() for i in 1:length(investment_intervals)
        )
        map_to_feasibility_slices = Dict{Int, Vector{Int}}(
            i => Vector{Int}() for i in 1:length(investment_intervals)
        )

        ix = 1
        slice_running_count = 0
        for (sx, slice) in enumerate(all_operation_slices)
            slice_length = length(slice)
            slice_found_in_interval = false
            for (ivx, investment_interval) in enumerate(investment_intervals)
                if first(slice) >= investment_interval[1] &&
                   last(slice) <= investment_interval[2]
                    if sx <= op_index_last_slice
                        push!(map_to_operational_slices[ivx], sx)
                    else
                        push!(map_to_feasibility_slices[ivx], sx)
                    end
                    inverse_invest_mapping[sx] = ivx
                    slice_found_in_interval = true
                    break
                end
            end
            if !slice_found_in_interval
                error()
            end
            slice_length = length(slice)
            slice_indeces = range(slice_running_count + 1, length=slice_length)
            consecutive_slices[sx] = collect(slice_indeces)
            slice_running_count = last(slice_indeces)
            for time_stamp in slice
                time_stamps[ix] = time_stamp
                ix += 1
            end
        end

        op_periods = OperationalPeriods(
            time_stamps,
            consecutive_slices,
            inverse_invest_mapping,
            collect(range(start=op_index_last_slice + 1, stop=total_slice_count)),
            collect(range(1, op_index_last_slice)),
        )

        inv_periods = InvestmentIntervals(
            investment_intervals,
            map_to_operational_slices,
            map_to_feasibility_slices,
        )

        new(inv_periods, op_periods)
    end
end

get_total_operation_period_count(tm::TimeMapping) = length(tm.operation.time_stamps)
# TODO: use more accessors to get the problem times
