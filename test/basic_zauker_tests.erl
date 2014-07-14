-module(basic_zauker_tests).
-compile(export_all).

-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").

%% This module show how to use new ERlang17 Maps
%% It is also a learning center for Erlang newbies
%% TEST CODE FOLLOWS


-import(eredis, [create_multibulk/1]).


stupid_test()->
    ?assertEqual(1,1).   

map_assign_test()->
	%% Remember => introduce new value (wierd) where := only REPLACE
	P = #{ name=> "Giovanni", surname=>"Giorgi" },
	Page = P#{ born => 1974 },
	Pgrampa = Page#{ name := "Giorgio", born := 1918},
	?assertEqual(1,1).


trigram_split_test()->
    ToSplit="Greather3",
    Trigram=string:substr(ToSplit,1,3),
    io:format("Trigram:~p~n",[Trigram]),
    ?assertEqual("Gre",Trigram).

    
-endif.


