-module(er_zauker_util).
-author("giovanni.giorgi@gioorgi.com").

-export([trigram/1,itrigram/1]).

%% @doc Split a string in 3-pair trigrams
trigram(ToSplit)->
    Size = string:len(ToSplit),
    if
	Size =< 3 ->
	    [ToSplit];
	true  ->
	    Trigram=string:substr(ToSplit,1,3),
	    [Trigram | trigram( string:substr(ToSplit,4) ) ]		
    end.
	
itrigram(ToSplit)->
    Lowered=string:to_lower(ToSplit),
    trigram(Lowered).
