module SimulationUtils

using Graphs
#using GraphPlot
using Setfield
#using Plots
using Statistics
using StatsBase
using LinearAlgebra


export Network,
       Observer,
       generate_network,
       get_network_from_file,
       algorithm,
       resetExistingNetwork


### Network representation: (Graph, Vector{Int}, Int)
struct Network
    graph::Graph
    network_state::Vector{Int}
    source_idx::Int
end


### Observer representation: (Int, Int)
mutable struct Observer
    idx::Int
    t::Int
end


### Initializing source: Vector{Int} -> Int
function initialize_info_source(v::Vector)
    n = length(v)
    idx = rand(1:n)
    v[idx] = 1
    return idx
end


### Generating E-R(N, p) network: (Int, Float16) -> Network
function generate_network(nodes::Int, prob::Float16)
    G::Graph = erdos_renyi(nodes, prob)
    network_state = zeros(nv(G))
    clusters = connected_components(G)
    if length(clusters) > 1
        for i in 1:(length(clusters)-1)
            add_edge!(G, clusters[i][1], clusters[i+1][1])
        end
    end
    source_idx::Int = initialize_info_source(network_state)
    N = Network(G, network_state, source_idx)
    return N
end


### Generating B-A(N, m, k) network: (Int, Int, Int) -> Network
function generate_network(nodes::Int, base_nodes::Int, edges::Int)
    G = barabasi_albert(nodes, base_nodes, edges, complete=true)
    network_state = zeros(nv(G))
    source_idx = initialize_info_source(network_state)
    N = Network(G, network_state, source_idx)
    return N
end

### Loading network from file name: (String) -> Network
function get_network_from_file(file_name::String)
    file = open(file_name, "r")
    longer_format::Bool = length(split(readline(file), " ")) == 2 ? false : true
    close(file)
    G::Graph = SimpleGraph()
    if !longer_format
        file = open(file_name, "r")
        max_vert::Int = 0
        for line in readlines(file)
            node1::Int = parse(Int, split(line, " ")[1])
            node2::Int = parse(Int, split(line, " ")[2])
            if node1 > max_vert
                max_vert = node1
            end
            if node2 > max_vert
                max_vert = node2
            end
        end
        add_vertices!(G, max_vert)
        close(file)
    end

    file = open(file_name, "r")
    for (i, line) in enumerate(readlines(file))
        if i == 1 && longer_format
            continue
        elseif i == 2 && longer_format
            n::Int = parse(Int, split(line, " ")[1])
            add_vertices!(G, n)
        else
            node1::Int = parse(Int, split(line, " ")[1])
            node2::Int = parse(Int, split(line, " ")[2])
            add_edge!(G, node1, node2)
        end
    end
    network_state = zeros(nv(G))
    source_idx = initialize_info_source(network_state)
    N = Network(G, network_state, source_idx)
    close(file)

    return N
end


### Get node's state in next time-step using FSIR model: (Network, Int, Float64, Float64) -> Int
function interact_witch_closest_fsir(N::Network, indx::Int, inf_prob_loc::Float64, alpha::Float64)
    neighbors = all_neighbors(N.graph, indx)
    k_interact = 0
    if N.network_state[indx] == 0
        for i in neighbors
            if N.network_state[i] == 1
                k_interact = k_interact + 1
            end
        end
        if rand() < 1 - (1 - inf_prob_loc / k_interact^alpha)^k_interact
            return 1
        end
    end
    return N.network_state[indx]
end


### Update states for all nodes in the network: (Network, Float64, Float64) -> Vector{Int}
function get_next_step(N::Network, inf_prob_loc::Float64, alpha::Float64)
    v_next::Vector = zeros(nv(N.graph))
    for indx in 1:length(N.network_state)
        v_next[indx] = N.network_state[indx]
    end
    for indx in 1:length(N.network_state)
        v_next[indx] = interact_witch_closest_fsir(N, indx, inf_prob_loc, alpha)
    end
    return v_next
end


