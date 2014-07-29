-module(er_zauker_rpool).
-behaviour(gen_server).

%% API
-export([start_link/0,wait4Connection/0, releaseConnection/1]).

%% Compatibility
-export([startRedisPool/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, code_change/3,terminate/2,handle_info/2]).

%% Push hipe
-compile([native]).

%% @doc Define here max connections (redis default maximum is 10.000).
%% To track it from the redis side use  the follwing  shell command
%% watch -d 'redis-cli client list | wc -l'
%% 
%% Erlang will magically optimize the load around this value.
%% Note: Redis must have enough ram to concurrently save the index
%% or you will start getting errors
-define(MAX_CONNECTIONS,3500).

start_link()->
    R=gen_server:start_link({local, er_zauker_rpool}, er_zauker_rpool, [], []),
    %%sys:trace(er_zauker_rpool,true),    
    R.
    

wait4Connection() ->
    R=gen_server:call(er_zauker_rpool,alloc),
    case R of
	no_connections ->
	    %% Retry in a snap...
	    timer:sleep(1000),	    
	    wait4Connection();
	{ok,C} ->
	    C
    end.

releaseConnection(C)->
    % ASYNC
    gen_server:cast(er_zauker_rpool,{free,C}).

%% @doc deprecated
startRedisPool()->
    start_link().

init([]) ->
    State=?MAX_CONNECTIONS,
    {ok,State}.

handle_call(alloc, _From, RemainingConnections)->
    if RemainingConnections >0 ->
	    {ok,ERedisResponse}=eredis:start_link(),	    
	    {reply, {ok,ERedisResponse}, RemainingConnections -1};
       true ->	   	    
	    {reply,no_connections, RemainingConnections}
    end.

handle_cast({free,C}, RemainingConnections)->
    eredis:stop(C),
    {noreply, RemainingConnections+1}.
    

terminate(normal,_State)->
    ok.

handle_info({'EXIT', _Pid, _Reason}, State) ->
    %% ..code to handle exits here..
    {noreply, State}.
				       
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

