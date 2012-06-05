-module(er_zauker_app).
-author("giovanni.giorgi@gioorgi.com").

-behaviour(application).

%% Application callbacks
-export([start/2, stop/1, startIndexer/0, indexerDaemon/0,indexDirectory/1]).

%% ===================================================================
%% Application callbacks
%% ===================================================================

start(_StartType, _StartArgs) ->
    er_zauker_sup:start_link().

stop(_State) ->
    ok.


startIndexer()->
    register(er_zauker_indexer,spawn(fun indexerDaemon/0)).



indexerDaemon()->
    receive
	{Pid,file,FileToIndex}->
	    % Spawn a worker for this guy...
	    NewPid=spawn(er_zauker_util, load_file,[FileToIndex]),
	    Pid!{worker, NewPid},
	    indexerDaemon();	
	{Pid,directory, DirectoryPath} ->
	    io:format("Recursive Indexing...~p~n",[DirectoryPath]),
	    indexDirectory(DirectoryPath),
	    Pid!{scanned_started},
	    indexerDaemon();
	{Pid,stop} ->
	    Pid!{stoped,self()}
    end.
	 

%% Basic indexer uses mulitple workers..
indexDirectory(Directory)->    
    filelib:fold_files(Directory, ".*", true, fun priv_index_file/2, {nothing}),
    io:format("Scanned Dir:~p~n",[Directory]).

priv_index_file(Filename, _Acc)->
    io:format("**Indexing File  ~p~n",[Filename]),
    er_zauker_indexer!{self(),file,Filename}.

