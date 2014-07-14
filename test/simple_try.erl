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
    ?debugVal(sets:to_list(TrigramSet)),
	?debugTime("Simple split of readme taken", er_zauker_util:split_file_in_trigrams("../readme.org")).


%% See http://sacharya.com/md5-in-erlang/
%% http://www.enchantedage.com/hex-format-hash-for-md5-sha1-sha256-and-sha512
hexstring(<<X:128/big-unsigned-integer>>) ->
    lists:flatten(io_lib:format("~32.16.0b", [X])).

md5_t1_test()->
    %% hexstring(<>) -> lists:flatten(io_lib:format(”~32.16.0b”, [X])).
    Checksum=erlang:md5("Er Zauker Rulez!"),
    ?assertEqual("339ba17e09c7834ab85b93009154da7c",hexstring(Checksum)  ).

md5_test()->   
    ?assertEqual("339ba17e09c7834ab85b93009154da7c",
		 er_zauker_util:md5("Er Zauker Rulez!")).

%% Try to slurp a test file

md5sum_raw_test()->
    %% See File test_files/md5-sum-checksums.txt
    %% for expected values
    Checksum=er_checksums:md5sum("../test_files/md5-test.txt"),
    ?assertEqual("967a905f9ecd311e14e7582bc5b96898",Checksum).


md5_file1_test()->
     er_zauker_util:md5_file("../test_files/md5-test.txt").

md5_file2_test()->
     ?assertEqual("cf5c2458a05d9f0870cd9fbd3e01fa0e",
		  er_zauker_util:md5_file("../test_files/md5-test2.txt")).


%% -export([print_file_name/2]).

print_file_name(F,_A)->
    ?debugVal(F).

file_scan_test_disab()->
    filelib:fold_files("/tmp",".*",true, fun print_file_name/2,{nothing}).



    
-endif.


