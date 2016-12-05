# PetriNet - Find All Reachable States and Transition Fire History

This program is made to run a **petri net** simulation and will print all reachable states for some **petri net**
 
    #create(number places, list of transition inputs, list of transition outputs, initial state)
    iex>PetriNet.Net.create(3, 2, [[1, 0, 0], [1, 0, 0]], [[0, 1, 0], [0, 0, 1]], [3, 0, 0])
###the above will create a petri net with

####3 places, 2 transitions, a transition that has inputs (1,0,0) and outputs (0,1,0), a transition that has inputs (1,0,0) and outputs (0,0,1), an initial configuration of (3,0,0)
#####we group the inputs of transitions together, for example the transition inputs equal [[1, 0, 0], [1, 0, 0]], the first element in the list is the inputs for transition 1, the second element in the list is the inputs for transition 2

    iex>PetriNet.Net.run      
###this will output each transition that was fired and the current state of the net at the time of firing, state after firing, as well every reachable state                                                                              
    [fire_history: [
        {1, [3, 0, 0], [2, 1, 0]}, 
        {2, [3, 0, 0], [2, 0, 1]},                                                                                  
        {1, [2, 1, 0], [1, 2, 0]}, 
        {2, [2, 1, 0], [1, 1, 1]},                                                                                                
        {1, [2, 0, 1], [1, 1, 1]}, 
        {2, [2, 0, 1], [1, 0, 2]},                                                                                                
        {1, [1, 2, 0], [0, 3, 0]}, 
        {2, [1, 2, 0], [0, 2, 1]},                                                                                                
        {1, [1, 1, 1], [0, 2, 1]}, 
        {2, [1, 1, 1], [0, 1, 2]},                                                                                                
        {1, [1, 0, 2], [0, 1, 2]}, 
        {2, [1, 0, 2], [0, 0, 3]}
        ],                                                                                               
     all_nodes: [
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
    ]  
**fire history** has the list of {transition number that was fired, current state}

#####so {1, [3, 0, 0]} means that transition 1 was fired and that the state before fireing was [3,0,0]
**exhausted** means the transition is not a dead end, but all possible transition have been fired for that particular state

**off** means a dead end

**recursive** means by firing some transition,the current state can be reached again

##This can also work with unbounded petri nets
        iex>PetriNet.Net.create(2,1, [[1,0]], [[1,1]], [1,0])
        iex>PetriNet.Net.run 

       [
           fire_history: [
               {1, [1, 0], [1, "w"]}, 
               {1, [1, "w"], [1, "w"]}
            ],                                                                                       
        all_nodes: [
            exhausted: [1, 0], 
            recursive: [1, "w"]
            ]
        ]