#!/usr/bin/env escript
%% -*- erlang -*-
%%!  -pa ./_build/default/lib/eredis/ebin/ -pa ./_build/default/lib/er_zauker/ebin/  debug verbose
main([SearchString]) ->    
    %%er_zauker_app:startIndexer(),
    %io:write(SearchString),
    Candidates=er_zauker_app:erlist(SearchString),
    lists:foreach( fun(E) ->
	    %% we double ~ on file name to avoid error from fwrite
            io:fwrite( re:replace(E,"~","~~",[{return,list}])),
	    io:fwrite("\n")
        end,Candidates).


