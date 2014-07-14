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
    ?assertEqual(["Gre","rea","eat","ath","the","her","er3"],Trigrams).

trigram_split3__case_insensitive_test()->
    Trigrams=er_zauker_util:itrigram("GreaTHer3"),
    io:format("Trigram:~p~n",[Trigrams]),
    ?assertEqual(["gre","rea","eat","ath","the","her","er3"],Trigrams).

trigram_2_set_test()->
    S=er_zauker_util:split_on_set("Pizza"),
    io:format("Set:~p~n",[S]),
    % piz, izz,zza
    ?assertEqual(3,sets:size(S)).

trigram_2_set2_test()->
    S1=er_zauker_util:split_on_set("Pizza", sets:new()),
    % Try again...
    S2=er_zauker_util:split_on_set("Pizza", S1),
    io:format("Set:~p~n",[S2]),
    % Must be still the same...
    ?assertEqual(3,sets:size(S2)).

incr_id_test_disabled()->
    {ok, C} = eredis:start_link(),
    MyTestId=er_zauker_util:get_unique_id(C),
    ?debugVal(MyTestId),
    ?assert(    list_to_integer(MyTestId) >= 0).

split_trigram_1_test()->
    {ok,TrigramSet}=er_zauker_util:split_file_in_trigrams("../readme.org"),
    ?debugVal(sets:to_list(TrigramSet)).


%% -export([print_file_name/2]).

print_file_name(F,_A)->
    ?debugVal(F).

file_scan_test_disab()->
    filelib:fold_files("/tmp",".*",true, fun print_file_name/2,{nothing}).
    
-endif.


