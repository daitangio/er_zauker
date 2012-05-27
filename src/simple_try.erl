-module(simple_try).
-compile(export_all).

-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").
 
%% TEST CODE HERE

-import(eredis, [create_multibulk/1]).


stupid_test()->
    ?assertEqual(1,1).   

trigram_split_test()->
    ToSplit="Greather3",
    Trigram=string:substr(ToSplit,1,3),
    io:format("Trigram:~p~n",[Trigram]),
    ?assertEqual("Gre",Trigram).
	
trigram_split2_test()->
    Trigrams=er_zauker_util:trigram("Greather3"),
    io:format("Trigram:~p~n",[Trigrams]),
    ?assertEqual(Trigrams,["Gre","ath","er3"]).

trigram_split3__case_insensitive_test()->
    Trigrams=er_zauker_util:itrigram("GreaTHer3"),
    io:format("Trigram:~p~n",[Trigrams]),
    ?assertEqual(Trigrams,["gre","ath","er3"]).

-endif.