### Choose and initialize observers: (Network, Int) -> Vector{Observer} 
function getObservers(N::Network, l::Int)
    obs = Vector{Observer}()
    a = sample(1:length(N.network_state), l, replace=false)
    for idx in a
        if idx == N.source_idx
            o = Observer(idx, 0)
        else
            o = Observer(idx, Int(floatmax(Float16)))
        end
        push!(obs, o)
    end
    return obs
end


### Updating observers: (Network, Vector{Int}, Vector{Observer}, Int) -> None
function actuateObservers(N_new::Network, N_old_state::Vector{Int}, obs::Vector{Observer}, time::Int)
    for point in obs
        if point.t == Int(floatmax(Float16))
            if N_new.network_state[point.idx] == 1 && N_old_state[point.idx] == 0
                point.t = time
            end
        end
    end
end


### Geting distances between node and each observer: (Network, Vector{Observer}, Int) -> Vector{Float64}
function getDistanceFromObservers(N::Network, obs::Vector{Observer}, idx::Int)
    d = Vector{Float64}()
    ds = desopo_pape_shortest_paths(N.graph, idx)
    for point in obs
        if ds.dists[point.idx] > floatmax(Float16)
            push!(d, floatmax(Float16))
        else
            push!(d, float(ds.dists[point.idx]))
        end
    end
    return d
end


### Calculating localization algorithm scores for each node in the network: (Network, Vector{Observer}) -> Vector{Float64}
function getScore(N::Network, obs::Vector{Observer})
    score = Vector{Float64}()
    t = Vector{Float64}()
    for point in obs
        push!(t, float(point.t))
    end
    for i in 1:length(N.network_state)
        d = getDistanceFromObservers(N, obs, i)
        sc::Float64 = cor(t, d)
        if isnan(sc)
            sc = -1.0
        end
        push!(score, sc)
    end
    return score
end


### Calculating precision and ranking: (Network, Vector{Float64}) ->  Float16, Int
function analizeScore(N::Network, score::Vector{Float64})
    solutions = Vector{Int}()

    for i in 1:length(score)
        if abs(score[i] - maximum(score)) < 0.001
            push!(solutions, i)
        end
    end

    src_score = score[N.source_idx]
    if N.source_idx in solutions
        prec = 1.0 / length(solutions)
    else
        prec = 0.0
    end

    rank = maximum(findall(x -> x == src_score, sort(score, rev=true)))
    return prec, rank

end


### Reseting network to new starting condition: (Network) -> None
function resetExistingNetwork(N::Network)
    new_network_state = Vector{Int}()
    for i in 1:length(N.network_state)
        if i == N.source_idx
            push!(new_network_state, 1)
        else
            push!(new_network_state, 0)
        end
    end
    N = @set N.network_state = new_network_state
end


### Performing single simulation: (Network, Float64, Float64, Vector{Int}) -> Vector{Float16}, Vector{Float64}, Vector{Observer}, Network
function algorithm(N::Network, inf_prob_loc::Float64, alpha::Float64, observer_count_list::Vector{Int})
    obs = getObservers(N, observer_count_list[1])
    all_obs_infected::Bool = false
    time_step::Int = 1

    while all_obs_infected == false
        N_temp_vect = copy(N.network_state)
        N = @set N.network_state = get_next_step(N, inf_prob_loc, alpha)
        actuateObservers(N::Network, N_temp_vect, obs, time_step)
        all_obs_infected = true

        for observer in obs
            if observer.t == Int(floatmax(Float16))
                all_obs_infected = false
            end
        end
        time_step += 1
        if time_step > 100000   # Escaping point in case of plateau (Exmpl: Observer not connected with the network)
            break
        end
    end
    prec_list = Vector{Float16}()
    rank_list = Vector{Float64}()
    for o_num_val in observer_count_list
        prec, rank = analizeScore(N, getScore(N, sample(obs, o_num_val, replace=false)))
        push!(prec_list, prec)
        push!(rank_list, rank)
    end
    return prec_list, rank_list, obs, N

end
end