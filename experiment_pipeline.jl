include(joinpath(@__DIR__, "experiment_utils.jl"))
#using .ExperimentUtils
import .ExperimentUtils: main_alpha, main_beta

### Reading simulation's params from params.txt file
params_array = Vector{}()
file = open("params.txt", "r")
for line in readlines(file)
    data = split(split(line, "#")[1], " ")
    push!(params_array, data)
end
close(file)

if length(params_array[1]) == 1
    network_params = [String(params_array[1][1])]
elseif length(params_array[1]) == 2
    n = parse(Int, params_array[1][1])
    p = parse(Float64, params_array[1][2])
    network_params = [n, p]
elseif length(params_array[1]) == 3
    n = parse(Int, params_array[1][1])
    n0 = parse(Int, params_array[1][2])
    k = parse(Int, params_array[1][3])
    network_params = [n, n0, k]
end

observer_count_list = Vector{Int}()
for obs_num_val in params_array[2]
    push!(observer_count_list, parse(Int, obs_num_val))
end

if params_array[3][1] == "alpha"
    use_alpha::Bool = true
    beta = parse(Float64, params_array[4][1])
    alpha_start = parse(Float64, params_array[5][1])
    alpha_step = parse(Float64, params_array[5][2])
    i_max = parse(Int, params_array[5][3])
elseif params_array[3][1] == "beta"
    use_alpha = false
    beta_start = parse(Float64, params_array[4][1])
    beta_step = parse(Float64, params_array[4][2])
    i_max = parse(Int, params_array[4][3])
    alpha = parse(Float64, params_array[5][1])
end

j_max::Int = parse(Int, params_array[6][1])

### Performing simulations in the given mode
if use_alpha == true
    main_alpha(beta, network_params, observer_count_list, alpha_start, alpha_step, i_max, j_max)
elseif use_alpha == false
    main_beta(alpha, network_params, observer_count_list, beta_start, beta_step, i_max, j_max)
end