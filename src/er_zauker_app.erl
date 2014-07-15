-module(er_zauker_app).
-author("giovanni.giorgi@gioorgi.com").

-behaviour(application).

%% Application callbacks
-export([start/2, stop/1, startIndexer/0, indexerDaemon/0,indexDirectory/1,makeSearchTrigram/1,listFileIds/2,map_ids_to_files/2,erlist/1]).

%% ===================================================================
%% Application callbacks
%% ===================================================================

start(_StartType, _StartArgs) ->
    er_zauker_sup:start_link().

stop(_State) ->
    ok.


startIndexer()->
    er_zauker_rpool:startRedisPool(),
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
	 

%% Basic indexer uses mulitple workers...
indexDirectory(Directory)->    
    filelib:fold_files(Directory, ".*", true, fun priv_index_file/2, {nothing}),
    io:format("Scanned Dir:~p~n",[Directory]).

%% Very aggressive Spawn
priv_index_file(Filename, _Acc)->
    %%io:format("**Indexing File  ~p~n",[Filename]),
    er_zauker_indexer!{self(),file,Filename}.

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
