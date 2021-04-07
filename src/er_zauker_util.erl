-module(er_zauker_util).
-author("giovanni.giorgi@gioorgi.com").

%% GG Consider also 'episcina' as resource pool

%% hipe optimization: please compile this module in x64
%% -compile([native, 
%% 	  {hipe,[
%% 		 o3, %% OPTIMIZE A lot
%% 		 {verbose,true}
%% 		]}]).

-export([load_file_if_needed/1,
	 load_file/1,
	 trigram/1,split_on_set/1,split_on_set/2, 
	 split_file_in_trigrams/1, good_trigram/1, 
	 md5_file/1
	]).

%%% Space guy is the tree-spaced guy
%%% Which is NEVER NEVER INDEXED
-define(SPACE_GUY,"   ").


good_trigram(Element)->    
    NoSpace=Element /= ?SPACE_GUY,
    NoSpace.
    



%% @doc Split a string in 3-pair trigrams. Case insensitive
trigram(ToSplit)->
    Size = string:len(ToSplit),
    if
	Size < 3 ->
	    [];
	Size =:= 3 ->
	    [string:to_lower(ToSplit)];
	true  ->
	    Trigram=string:to_lower(string:substr(ToSplit,1,3)),
	    [  Trigram   | trigram( string:substr(ToSplit,2) ) ]		
    end.


%% @doc Split a string to trigram, and push the trigrams to the set.
%% Used before commiting it to redis
%% From v0.0.5 optimized to avoid calling trigram(): we split directyl the bad guy.
%% The new impl passed from 6.70 uS to 3.53 uS / call approx
%% Return the nre set. If the string is LESS THEN 3 CHAR, NOTHING IS DONE
split_on_set(ToSplit,Set1) ->
    Size = string:len(ToSplit),
    if 
	Size < 3 ->
	    Set1;
	Size =:= 3 ->
	    sets:add_element(ToSplit,Set1);
       true ->
	    Trigram=string:to_lower(string:substr(ToSplit,1,3)),
	    Remaining=string:substr(ToSplit,2),
	    NewSet=sets:add_element(Trigram,Set1),
	    split_on_set(Remaining,NewSet)
    end.

% Optimized to avoid building a spourious set
split_on_set(ToSplit) ->
    List2Store=trigram(ToSplit),
    sets:from_list(List2Store).

%% Obtain a brand new string fscan:nextId
get_unique_id(C)->
    {ok, ID}=eredis:q(C, ["INCR", "fscan:nextId"]),
    binary_to_list(ID).

increment_processed_files_counter(C)->
    {ok,ID}=eredis:q(C, ["INCR", "fscan:fileProcessed"]),
    binary_to_list(ID).


%% split_file_in_trigrams(Fname)->
%%     try split_file_in_trigrams_priv(Fname) of
%% 	Result ->
%% 	    Result	 
%%     catch
%% 	error:Error ->
%% 	    io:format("~p Error processing:~p~n",[Error,Fname]),
%% 	    throw(Error)
%%     end.

%% Returns a Set of unique trigrams
split_file_in_trigrams(Fname)->
    %% case file:open(Fname,[read,{encoding,utf8}, {read_ahead,5000}]) of
    case file:open(Fname,[read,{encoding,latin1}, {read_ahead,15000}]) of
	{ok,Fd}->
	    scan_file_trigrams(Fd,sets:new(),file:read_line(Fd));
	{error,Reason} ->
	    {error,Reason}
    end.




scan_file_trigrams(Fd,TrigramSet, {ok, StringToSplit})->
    NewSet=split_on_set(StringToSplit,TrigramSet),    
    scan_file_trigrams(Fd,NewSet,file:read_line(Fd));

scan_file_trigrams(Fd,TrigramSet, eof)->
    file:close(Fd),
    % Remove the bad guys right now
    FilteredSet=sets:filter(fun good_trigram/1,TrigramSet),
    %% io:format("*Set Size:~p~n",[sets:size(FilteredSet)]),
    {ok,FilteredSet};

scan_file_trigrams(Fd, _TrigramSet, {error,Reason}) ->
    file:close(Fd),    
    {error,Reason}.   


redis_pusher(Trigram, Accumulator)->
    {data, Redis, FileId, Counter }=Accumulator,
    eredis:q(Redis,["SADD", string:concat("fscan:trigramsOnFile:",FileId),Trigram]),
    %%eredis:q(Redis,["SADD", string:concat("trigram:ci:",string:to_lower(Trigram)),FileId]),
    eredis:q(Redis,["SADD", string:concat("trigram:ci:",Trigram),FileId]),
    AccOut={data, Redis, FileId, Counter+1 },
    AccOut.

iolist_equal(A, B) ->
    iolist_to_binary(A) =:= iolist_to_binary(B).

