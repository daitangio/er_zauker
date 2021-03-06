-module(er_zauker_app).
-author("giovanni.giorgi@gioorgi.com").

-compile([native]).
-behaviour(application).

%% Application callbacks
-export([start/2, stop/1, startIndexer/0, 
	 indexerDaemon/3,indexDirectory/1,makeSearchTrigram/1,listFileIds/2,map_ids_to_files/2,
	 erlist/1,erlist/2,
	 wait_worker_done/0]).

%% Supported languages by CodeZauker are filtered via the following regexp
%% Emacs lisp is very bad because generate a lot of trigrams
%% xml is supported only because it is used a lot on some java projects
%% but personally I hate it.
%% .cs=C# source file
-define(SCAN_REGEXP,".*[.](java|xml|c|cpp|erl|sql|cs|txt|markdown|properties|ini|el|rb|php|coffee)$").


%% ===================================================================
%% Application callbacks
%% ===================================================================

start(_StartType, _StartArgs) ->
    %% YUM No good supervisor  right now.... 
    er_zauker_sup:start_link().
    

stop(_State) ->   
    er_zauker_indexer!{self(),stop},
    %% TODO: check if stopped itself
    ok.


startIndexer()->
    er_zauker_rpool:start_link(),    
    register(er_zauker_indexer,spawn(er_zauker_app, indexerDaemon, [ 0,0 , #{} ] )),   
    io:format("~n---------------------------------------------------"),
    io:format("~n--------------- Started Er Zauker App -------------"),
    io:format("~n- $Id$ -"),
    io:format("~n"),
    ok.



%%% SUPPORT API:
%% @doc wait_worker_done()
%% will return control only when all workers have done.
%% 
wait_worker_done()->
    waitAllWorkerDone(1,erlang:monotonic_time(second)).



waitAllWorkerDone(RunningWorker,StartTimestamp) when RunningWorker >0 ->
    er_zauker_indexer!{self(),report},
    receive 
	{worker,0} ->
	    io:format("All workers done~n~n");
	{worker, RunningGuys, files_processed, TotalFilesDone} ->
	    if 
		RunningGuys  /= RunningWorker -> 
		    % Compute the time difference
		    SecondsRunning= erlang:monotonic_time(second)-StartTimestamp,
		    FilesSec=TotalFilesDone/SecondsRunning,
			io:format("[~p]s Workers[~p] Files processed:~p Files/sec: ~p ~n",[SecondsRunning,RunningGuys,TotalFilesDone,FilesSec]),
		    timer:sleep(200);
	       true -> 
		    %% Okey so nothing changed so far...sleep a bit
		    timer:sleep(100)
	    end,
	    %% Master sleep value
	    timer:sleep(990),
	    waitAllWorkerDone(RunningGuys,StartTimestamp)
    after 5000 ->
	    io:format("~n-----------------------------~n"),
	    io:format(" Mmmm no info in the last 5 sec... when was running:~p Workers~n",[RunningWorker]),
	    io:format(" ?System is stuck? "),
	    io:format("------------------------------~n"),
	    waitAllWorkerDone(RunningWorker,StartTimestamp)
    end;
waitAllWorkerDone(0,_) ->
    io:format("All worker Finished").


indexerDaemon(RunningWorker, FilesProcessed,MonitorRefMap)->
    receive
	{_Pid,file,FileToIndex}->
	    % Spawn a worker for indexing this file
	    NewPid=spawn(er_zauker_util, load_file_if_needed,[FileToIndex]),
	    %% ALWAYS REINDEX: NewPid=spawn(er_zauker_util, load_file,[FileToIndex]),
	    MonitorRef = erlang:monitor(process,NewPid),
		NewRefMap=MonitorRefMap#{ MonitorRef => FileToIndex },
		% TODO Store the REF in a small table
	    indexerDaemon(RunningWorker+1,FilesProcessed,NewRefMap);
	{_Pid,directory, DirectoryPath} ->
	    NewPid=spawn(er_zauker_app,indexDirectory,[DirectoryPath]),
	    %% Mmm technically directory are not "files"
	    erlang:monitor(process,NewPid),
	    indexerDaemon(RunningWorker+1,FilesProcessed,MonitorRefMap);
	{'DOWN', Reference, process, _Pid, normal} ->
		indexerDaemon(RunningWorker-1,FilesProcessed+1,
			maps:remove(Reference,MonitorRefMap) );
	{'DOWN', Reference, process, Pid, {timeout, Detail}} ->
		%% MMMmm we must assume still files to be processed?
		#{ Reference := FailedFile } = MonitorRefMap,
		io:format("!! Timeout Error on ~p ~n Detail: ~p~n", [FailedFile, {'DOWN', Reference, process, Pid, {timeout, Detail}}]),		
		% We suppose a timeout error and we push back
		% Remove old Reference
		UpdatedRefMap=maps:remove(Reference,MonitorRefMap),
	    NewPid=spawn(er_zauker_util, load_file_if_needed,[FailedFile]),	    
	    MonitorRef = erlang:monitor(process,NewPid),
		NewRecoveryRefMap=UpdatedRefMap#{ MonitorRef => FailedFile },
		indexerDaemon(RunningWorker,FilesProcessed,NewRecoveryRefMap);
	{CallerPid,running} ->
	    %%io:format("Asked Running Worker:~p~n",[RunningWorker]),
	    CallerPid!{worker,RunningWorker},
	    indexerDaemon(RunningWorker,FilesProcessed,MonitorRefMap);
	{Pid, files_processed} ->
	    Pid!{files_processed,FilesProcessed},
	    indexerDaemon(RunningWorker,FilesProcessed,MonitorRefMap);
	{Pid, report} ->
	    Pid!{worker,RunningWorker,files_processed,FilesProcessed},
	    indexerDaemon(RunningWorker,FilesProcessed,MonitorRefMap);
	code_switch ->
	    io:format("Reloading code...."),
	    er_zauker_app:indexerDaemon(RunningWorker,FilesProcessed,MonitorRefMap);
	{Pid,stop} ->
	    Pid!{stoped,self()}
    end.
	 

% directory_count_files(Pid,DirectoryPath)->
% 	Files2Scan=filelib:fold_files(DirectoryPath,?SCAN_REGEXP , true, fun priv_file_count/2, 0),
% 	Pid ! { directory_count, Files2Scan}.

% priv_file_count(_Filename, Acc)->
% 	Acc+1.

%% @doc returns the number of file to index.
indexDirectory(Directory)->    
    Files2Scan=filelib:fold_files(Directory,?SCAN_REGEXP , true, fun priv_index_file/2, 0),
    io:format("Scanned Dir:~p Files found:~p ~n",[Directory,Files2Scan]),
    Files2Scan.

%% Very aggressive Spawn
priv_index_file(Filename, Acc)->
    %%io:format("**Indexing File  ~p~n",[Filename]),
    er_zauker_indexer!{self(),file,Filename},
    Acc+1.

%%% Client SIDE API

erlist(SearchString)->
    %% Default timeout on gen server is 5000,
    %% too low for a big redis and a long word to SINTER
    erlist(SearchString,10000).

erlist(SearchString, Timeout)->    
    ReconnectSleep=100,
    {ok,C}=eredis:start_link("127.0.0.1", 6379, 0, "",ReconnectSleep,Timeout),
    Sgram=makeSearchTrigram(SearchString),    
    Ids=listFileIds(Sgram,C),
    map_ids_to_files(Ids,C).

map_ids_to_files([Id1|Rest],C)->
    {ok, Filename}=eredis:q(C,["GET", string:concat("fscan:id2filename:",Id1)]),
    [Filename | map_ids_to_files(Rest,C)];

map_ids_to_files([],_C)->
    [].

listFileIds(TrigramList,Redis)->
    {ok, Stuff}=eredis:q(Redis,["SINTER" | TrigramList]),
    Stuff.

makeSearchTrigram(Term)->
    makeSearchTrigramWithPrefix(string:to_lower(Term),"trigram:ci:").

makeSearchTrigramWithPrefix(ToSplit,Prefix)->
    Size = string:len(ToSplit),
    if Size =<3 -> 
	    [string:concat(Prefix,ToSplit)];
       true ->
	    CurrentGram=string:substr(ToSplit,1,3),
	    [string:concat(Prefix,CurrentGram) | makeSearchTrigramWithPrefix(string:substr(ToSplit,2),Prefix)]
    end.
