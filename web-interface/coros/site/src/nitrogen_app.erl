-module(nitrogen_app).
-behaviour(application).
-export([start/2, stop/1]).

%% ===================================================================
%% Application callbacks
%% ===================================================================

start(_StartType, _StartArgs) ->
    io:format("~n-------------------------------"),
    io:format("~n-- COROS Starting Zauker ----~n"),
    er_zauker_app:startIndexer(),
    io:format("~n-- COROS Zauker Indexer OK ----~n"),    
    %% For developing, ensure sync is running
    sync:go(),
    nitrogen_sup:start_link().

stop(_State) ->
    ok.