%% @doc Master Entry Point:
%% Load a file, split in trigrams and push on Redis
%% If the file md5 is already here, we skip it (optimization)
load_file_if_needed(Fname)->
    C=er_zauker_rpool:wait4Connection(),
    CurrentChecksum=md5_file(Fname),
    MD5Key=string:concat("cz:md5:",Fname),
    {ok, Stuff}=eredis:q(C,["GET",MD5Key]),
    case Stuff of
	undefined ->
	    %% format("~p Brand new file ~p ~n",[Fname,Stuff]),
	    Reply=load_file(Fname,C),	    
	    %%io:format("New MD5 ~p = ~p ~n",[MD5Key,CurrentChecksum]),
	    eredis:q(C,["SET",MD5Key,CurrentChecksum]);
	Checksum2Verify -> 	    	    
	    case iolist_equal(CurrentChecksum, Checksum2Verify) of
		true ->
		    %% io:format("File unchanged,Skipped:~p~n",[Fname]),
		    Reply={already_indexed};
	       false ->
		    %% TODO: we should the if from all the trigrams it belongs!
		    io:format("File ~p changed~n",[Fname]),
		    Reply=load_file(Fname,C),
		    eredis:q(C,["SET",MD5Key,CurrentChecksum]),
		    io:format("Reindexed MD5 OLD:~p NEW:: ~p = ~p ~n",[Checksum2Verify,MD5Key,CurrentChecksum])
	    end
    end,
    %% Signal file pushed
    increment_processed_files_counter(C),
    %% Release connection
    er_zauker_rpool:releaseConnection(C),
    Reply.
	    

load_file(Fname)->    
    C=er_zauker_rpool:wait4Connection(),
    ReturnedValue=load_file(Fname,C),
    er_zauker_rpool:releaseConnection(C),
    ReturnedValue.

load_file(Fname,C)->
    {ok, Stuff}=eredis:q(C,["GET",string:concat("fscan:id:",Fname)]),
    case Stuff of
	undefined -> FileId=get_unique_id(C),
    		     %%io:format("New FileId:~p For File: ~p~n",[FileId,Fname]),
		     eredis:q(C,["SET", string:concat("fscan:id:",Fname),FileId]),
		     eredis:q(C,["SET", string:concat("fscan:id2filename:",FileId),Fname]);
	_ -> %%io:format("Changed or not successfuly processed: ~p~n",[Fname]),	    
	     FileId=binary_to_list(Stuff)	     
    end,
    %%io:format("Splitting files...~n"),
    %%?optimization tip: release redis now, and take it back after
    %% but you must remove C from /every/ reference
    case split_file_in_trigrams(Fname) of
	{error,Reason} ->
	    io:format("Unable to parse ~p ~p ~n",[Fname,Reason]),
	    %% TODO: mark file somewhat
	    {error,Reason};
	{ok, TrigramSet}->
	    %% io:format("Pushing data...~n"),	
	    %% Now wrap the redis_pusher function inside a multi/exec transaction
	    {ok, <<"OK">>} = eredis:q(C, ["MULTI"]),    
	    {data, _Redis, _FileId, _MyCounter }=sets:fold(fun redis_pusher/2,{data, C, FileId,0 },TrigramSet),
	    eredis:q(C, ["EXEC"]),
	    %% io:format("~p pushed: ~p~n", [Fname, MyCounter]),
	    {ok}
    end.


%% See http://sacharya.com/md5-in-erlang/
%% http://www.enchantedage.com/hex-format-hash-for-md5-sha1-sha256-and-sha512
%% http://rosettacode.org/wiki/MD5#Erlang
%% my_hexstring(<<X:128/big-unsigned-integer>>) ->
%%     lists:flatten(io_lib:format("~32.16.0b", [X])).

%% md5(String)->
%%     my_hexstring(erlang:md5(String)).

%%TODO VIA file:list_dir be ready to do a major scan
%% Setup a separate process for slurping trigrams

%%  SEE https://github.com/sdanzan/erlang-systools/blob/master/src/checksums.erl


md5_file(Filename)->
	Stuff=readlines(Filename),
    to_hex(crypto:hash(md5,Stuff)).


readlines(FileName) ->
    {ok, Device} = file:open(FileName, [read]),
    try get_all_lines(Device)
      after file:close(Device)
    end.

get_all_lines(Device) ->
    case io:get_line(Device, "") of
        eof  -> [];
        Line -> Line ++ get_all_lines(Device)
    end.

to_hex(BitsString) ->
    Size = bit_size(BitsString),
    <<N:Size/big-unsigned-integer>> = BitsString,
    Format = "~" ++ integer_to_list(Size div 4) ++ ".16.0b",
    lists:flatten(io_lib:format(Format, [ N ])).


%% scan_file_md5(Fd,TrigramSet, {ok, StringToSplit})->
%%     NewSet=split_on_set(StringToSplit,TrigramSet),    
%%     scan_file_md5(Fd,NewSet,file:read_line(Fd));

