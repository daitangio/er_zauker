-module(er_zauker_app).
-author("giovanni.giorgi@gioorgi.com").

-behaviour(application).

%% Application callbacks
-export([start/2, stop/1, startIndexer/0, 
	 indexerDaemon/1,indexDirectory/1,makeSearchTrigram/1,listFileIds/2,map_ids_to_files/2,
	 erlist/1,
	 wait_worker_done/0]).

%% ===================================================================
%% Application callbacks
%% ===================================================================

start(_StartType, _StartArgs) ->
    er_zauker_sup:start_link().

stop(_State) ->
    ok.


startIndexer()->
    er_zauker_rpool:startRedisPool(),
    register(er_zauker_indexer,spawn(er_zauker_app, indexerDaemon, [ 0 ] )).



%%% SUPPORT API:
%% @doc wait_worker_done()
%% will return control only when all workers have done.
%% 
wait_worker_done()->
    waitAllWorkerDone(-1,erlang:now()).

waitAllWorkerDone(RunningWorker,StartTimestamp)->
    er_zauker_indexer!{self(),running},
    receive 
	{worker,0} ->
	    io:format("All workers done~n~n");
	{worker, RunningGuys} ->
	    if 
		RunningGuys  /= RunningWorker -> 
		    % Print and compute the microseconds (10^-6) time difference
		    MsRunning=timer:now_diff(erlang:now(),StartTimestamp),
		    MillisecondRunning=MsRunning/1000,
		    io:format("[~p]ms Working:~p~n",[MillisecondRunning,RunningGuys]);
	       true -> 
		    %% Okey so nothing changed so far...sleep a bit to readuce load
		    timer:sleep(100)
	    end,
	    %% Sleep a bit MORE
	    timer:sleep(600),
	    waitAllWorkerDone(RunningGuys,StartTimestamp)
    after 5000 ->
	    io:format("~n-----------------------------~n"),
	    io:format(" Mmmm no info in the last 5 sec... when was running:~p~n",[RunningWorker]),
	    io:format("------------------------------~n"),
	    waitAllWorkerDone(RunningWorker,StartTimestamp)
    end.

indexerDaemon(RunningWorker)->
    receive
	{_Pid,file,FileToIndex}->
	    % Spawn a worker for this guy...
	    NewPid=spawn(er_zauker_util, load_file_if_needed,[FileToIndex]),
	    erlang:monitor(process,NewPid),
	    indexerDaemon(RunningWorker+1);	
	{_Pid,directory, DirectoryPath} ->
	    NewPid=spawn(er_zauker_app,indexDirectory,[DirectoryPath]),
	    erlang:monitor(process,NewPid),
	    indexerDaemon(RunningWorker+1);
	{'DOWN', _Reference, process, _Pid, _Reason} ->
	    %%io:format("Just down: ~p~n", [{'DOWN', Reference, process, Pid, Reason}]),
	    indexerDaemon(RunningWorker-1);
	{CallerPid,running} ->
	    %%io:format("Asked Running Worker:~p~n",[RunningWorker]),
	    CallerPid!{worker,RunningWorker},
	    indexerDaemon(RunningWorker);		
	{Pid,stop} ->
	    Pid!{stoped,self()}
    end.
	 

%% @doc returns the number of file to index.
indexDirectory(Directory)->    
    Files2Scan=filelib:fold_files(Directory, ".*", true, fun priv_index_file/2, 0),
    io:format("Scanned Dir:~p Files found:~p ~n",[Directory,Files2Scan]),
    Files2Scan.

%% Very aggressive Spawn
priv_index_file(Filename, Acc)->
    %%io:format("**Indexing File  ~p~n",[Filename]),
    er_zauker_indexer!{self(),file,Filename},
    Acc+1.

%%% Client SIDE API


erlist(SearchString)->
    {ok,C}=eredis:start_link(),
    Sgram=makeSearchTrigram(SearchString),
    Ids=listFileIds(Sgram,C),
    map_ids_to_files(Ids,C).

map_ids_to_files([Id1|Rest],C)->
    {ok, Filename}=eredis:q(C,["GET", string:concat("fscan:id2filename:",Id1)]),
    [Filename | map_ids_to_files(Rest,C)];

map_ids_to_files([],_C)->
    [].

listFileIds(TrigramList,Redis)->
    %% @redis.sinter(*trigramInAnd)
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
