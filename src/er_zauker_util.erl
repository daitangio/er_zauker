-module(er_zauker_util).
-author("giovanni.giorgi@gioorgi.com").

-export([trigram/1,itrigram/1,split_on_set/1,split_on_set/2, get_unique_id/1, split_file_in_trigrams/1, good_trigram/1]).

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
    case file:open(Fname,[read,raw,binary]) of
	{ok,Fd}->
	    scan_file_trigrams(Fd,sets:new(),file:read(Fd,1024));
	{error,Reason} ->
	    {error,Reason}
    end.


good_trigram(Element)->    
    Element /= "   ".



scan_file_trigrams(Fd,TrigramSet, {ok, Binary})->
    StringToSplit=binary_to_list(Binary),
    NewSet=split_on_set(StringToSplit,TrigramSet),
    % scan_file(Fd, Occurs + count_x(Binary), file:read(Fd, 1024));
    scan_file_trigrams(Fd,NewSet,file:read(Fd,1023));

scan_file_trigrams(Fd,TrigramSet, eof)->
    file:close(Fd),
    % Remove the bad guys right now
    sets:filter(fun good_trigram/1,TrigramSet);
    %% TrigramSet;

scan_file_trigrams(Fd, _TrigramSet, {error,Reason}) ->
    file:close(Fd),
    {error,Reason}.   


%% Example of multi bulk
%% {ok, <<"OK">>} = eredis:q(C, ["MULTI"]).
%% {ok, <<"QUEUED">>} = eredis:q(C, ["SET", "foo", "bar"]).
%% {ok, <<"QUEUED">>} = eredis:q(C, ["SET", "bar", "baz"]).
%% {ok, [<<"OK">>, <<"OK">>]} = eredis:q(C, ["EXEC"]).
