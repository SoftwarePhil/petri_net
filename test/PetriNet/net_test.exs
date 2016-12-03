defmodule PetriNet.NetTest do
    use ExUnit.Case

    test "bounded petri net test" do
        PetriNet.Net.create(3,2, [[1, 0, 0], [1, 0, 0]], [[0, 1, 0], [0, 0, 1]], [3, 0, 0]) 
        
        [_fire_history, all_nodes: result] = assert PetriNet.Net.run
        assert result == [exhausted: [3, 0, 0], exhausted: [2, 1, 0], exhausted: [2, 0, 1],                                                                                     
                                exhausted: [1, 2, 0], exhausted: [1, 1, 1], exhausted: [1, 0, 2],                                                                                     
                                off: [0, 3, 0], off: [0, 2, 1], off: [0, 1, 2], off: [0, 0, 3]]
    end

    test "unbounded petri net test" do
        PetriNet.Net.create(2,1, [[1,0]], [[1,1]], [1,0])

        
        [_fire_history, all_nodes: result] = assert PetriNet.Net.run 
        assert result == [exhausted: [1, 0], recursive: [1, "w"]]   
    end

    test "unbounded petri net test, with w transitions being fired" do
        PetriNet.Net.create(3,3, [[1,0,0], [1,0,0], [0,1,1]], [[1,1,0], [0,0,1], [0,0,1]], [1,0,0]) 
        
        [_fire_history, all_nodes: result] = assert PetriNet.Net.run 
        assert result == [exhausted: [1, 0, 0], recursive: [1, "w", 0], off: [0, 0, 1],                                                                             
                          recursive: [0, "w", 1]] 
    end
end