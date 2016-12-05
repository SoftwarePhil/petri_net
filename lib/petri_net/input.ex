defmodule PetriNet.Input do
    def places_and_transitions do
        str = IO.gets "input the number of transitions and places for the net\n(example \'3 2\' is for a net with 3 places and 2 transitions)"
        
        result = parse_p_t(str)
        check = Enum.any?(result, fn check -> check == :ok end)
        
        case check do
            true  -> places_and_transitions
            false -> 
                    IO.inspect result

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
        {t, t}
    end

    def fill_transition(transitions, type) do
        t = Enum.map(transitions, fn(t) -> fill_places(t, type) end)
        
        #check = List.flatten(t)
         #       |>Enum.any?(fn )
    end

    def fill_places(transition, type) do
        Enum.map(transition,
        fn(spot) ->
            case spot do
                {:empty, {t,p}} -> 
                        input = IO.gets "enter data for transition #{type} transition #{t}, place index #{p}"
                        case Integer.parse input do
                            {num, _str} when num >= 0  -> num
                            {_num, _str}              -> 
                                                       IO.puts "enter only postive integers"
                                                       {:empty, {t,p}}
                            :error                  -> 
                                                       IO.puts "non integer or bad format try again"
                                                       {:empty, {t,p}}
                        end
                num -> num
            end
        end)
    end
end