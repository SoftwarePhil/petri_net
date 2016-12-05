defmodule PetriNet.Net do
   use GenServer
   require IEx
   @name {:global, __MODULE__}
   
   def create(places, transitions, inputs, outputs, initial) do
       with {:ok, state} <- validate_net(places, transitions, inputs, outputs, initial)
       do 
           GenServer.start_link(__MODULE__, {[], state, []}, name: @name)
           add_node(initial)
       end
   end

#add check when the amount of inputs does not equal the amount of outputs
   def validate_net(places, transitions, inputs, outputs, initial) do
       with false <- Enum.any?(inputs,  fn(t) -> Enum.count(t) != places end), #if the size of the inputs is larger than the amount of places --
            false <- Enum.any?(outputs, fn(t) -> Enum.count(t) != places end),
            true  <- Enum.count(inputs)  == transitions,
            true  <- Enum.count(outputs) == transitions,
            true  <- Enum.count(initial) == places,
       do: {:ok, Enum.map(1..transitions, fn(num) -> {num, Enum.at(inputs, num - 1), Enum.at(outputs, num - 1)} end)} 
   end

#GenServer client
   def run do
       step
       case check_done do
           false -> run
           true  ->
                    {fire_history, _transitions, current_nodes} = net_state
                    [fire_history: fire_history, all_nodes: current_nodes]

       end
   end
   
   #TODO: make this after, fire_transition is called return a new updated net
   #that net should be passed into the genserver to be stored
   #the way it is done now is confusing because some of the functions
   #that make up fire_transition add/modify nodes stored on the GenServer
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

   def add_history(node) do
       GenServer.cast(@name, {:fire_history, node})
   end

   def net_state do
       GenServer.call(@name, :get_state)
   end

   def clear(places, transitions, inputs, outputs, initial) do
        with {:ok, state} <- validate_net(places, transitions, inputs, outputs, initial) do
            GenServer.call(@name, {:clear, {[], state, [on: initial]}})
        end
   end

#mark node done after it fires each
   def fire_each(all_transitions, current_tree) do
        Enum.each(current_tree, 
            fn(node) ->
                    case node do
                        {:on, state}  -> 
                            Enum.each(all_transitions, fn(current_transition) ->
                                case can_fire?(state, current_transition) do
                                    true  -> 
                                        {t, _inputs, _outputs} = current_transition
                                        new_state = fire_transition(state, current_transition)
                                        add_history({t, state, new_state})
                                        {:new, new_state}
                                    false ->  :cannot_fire
                                end
                            end)
                        {:off, _state}       -> {:off, :cannot_fire}
                        {:exhausted, _state} -> {:done, :cannot_fire} 
                        {:recursive, _state} -> {:done, :recursive}
                    end
                    case node do
                        #mark node as 'exhausted'
                        {:on, _state}    -> mark_node(node, :exhausted)
                        {_other, _state} -> {:done, :cannot_fire}
                    end  
                end)
   end

   def mark_node(node, new_status) do
        {_intital, _t, all_nodes} = net_state
        Enum.map(all_nodes, fn(test_node) -> 
                                with {state, n} = test_node do
                                    case test_node do
                                        test_node when test_node == node -> {new_status, n}
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
                    {:recursive, state} -> {:recursive, state}
                    end
        end)
   end

   def can_fire?(state, transtion) do
       with {_t, inputs, _outputs} = transtion do
            Enum.zip(state, inputs)
            |>Enum.map(fn {pi, ti} -> w?(pi, -ti) end)
            |>Enum.all?(fn result -> result >= 0 end)
       end
   end

   def fire_transition(state, transtion) do
        node = with {_t, inputs, outputs} = transtion do
                List.zip([state, inputs, outputs])
                |>Enum.map(fn {pi, ti, to} -> w(pi, -ti + to) end)   #pi - ti + to  
            end
        node = check_w(state, node)
        add_node(node)
        node
    end

    def w(num1, num2) do
        case {num1, num2} do
            {"w", _num} -> "w"
            {a  ,   b} -> a + b 
        end
    end

     def w?(num1, num2) do
        case {num1, num2} do
            {"w", _num} -> 1
            {a  ,   b} -> a + b 
        end
    end

    def sub_w(num1, num2) do
        case {num1, num2} do
            {"w", _num}  -> "w"
            {a  ,   "w"} -> a 
            {a  ,     b} -> a - b
        end
    end

    #a check for recursive w transitions
    def check_w(before_state, after_state) when before_state == after_state do
        mark_node({:on, after_state}, :recursive)
        after_state 
    end
    
    #checks if a transition will cause net to be unbounded 
    def check_w(before_state, after_state) do    
        with list  = List.zip([before_state, after_state]),
                done? = Enum.map(list, fn({current, next}) -> sub_w(current, next) end),
                test  = Enum.all?(done?, fn(x) -> x <= 0 end)
            do    
                if(test) do
                    Enum.map(list, fn({current, next}) -> 
                        case current - next do
                            num when num < 0 -> "w"
                            _num             -> next
                        end    
                    end)
                else
                    after_state
                end
            end
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

    def handle_cast({:fire_history, node}, {initial, transitions, current_nodes}) do
        {:noreply, {initial ++ [node], transitions, current_nodes}}
    end

    def handle_call(:get_state, _from, state) do
        {:reply, state, state}
    end

    def handle_call({:clear, new_state}, _from, _state) do
        {:reply, :ok, new_state}
    end
end

#TODO: 
#       1. write input gather to get the 'right' input for valid petri nets
#           1a. if the user messes up make sure the state stays the same and re-ask 

#PetriNet.Net.create(2,1, [[1, 0]], [[0, 1]], [1, 0])

#PetriNet.Net.create(3,2, [[1, 0, 0], [0, 1, 0]], [[1, 1, 0], [0,0,1]], [1, 0, 0])

#PetriNet.Net.create(3,2, [[1, 0, 0], [1, 0, 0]], [[0, 1, 0], [0, 0, 1]], [3, 0, 0])
#PetriNet.Net.run

#recurisve
#PetriNet.Net.create(2,1, [[1,0]], [[1,1]], [1,0])

#PetriNet.Net.create(5, 5, [[1,0,0,0,0],[0,1,0,0,0],[0,0,0,0,1],[0,0,0,1,0],[0,0,1,0,1]], [[0,1,0,1,0],[0,0,1,0,0],[0,0,0,1,0],[0,0,0,0,1],[1,0,0,0,0]], [1,0,0,0,0])

#PetriNet.Net.create(3,3, [[1,0,0], [1,0,0], [0,1,1]], [[1,1,0], [0,0,1], [0,0,1]], [1,0,0])