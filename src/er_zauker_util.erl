-module(er_zauker_util).
-author("giovanni.giorgi@gioorgi.com").

-export([load_file/1,
	 trigram/1,itrigram/1,split_on_set/1,split_on_set/2, get_unique_id/1, split_file_in_trigrams/1, good_trigram/1]).

%%% Space guy is the tree-spaced guy
-define(SPACE_GUY,"   ").

%% @doc Split a string in 3-pair trigrams. Case Sensitive
trigram(ToSplit)->
    Size = string:len(ToSplit),
    if
	Size =< 3 ->
	    [ToSplit];
	true  ->
	    Trigram=string:substr(ToSplit,1,3),
	    [  Trigram   | trigram( string:substr(ToSplit,2) ) ]		
    end.

%% @doc Case insensitive variant (not used, only for proof)
itrigram(ToSplit)->
    Lowered=string:to_lower(ToSplit),
    trigram(Lowered).

%% @doc Split a string to trigram, and push the trigrams to the set.
%% Used before commiting it to redis
split_on_set(ToSplit,Set1) ->
    List2Store=trigram(ToSplit),
    Set2=sets:from_list(List2Store),
    sets:union(Set1,Set2).

% Optimized to avoid building a spourious set
split_on_set(ToSplit) ->
    List2Store=trigram(ToSplit),
    sets:from_list(List2Store).

%% Obtain a brand new string fscan:nextId
get_unique_id(C)->
    {ok, ID}=eredis:q(C, ["INCR", "fscan:nextId"]),
    binary_to_list(ID).

%% Returns a Set of unique trigrams
split_file_in_trigrams(Fname)->
    case file:open(Fname,[read,{encoding,utf8}, {read_ahead,5000}]) of
	{ok,Fd}->
	    scan_file_trigrams(Fd,sets:new(),file:read_line(Fd));
	{error,Reason} ->
	    {error,Reason}
    end.


good_trigram(Element)->    
    Element /= "   ".



scan_file_trigrams(Fd,TrigramSet, {ok, StringToSplit})->
    NewSet=split_on_set(StringToSplit,TrigramSet),    
    scan_file_trigrams(Fd,NewSet,file:read_line(Fd));

scan_file_trigrams(Fd,TrigramSet, eof)->
    file:close(Fd),
    % Remove the bad guys right now
    FilteredSet=sets:filter(fun good_trigram/1,TrigramSet),
    io:format("*Set Size:~p~n",[sets:size(FilteredSet)]),
    {ok,FilteredSet};

scan_file_trigrams(Fd, _TrigramSet, {error,Reason}) ->
    file:close(Fd),
    {error,Reason}.   


redis_pusher(Trigram, Accumulator)->
    {data, Redis, FileId, Counter }=Accumulator,
    eredis:q(Redis,["SADD", string:concat("trigram:",Trigram),FileId]),
    eredis:q(Redis,["SADD", string:concat("fscan:trigramsOnFile:",FileId),Trigram]),
    eredis:q(Redis,["SADD", string:concat("trigram:ci:",string:to_lower(Trigram)),FileId]),
    AccOut={data, Redis, FileId, Counter+1 },
    AccOut.

%% @doc Master Entry Point:
%% Load a file, split in trigrams and push on Redis
%% The file split is 
load_file(Fname)->
    {ok, C} = eredis:start_link(),
    load_file(Fname,C).

load_file(Fname,C)->
    {ok, Stuff}=eredis:q(C,["GET",string:concat("fscan:id:",Fname)]),
    case Stuff of
	undefined -> FileId=er_zauker_util:get_unique_id(C),
		     eredis:q(C,["SET", string:concat("fscan:id:",Fname),FileId]),
		     eredis:q(C,["SET", string:concat("fscan:id2filename:",FileId),Fname]),
		     io:format("New FileId:~p For File: ~p~n",[FileId,Fname]);
	_ -> FileId=binary_to_list(Stuff),
	     io:format("Already Found FileId:~p For File: ~p~n",[FileId,Fname])
    end,
    io:format("Splitting files...~n"),
    {ok, TrigramSet}=split_file_in_trigrams(Fname),
    io:format("Pushing data...~n"),
    %% %% Now wrap the redis_pusher function inside a multi/exec transaction
    {ok, <<"OK">>} = eredis:q(C, ["MULTI"]),    
    {data, _Redis, _FileId, MyCounter }=sets:fold(fun redis_pusher/2,{data, C, FileId,0 },TrigramSet),
    %% %%{ok, [<<"OK">>, <<"OK">>]} = eredis:q(C, ["EXEC"]),
    eredis:q(C, ["EXEC"]),
    io:format("Elements pushed: ~p~n", [MyCounter]),
    {ok}.


%%TODO VIA file:list_dir be ready to do a major scan
%% Setup a separate process for slurping trigrams