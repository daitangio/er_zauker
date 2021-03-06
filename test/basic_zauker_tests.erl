-module(basic_zauker_tests).

%%-compile([export_all,{parse_transform, lager_transform}]).
-compile([export_all]).

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
%%%% @doc This function must try to connect to non-existent REDIS 
connection2redis_will_tear_down_me(Caller)->
	try	   
	    %% The port 6999 is the wrong one: 
	    ERedisResponse=eredis:start_link("127.0.0.1", 6999, 0, "",no_reconnect),	   
	    Caller ! ERedisResponse
	catch
	   _ ->
	      erlang:display(erlang:get_stacktrace()),
		Caller ! {error,unexpected}
	end.


safe_redis_connect()->
    Pidz=spawn(basic_zauker_tests,connection2redis_will_tear_down_me,[self()]),
    receive 
	{ok,C} ->
	    C;
	_ -> {error,no_redis}
    after 500 ->
	    case process_info(Pidz) of
		undefined ->
		    {error,no_redis};
		_ -> {error,redis_timeout}
	    end
    end.
    
			 


%% Still unsolved problem
%% connectionIsDown_test()->
%%     connection2redis_will_tear_down_me(self()),
%%     receive
%% 	{error}->
%% 	    ?assertEqual(true,true);	 
%% 	_ ->
%% 	    ?debugMsg("Connecting to non-existent redis give not error back"),
%% 	    ?assertEqual(true,false)
%%     end.


%% Wrong: should report undefined if Pidz is dead but it des not happen
connection2redis_test()->
    {error,R}=safe_redis_connect(),
    ?assertEqual(no_redis,R).


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

trigram_split_case_single3_test()->
    T1=er_zauker_util:trigram("Pip"),
    ?assertEqual(["pip"],T1).


trigram_split_rotation_test()->
    T1=er_zauker_util:trigram("Pip12"),
    ?assertEqual(["pip","ip1","p12"],T1).


trigram_split_no_size_3_test()->
    Trigram=er_zauker_util:trigram("Pi"),
    ?assertEqual([],Trigram).

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


%% Indexing Integration tests for checking:
%% Is indexer working properly?
%% To do it well, we have a setup and cleaup function:
%% see http://stackoverflow.com/questions/16223210/erlang-eunit-setup-function-doesnt-run


setup()->
    er_zauker_rpool:startRedisPool(),
    %%er_zauker_app:startIndexer(),
    %% Run Lager logger
    %%lager:start(),
    %%lager:info("Nice to meet you"),
    done.

cleanup(_Bho)->
    ?debugMsg("Cleanup of redis pool still unsupported"),
    nothing2do.


seach_test_() ->
    {setup, fun setup/0, fun cleanup/1,
     {inorder,
      [
       fun md5_search_works/0,
       fun search_works1/0,
       fun search_works2/0,
       fun subgram_does_not_work/0,
       fun search_works_no_matchtest/0,
       fun iso_8859_breaks/0,
       fun space_guy_never_recoded/0,
       fun zauker_skip_aready_indexed_test/0,
       fun ensure_good_trigrams/0
      ]
     }
    }.



md5_search_works()->
    er_zauker_util:load_file_if_needed("./test_files/test_text1.txt"),
    er_zauker_util:load_file_if_needed("./test_files/test_text1.txt"),
    SearchFilesResult=er_zauker_app:erlist("califragilisti"),
    ?assertEqual([<<"./test_files/test_text1.txt">>],SearchFilesResult).
    

search_works1()->    
    er_zauker_util:load_file("./test_files/test_text1.txt"),
    SearchFilesResult=er_zauker_app:erlist("califragilisti"),
    ?assertEqual([<<"./test_files/test_text1.txt">>],SearchFilesResult).

search_works2()->    
    er_zauker_util:load_file("./test_files/test_text1.txt"),
    SearchFilesResult=er_zauker_app:erlist("spiralidoso_se_lo_dici"),
    ?assertEqual([<<"./test_files/test_text1.txt">>],SearchFilesResult).

subgram_does_not_work()->
    er_zauker_util:load_file("./test_files/test_text1.txt"),
    SearchFilesResult=er_zauker_app:erlist("su"),
    ?assertEqual([],SearchFilesResult).

%% @doc this test is a negative one: a little useful
%% we use it only to avoid some bad cases in which we return wrong results!
search_works_no_matchtest()->
    er_zauker_util:load_file("./test_files/test_text1.txt"),
    SearchFilesResult=er_zauker_app:erlist("yeppa,we hope this set of trigrams will not be on any file set used for test."),
    ?assertEqual([],SearchFilesResult).



iso_8859_breaks()->
    %% ?assertMatch( {error,_},er_zauker_util:load_file("./test_files/iso-8859-file.txt")).
    ?assertMatch( {ok},er_zauker_util:load_file("./test_files/iso-8859-file.txt")).


space_guy_never_recoded()->
    er_zauker_util:load_file("./test_files/test_all_spaces.txt"),
    SearchFilesResult=er_zauker_app:erlist("    "),
    ?assertEqual([],SearchFilesResult).



zauker_skip_aready_indexed_test()->
    Fname = "./test_files/md5-test2.txt",
    Checksum = "cf5c2458a05d9f0870cd9fbd3e01fa0e",
    %%?assertEqual(Checksum,er_zauker_util:md5_file(Fname)),
    er_zauker_util:load_file_if_needed(Fname),
    {ok, C} = eredis:start_link(),
    {ok, Stuff}=eredis:q(C,["GET",string:concat("cz:md5:",Fname)]),
    ExpectedNothing2Do=er_zauker_util:load_file_if_needed(Fname),
    ?assertMatch( {already_indexed}, ExpectedNothing2Do),    
    ?assertEqual(Checksum,binary_to_list(Stuff)).
 


ensure_good_trigrams()->
    %% TODO: Delete bad trigram at the start, to avoid false positives...
    %% GG Try to force bad trigrams like trigram:ci:\n  
    ?assertMatch( {ok},er_zauker_util:load_file("./test_files/bad_trigram_split.txt")),
    {ok, C} = eredis:start_link(),
    {ok, Stuff}=eredis:q(C,["KEYS","trigram:ci:*"]),  
    %% "trigram:ci:abc"
    Bad = [ T || T <- Stuff, string:len(binary_to_list(T)) /= 14 ],
    ?assertEqual([],Bad).

%% makeIntegrationSearch_test()->
%%     R=eredis:start_link(),
%%     T=er_zauker_app:makeSearchTrigram("herhec"),
%%     ?debugVal(T),
%%     Ids=er_zauker_app:listFileIds(T,R),
%%     ?debugVal(Ids).
    
-endif.


