defmodule PetriNet.Net do
   use GenServer
   require IEx
   @name {:global, __MODULE__}
   
   def create(places, transitions, inputs, outputs, initial) do
       with {:ok, init, state} <- validate_net(places, transitions, inputs, outputs, initial)
       do 
           GenServer.start_link(__MODULE__, {init, state, []}, name: @name)
       end

       add_node(initial)
   end

#add check for when there is more transions than elements in inputs/outputs list
   def validate_net(places, transitions, inputs, outputs, initial) do
       with false <- Enum.any?(inputs,  fn(t) -> Enum.count(t) != places end), #if the size of the inputs is larger than the amount of places --
            false <- Enum.any?(outputs, fn(t) -> Enum.count(t) != places end),
            true <- Enum.count(initial) == places,
       do: {:ok, initial, Enum.map(1..transitions, fn(num) -> {num, Enum.at(inputs, num - 1), Enum.at(outputs, num - 1)} end)} 
   end

#GenServer client
   def run do
       step
       case check_done do
           false -> run
           true  ->
                    {_inital, _transitions, current_nodes} = net_state
                    IO.inspect current_nodes

       end
   end
   
   def step do
       GenServer.cast(@name, :dead_nodes)
       {_inital, transitions, current_nodes} = net_state
       fire_each(transitions, current_nodes)
   end

   def update_nodes(nodes) do
       GenServer.cast(@name, {:update, nodes})
   end
   
   def add_node(state) do
       GenServer.cast(@name, {:add_node, state})
   end

   def net_state do
       GenServer.call(@name, :get_state)
   end

#mark node done after it fires each
   def fire_each(all_transitions, current_tree) do
        Enum.each(current_tree, 
            fn(node) ->
                    case node do
                        {:on, state}  -> 
                            Enum.each(all_transitions, fn(current_transition) ->
                                case can_fire?(state, current_transition) do
                                    true  -> {:new, fire_transition(state, current_transition)}
                                    false ->  :cannot_fire
                                end
                            end)
                        {:off, _state}       -> {:off, :cannot_fire}
                        {:exhausted, _state} -> {:done, :cannot_fire} 
                    end
                    case node do
                        #mark node as 'exhausted'
                        {:on, _state}    -> mark_node_exhausted(node)
                        {_other, _state} -> {:done, :cannot_fire}
                    end  
                end)
   end

   defp mark_node_exhausted(node) do
        {_intital, _t, all_nodes} = net_state

        Enum.map(all_nodes, fn(test_node) -> 
                                with {state, n} = test_node do
                                    case test_node do
                                        test_node when test_node == node -> {:exhausted, n}
                                        _                                -> {state, n}
                                    end
                                end 
                            end)
        |>update_nodes    
   end

   def mark_nodes_dead(all_transitions, state) do
        Enum.map(state, fn(node) -> 
                case node do
                    {:on, state} ->
                        result = Enum.any?(all_transitions, fn(t) -> can_fire?(state, t) end)
                        
                        if(result) do
                            {:on, state}
                        else 
                            {:off, state}
                        end
                    {:off, state}       -> {:off, state}
                    {:exhausted, state} -> {:exhausted, state}
                    end
        end)
   end

   def can_fire?(state, transtion) do
       with {_t, inputs, _outputs} = transtion do
            Enum.zip(state, inputs)
            |>Enum.map(fn {pi, ti} -> pi - ti end)
            |>Enum.all?(fn result -> result >= 0 end)
       end
   end

   def fire_transition(state, transtion) do
        node = with {_t, inputs, outputs} = transtion do
                List.zip([state, inputs, outputs])
                |>Enum.map(fn {pi, ti, to} -> pi - ti + to end)   
            end
        
        add_node(node)
    end

    def check_done do
        {_intital, _t, all_nodes} = net_state

        Enum.all?(all_nodes,fn(node) -> 
                                case node do
                                    {status, _state} when status == :on -> false
                                    _                                   -> true
                                end
                            end)
    end

    #GenServer calls
    def handle_cast({:add_node, state}, {inital, transitions, current_nodes}) do
        if (Enum.any?(current_nodes, fn({_status, other_state}) -> other_state == state end)) do
            {:noreply, {inital, transitions, current_nodes}}
        else
            {:noreply, {inital, transitions, current_nodes ++ [on: state]}}
        end 
    end

    def handle_cast(:dead_nodes, {initial, transitions, current_nodes}) do
        {:noreply, {initial, transitions, mark_nodes_dead(transitions, current_nodes)}}
    end

    def handle_cast({:update, nodes}, {initial, transitions, _current_nodes}) do
        {:noreply, {initial, transitions, nodes}}
    end

    def handle_call(:get_state, _from, state) do
        {:reply, state, state}
    end
end

#TODO: 
#       1. handle case of unbounded petri nets, fix caulctions that will have a 'w'
#       2. write input gather to get the 'right' input for valid petri nets
#           2a. if the user messes up make sure the state stays the same and re-ask 

#PetriNet.Net.create(2,1, [[1, 0], [0, 1]], [[0, 1]], [1, 0])

#PetriNet.Net.create(3,2, [[1, 0, 0], [0, 1, 0]], [[1, 1, 0], [0,0,1]], [1, 0, 0])

#PetriNet.Net.create(3,2, [[1, 0, 0], [1, 0, 0]], [[0, 1, 0], [0, 0, 1]], [3, 0, 0])
#PetriNet.Net.run