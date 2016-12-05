defmodule PetriNet.Input do
    alias PetriNet.Net, as: Net
    def gather do
            [places, transitions] = places_and_transitions
            {empty_input, empty_output, empty_initial} = make_net_structure [places, transitions]
            inputs  = fill_transition(empty_input, "input")
            outputs = fill_transition(empty_output, "output")
            initial = fill_initial(empty_initial)

            case Net.check_status do
                :nil ->
                    Net.create places, transitions, inputs, outputs, initial
                    Net.run
                _pid -> 
                    Net.clear places, transitions, inputs, outputs, initial
                    Net.run 
            end
    end
    
    def places_and_transitions do
        str = IO.gets "input the number of transitions and places for the net\n(example \'3 2\' is for a net with 3 places and 2 transitions) "
        
        result = parse_p_t(str)
        result_count = Enum.count(result)
        check = Enum.any?(result, fn check -> check == :ok end)
        
        case check do
            true  -> places_and_transitions
            false when result_count == 2 -> result
            _     ->
                    IO.puts "An improper amount of inputs was entered" 
                    places_and_transitions
        end
    end

    defp parse_p_t(string) do
        String.replace(string, "\n", "")
        |>String.split(" ")
        |>Enum.map(fn x ->
            case Integer.parse x  do
                 {num, ""} when num > 0  -> num
                 {_num, ""}              -> IO.puts "enter only postive integers"
                 :error                  -> IO.puts "non integer or bad format try again"
                                
            end 
        end)
    end

    def make_net_structure([places, transitions]) do
        t = Enum.map(1..transitions, fn(t) -> Enum.reduce(1..places, [], fn(p, acc) -> acc ++ [empty: {t,p}] end) end)
        p = Enum.reduce(1..places, [], fn(p, acc) -> acc ++ [empty: p] end)
        {t, t, p}
    end

    def fill_transition(transitions, type) do
        t = Enum.map(transitions, fn(t) -> fill_places(t, type) end)
        
        check = List.flatten(t)
                |>Enum.any?(fn(some_t) -> 
                                case some_t do
                                    {:empty,  _n} -> true
                                    _num          -> false
                                end        
                            end)

        case check do
            true   -> 
                IO.puts "try again"
                fill_transition(t, type)
            false  -> t
        end
    end

    def fill_places(transition, type) do
        Enum.map(transition,
        fn(spot) ->
            case spot do
                {:empty, {t,p}} -> 
                        input = IO.gets "enter the #{type} data for transition #{t}, place index #{p} "
                        case Integer.parse input do
                            {num, _str} when num >= 0  -> num
                            {_num, _str}              -> 
                                                       IO.puts "enter only postive integers"
                                                       {:empty, {t,p}}
                            :error                  -> 
                                                       IO.puts "non integer or bad format"
                                                       {:empty, {t,p}}
                        end
                num -> num
            end
        end)
    end

    def fill_initial(initial) do
        place = Enum.map(initial,
                fn(spot) ->
                    case spot do
                        {:empty, i} -> 
                                input = IO.gets "enter the value of index #{i} for the initial state of the net "
                                case Integer.parse input do
                                    {num, _str} when num >= 0  -> num
                                    {_num, _str}              -> 
                                                            IO.puts "enter only postive integers"
                                                            {:empty,i}
                                    :error                  -> 
                                                            IO.puts "non integer or bad format"
                                                            {:empty, i}
                                end
                        num -> num
                    end
                end)


        check = Enum.any?(place, fn(p) -> 
                                case p do
                                    {:empty,  _n} -> true
                                    _num          -> false
                                end        
                            end)
        case check do
                true   -> 
                    IO.puts "try again"
                    fill_initial(place)
                false  -> place
        end 
    end
end