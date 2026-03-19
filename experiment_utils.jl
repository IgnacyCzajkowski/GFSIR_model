module ExperimentUtils

include(joinpath(@__DIR__, "simulation_utils.jl"))
using .SimulationUtils
using Statistics

export main_alpha, main_beta

### Performing set of simulations in function of beta with set alpha value and saving results to data_o{num_of_observers}.txt file 
function main_beta(alpha::Float64, network_params, observer_count_list::Vector{Int}, beta_start::Float64, beta_step::Float64, i_max::Int, j_max::Int)
    files_array = Vector{}()
    for o_val in observer_count_list
        file = open("data_o" * string(o_val) * ".txt", "w")
        push!(files_array, file)
    end

    for i in 1:i_max
        rank_avg_conteigner = Vector{}()
        prec_avg_conteigner = Vector{}()
        for o_val in observer_count_list
            rank_avg_vect_kor = Vector{Float64}()
            prec_avg_vect_kor = Vector{Float16}()
            push!(rank_avg_conteigner, rank_avg_vect_kor)
            push!(prec_avg_conteigner, prec_avg_vect_kor)
        end
        beta = beta_start + beta_step * (i - 1)
        for j in 1:j_max
            if length(network_params) == 1
                N::Network = get_network_from_file(network_params[1])
            elseif length(network_params) == 2
                nodes::Int = network_params[1]
                prob::Float16 = network_params[2]
                N = generate_network(nodes, prob)
            elseif length(network_params) == 3
                nodes = network_params[1]
                base_nodes::Int = network_params[2]
                edges::Int = network_params[3]
                N = generate_network(nodes, base_nodes, edges)
            end

            prec_kor_list, rank_kor_list = algorithm(N, beta, alpha, observer_count_list)
            for k in 1:length(observer_count_list)
                push!(prec_avg_conteigner[k], prec_kor_list[k])
                push!(rank_avg_conteigner[k], rank_kor_list[k])
            end
            resetExistingNetwork(N)
            if j % 50 == 0
                println("Progres: ", ((i - 1) * j_max + j - 1) / (j_max * i_max)) #Timestep
            end

        end
        for k in 1:length(observer_count_list)
            prec_avg_kor = sum(prec_avg_conteigner[k]) / length(prec_avg_conteigner[k])
            std_dev_prec_kor = std(prec_avg_conteigner[k]) / length(prec_avg_conteigner[k])
            rank_avg_kor = sum(rank_avg_conteigner[k]) / length(rank_avg_conteigner[k])
            std_dev_rank_kor = std(rank_avg_conteigner[k]) / length(rank_avg_conteigner[k])   
            write(files_array[k], string(beta) * " " * string(prec_avg_kor) * " " * string(rank_avg_kor) * " " * string(std_dev_prec_kor) * " " * string(std_dev_rank_kor) * " \n")
        end
    end
    for file in files_array
        close(file)
    end
end


### Performing set of simulations in function of alpha with set beta value and saving results to data_o{num_of_observers}.txt file
function main_alpha(beta::Float64, network_params, observer_count_list::Vector{Int}, alpha_start::Float64, alpha_step::Float64, i_max::Int, j_max::Int)
    files_array = Vector{}()
    for o_val in observer_count_list
        file = open("data_o" * string(o_val) * ".txt", "w")
        push!(files_array, file)
    end

    for i in 1:i_max
        rank_avg_conteigner = Vector{}()
        prec_avg_conteigner = Vector{}()
        for o_val in observer_count_list
            rank_avg_vect_kor = Vector{Float64}()
            prec_avg_vect_kor = Vector{Float16}()
            push!(rank_avg_conteigner, rank_avg_vect_kor)
            push!(prec_avg_conteigner, prec_avg_vect_kor)
        end
        alpha = alpha_start + alpha_step * (i - 1)
        for j in 1:j_max

            if length(network_params) == 1
                N::Network = get_network_from_file(network_params[1])
            elseif length(network_params) == 2
                nodes::Int = network_params[1]
                prob::Float16 = network_params[2]
                N = generate_network(nodes, prob)
            elseif length(network_params) == 3
                nodes = network_params[1]
                base_nodes::Int = network_params[2]
                edges::Int = network_params[3]
                N = generate_network(nodes, base_nodes, edges)
            end
            prec_kor_list, rank_kor_list = algorithm(N, beta, alpha, observer_count_list)
            for k in 1:length(observer_count_list)
                push!(prec_avg_conteigner[k], prec_kor_list[k])
                push!(rank_avg_conteigner[k], rank_kor_list[k])
            end
            resetExistingNetwork(N)
            if j % 50 == 0
                println("Progres: ", ((i - 1) * j_max + j - 1) / (j_max * i_max)) #Timestep
            end
        end
        for k in 1:length(observer_count_list)
            prec_avg_kor = sum(prec_avg_conteigner[k]) / length(prec_avg_conteigner[k])
            std_dev_prec_kor = std(prec_avg_conteigner[k]) / length(prec_avg_conteigner[k])
            rank_avg_kor = sum(rank_avg_conteigner[k]) / length(rank_avg_conteigner[k])
            std_dev_rank_kor = std(rank_avg_conteigner[k]) / length(rank_avg_conteigner[k])
            write(files_array[k], string(alpha) * " " * string(prec_avg_kor) * " " * string(rank_avg_kor) * " " * string(std_dev_prec_kor) * " " * string(std_dev_rank_kor) * " \n")
        end
    end

    for file in files_array
        close(file)
    end
end
end