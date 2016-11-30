# PetriNet

This program is made to run a petri net simulation and will print all
reachable states for some petri net

iex>PetriNet.Net.create(3,2, [[1, 0, 0], [1, 0, 0]], [[0, 1, 0], [0, 0, 1]], [3, 0, 0])
#this will create a petri net with
  #3 places
  #2 transitions
  #t1 has inputs 1,0,0 and outputs 0,1,0
  #t2 has inputs 1,0,0 and outputs 0,0,1
  #the inital configuration is 3,0,0

iex>PetriNet.Net.run
#output                                                                                    
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

  off means a dead end, exhausted means the transition is not a dead end, but
  all possible transition have been fired for that particular state, and that
  those other states exsit in the output 


