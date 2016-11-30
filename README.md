# PetriNet - Find All Reachable States

This program is made to run a petri net simulation and will print all reachable states for some petri net
 
    #create(number places, list of transition inputs, list of transition outputs, initial state)
    iex>PetriNet.Net.create(3,2, [[1, 0, 0], [1, 0, 0]], [[0, 1, 0], [0, 0, 1]], [3, 0, 0])
##this will create a petri net with

####3 places
####2 transitions
####a transition that has inputs (1,0,0) and outputs (0,1,0)
####a transition that has inputs (1,0,0) and outputs (0,0,1)
####an initial configuration of (3,0,0)
######we group the inputs of transitions together, for example the transition inputs equal [[1, 0, 0], [1, 0, 0]], the first element in the list is the inputs for transition 1, the second element in the list are the inputs for transition 2

    iex>PetriNet.Net.run      
##this will output all states the above net can have                                                                              
    
    [
    exhausted: [3, 0, 0], 
    exhausted: [2, 1, 0], 
    exhausted: [2, 0, 1],                                                                                     
    exhausted: [1, 2, 0], 
    exhausted: [1, 1, 1], 
    exhausted: [1, 0, 2],                                                                                     
    off: [0, 3, 0], 
    off: [0, 2, 1], 
    off: [0, 1, 2], 
    off: [0, 0, 3]
    ] 

####exhausted means the transition is not a dead end, but all possible transition have been fired for that particular state
####off means a dead end