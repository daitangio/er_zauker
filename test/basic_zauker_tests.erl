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
	?debugVal(Pgrampa),
	%% Matching is done via := and not all field are required:
	#{  born:=WhenGrampaIsBorn } =Pgrampa,
	GrampaAge=2014-WhenGrampaIsBorn,
	?debugVal(GrampaAge),
	?assertEqual(96,GrampaAge).


name_in_fun_test() ->
	F = fun  Fact(0) -> 1; 
              Fact(N) -> N * Fact(N - 1) 
        end,	
	?debugVal(F(3)).
	





%%%% checking for  a connection problem is quite hard
connection2redis_will_tear_down_me(Caller)->
	try	   
	   eredis:start_link(),
	   Caller ! {ok}
	catch
	   _:_ ->
	      erlang:display(erlang:get_stacktrace()),
		  Caller ! {error}
	end.



%% Wrong: should report undefined if Pidz is dead but it des not happen
connection2redis_test()->
	Pidz=spawn(basic_zauker_tests,connection2redis_will_tear_down_me,[self()]),
	receive 
		{ok} ->
			?debugMsg("Redis ok");
		{error} ->
			?debugMsg("Redis offline")
		%% As far as we can see, 350 is a good value to test this
		after 350 ->
			?debugMsg("Redis offline or slow"),
			?debugVal(process_info(Pidz)),
			% For extra safety: we expect the test process CRASHED:
			?assertNotEqual(undefined, process_info(Pidz))			
	end.


%% Breaks and we are not able to cope
%% connection2redis_work_test()->
%% 	try eredis:start_link() of 
%% 		{ok, C} -> 
%% 			?debugVal("Redis is ok")
%% 	catch
%% 		throw:_->
%% 			?debugVal("Error");
%% 		exit:_->
%% 			?debugVal("Error Exit");
%% 		_:_->	
%% 			?debugVal("Bad day")
%% 	after 	
%% 		?debugVal("Test ends here")
%% 	end.
	



trigram_split_test()->
    ToSplit="Greather3",
    Trigram=string:substr(ToSplit,1,3),
    io:format("Trigram:~p~n",[Trigram]),
    ?assertEqual("Gre",Trigram).

%% Client split and search test
%% termLowercase=term.downcase()
%% Split in trigram and add prefix:
%% trigramInAnd=split_in_trigrams(termLowercase,"trigram:ci")
%% fileIds=    @redis.sinter(*trigramInAnd)
%% return map_ids_to_files(fileIds) 

makeSearchSet1_test()->
    T = er_zauker_app:makeSearchTrigram("abc"),
    ?assertEqual(["trigram:ci:abc"],T),
    ?debugVal(T).


makeSearchSet2_test()->
    T = er_zauker_app:makeSearchTrigram("abcd"),
    ?assertEqual(["trigram:ci:abc","trigram:ci:bcd"],T),
    ?debugVal(T).


makeSearchSet3_test()->
    T = er_zauker_app:makeSearchTrigram("abcde"),
    ?assertEqual(["trigram:ci:abc","trigram:ci:bcd","trigram:ci:cde"],T),
    ?debugVal(T).

%% sinter "trigram:ci:her" "trigram:ci:hec"
%% Return 2 and 
%% get fscan:id2filename:2
%% returns "src/er_zauker_util.erl"

listIds_test()->
    {ok,R}=eredis:start_link(),
    Ids=er_zauker_app:listFileIds(["trigram:ci:her","trigram:ci:hec"],R),
    ?debugVal(Ids).

map_ids_to_files_test()->
    {ok,R}=eredis:start_link(),
    Files=er_zauker_app:map_ids_to_files(["1","2"],R),
    %% TODO CHECK LEN IS 2
    ?debugVal(Files).

%% makeIntegrationSearch_test()->
%%     R=eredis:start_link(),
%%     T=er_zauker_app:makeSearchTrigram("herhec"),
%%     ?debugVal(T),
%%     Ids=er_zauker_app:listFileIds(T,R),
%%     ?debugVal(Ids).
    
-endif.


