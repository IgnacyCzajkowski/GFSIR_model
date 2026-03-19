### About
This repository contains the source code for replicating the simulations from the research paper “Nonlinear dynamics of information overload: Impact on source localization in complex networks” by Ignacy Czajkowski and Robert Paluch. In particular, the GFSIR propagation model on networks is implemented here.

### Code structure
The code is organized as follows:
- The **simulation_utils.jl** contains functions and structs implementing simulation of information propagation using GFSIR model from the paper. If one wants to use and integrate the model into existing simulation pipeline, importing this file should be sufficient.
- The **experiment_utils.jl** contains functions to replicate the experiment setup used in the paper. If one wants to replicate the results then he/she should aslo import this file.
- The **experiment_pipeline.jl** implements the whole pipeline used in the experiment. The parameters for a given experiments should be specified in the params.txt file such as described below in the parameters format section and in the **params.txt** file's comments. The output is saved into data_o{NUMBER_OF_OBSERVERS}.txt file/s in the format specified in the Output format section

### Parameters Format
When replicating our experiment, there are two avaiable **modes**. The alpha mode performs a set of propagation simulations with changing **alpha** ($\alpha$) parameter, with set **beta** ($\beta$). In the case of the beta mode the simulations are conducted with a set $\alpha$ value and changing $\beta$. 

In both modes for each pair ($\alpha, \beta$) there are conducted **j_max** simulations and average precision and ranking with their std dev are saved. One should also speciffy the **observer_count** where it can be either a single value or a set of decreasing values. In the second case, there will be as many output files as many observer values have been provided.

There is also a need to include a **network_parameters** that specify in what network the propagation will take place. There are three posible options: E-R network (N, p), B-A network (N, m, k) or reading network from a file (filename) in the format of 

The **params.txt** file should be then arranged as follows:
**network_parameters** (ex. 1000 5 2)#    Network parameters: E-R -> (N:Int, p:Float16), B-A -> (N:Int, m:Int, k:Int), From a file -> (file_name:String)
**observer_count** (ex. 100 or 200 100 50)#         Number of observers. One can add few observer values in decreasing order. In such case there will be a few output files.
**mode** (ex. alpha)#       Experiment mode: (alpha/beta)  
**beta** (ex. 0.7 or 0.0 0.1 5)#         Beta value (In case of alpha mode, add singular Float value, in case of beta mode add start, delta, number of steps)
**alpha** (ex.0.0 0.3 5 or 0.6)#   Alpha value (In case of alpha mode, add start, delta, number of steps, in case of beta mode add singular float value)
**j_max** (ex. 100)#         Number of simulations to average per single data point

Note that each parameter is specified in the new line. The order of the parameters matters. In case of multiple values per parameter the delimeter is \space, do not use \, or \tab. **Do not delete \#** since it is used to divide the parameter value from a comment.

### Output format
During the simulation, the results will be saved to data_o{**observer_count**}.txt file (or multiple files) in the case of multiple **observer_count** parameters provided). In the output files each datapoint is saved in a new line. The format is:
**alpha**/**beta** (depending on the mode) | **avg_precision** | **avg_ranking** | **prec_std_dev** | **rank_std_dev** |

### Requirements
-- Julia (tested version 1.12.5)
-- Graphs (https://github.com/JuliaGraphs/Graphs.jl/)
-- Setfield (https://github.com/jw3126/Setfield.jl)
-- StatsBase (https://github.com/JuliaStats/StatsBase.jl)

### License
The repository has been licensed with MIT Licence for impoving future usage and replicability.
