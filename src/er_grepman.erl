-module(er_grepman).
-behaviour(gen_server).

-compile([export_all, native]).


start_link()->
    R=gen_server:start_link({local, er_grepman}, er_grepman, [], []),
    sys:trace(er_grepman,true),    
    R.


%%% Public API
-spec grep(string(), [string()]) ->[string()] | {error,string()}.
grep(Query,FileCandidates) ->
    R=gen_server:call(er_grepman, {search_for_on,Query,FileCandidates}),
    case R of
	{error, Reason} ->
	    {error, Reason};
	{ok, ListOfStuff} ->
	    ListOfStuff
    end.
%%% End Public Api


%%% GEN SERVER
init([]) ->
    GrepCmdState="grep -n  -C1 -i --no-messages ",
    {ok,GrepCmdState}.

terminate(Reason,State) ->
    %% Reason = normal | shutdown | {shutdown,term()} | term()
    {return_value_ignored}.


handle_call({search_for_on, Query,FileCandidates}, _From, State) ->
    {reply,{error,"NotImplemented"},State}.

handle_cast(_Bho,Status)->
    {noreply, Status}.


code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

handle_info({'EXIT', _Pid, _Reason}, State) ->
    %% ..code to handle exits here..
    {noreply, State}.

