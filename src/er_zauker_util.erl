-module(er_zauker_util).
-author("giovanni.giorgi@gioorgi.com").

-export([trigram/1,itrigram/1,split_on_set/1,split_on_set/2, get_unique_id/1]).

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

get_unique_id(C)->
    {ok, ID}=eredis:q(C, ["INCR", "fscan:nextId"]),
    list_to_integer(binary_to_list(ID)).

