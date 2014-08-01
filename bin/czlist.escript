#!/usr/bin/env escript
%% -*- erlang -*-
%%!  -pa deps/eredis/ebin/ -pa ebin/  debug verbose
main([SearchString]) ->    
    %%er_zauker_app:startIndexer(),
    %io:write(SearchString),
    Candidates=er_zauker_app:erlist(SearchString),
    lists:foreach( fun(E) ->
	    %% we double ~ on file name to avoid error from fwrite
            io:fwrite( re:replace(E,"~","~~",[{return,list}])),
	    io:fwrite("\n")
        end,Candidates).


