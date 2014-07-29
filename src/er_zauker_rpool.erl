-module(er_zauker_rpool).
-author("giovanni.giorgi@gioorgi.com").


-export([startRedisPool/0,wait4Connection/0,releaseConnection/1,delegate_connection2redis/1]).

%%% Too many redis connection are bad bacause lead to
%% =ERROR REPORT==== 15-Jul-2014::11:38:05 ===
%% Error in process <0.10173.0> on node 'Cli@eva1.esp.internal.usinet.it' with exit value: {{badmatch,{error,{connection_error,{connection_error,timeout}}}},[{er_zauker_util,load_file,1,[{file,"src/er_zauker_util.erl"},{line,89}]}]}
%% So to avoid it we create a simple 'semaphore' to ask if we can proceed or not: this is the responsability
%% of er_zauker_rpool module

-define(TIMEOUT, 5000).

%% @doc Define here max connections (redis default maximum is 10.000).
%% To track it from the redis side use  the follwing  shell command
%% watch -d 'redis-cli client list | wc -l'
%% 
%% Erlang will magically optimize the load around this value.
%% Note: Redis must have enough ram to concurrently save the index
%% or you will start getting errors
-define(MAX_CONNECTIONS,3500).

%% Put this value 0 to stick with MAX_CONNECTIONS
%% or let erlang grow freely. 
-define(GROW_FACTOR,0).

startRedisPool()->
    register(rpool,spawn(fun rpoolman/0)).


rpoolman()->
    rpool(?MAX_CONNECTIONS).



%%% PUBLIC API
wait4Connection()->
    rpool!{self(),ask},
    receive
	{ok}->
	    % Returns {error,no_redis} if redis is down. Consider retry connect
	    {ok_proxed, C} = safe_redis_connect(),
	    C
       %% after 60000 ->
       %% 	       io:format("~n~p Mmmm still waiting Redis connection After 1 minute~n", [self()]),
       %% 	       wait4Connection()		 
    end.

releaseConnection(C)->
    rpool!{self(),release,C}.


%%%% INTERNALS FOLLOW


%%% If redis connection is unailable, The process running delegate will crash
%%% So delegate is a simple "proxy"
delegate_connection2redis(Caller)->
	try	   	     
	    ERedisResponse=eredis:start_link(),
	    Caller ! ERedisResponse
	catch
	   _ ->
	      erlang:display(erlang:get_stacktrace()),
		Caller ! {error,unexpected}
	end.

%% @doc In case of error returns {error, ReasonAtom } 
safe_redis_connect()->
    Pidz=spawn(er_zauker_rpool,delegate_connection2redis,[self()]),
    receive 
	{ok,C} ->
	    {ok_proxed,C};
	_ -> {error,no_redis}
    after 5000 ->
	    case process_info(Pidz) of
		undefined ->
		    {error,no_redis};
		_ -> {error,redis_delegate_timeout}
	    end
    end.









rpool(RemainingConnections)->
    %% if RemainingConnections <3 -> io:format("RedisFree Connections: ~p~n",[RemainingConnections]);
    %%    true -> nothing2say
    %% end,
    receive 
	{Pid, ask} ->
	    if RemainingConnections >0 ->
		    Pid!{ok},
		    rpool(RemainingConnections-1);	       
	       true ->
		    % Asker is the first asking for a scare resourec so we enter in release only "mode".
		    % subsequent calls will be enqueued by erlang
		    rpoolReleaseOnlyMode(Pid)
	    end;
	{_Pid, release, Connection2Release} ->	    
	    eredis:stop(Connection2Release),
	    %%Pid!{ok},
	    rpool(RemainingConnections+1)
    end.
	    
	
    
rpoolReleaseOnlyMode(FirstWaitingPid)->
    %% decomment the following line to monitor when the pool fills up:
    %% io:format("All ~p connections filled up~n",[?MAX_CONNECTIONS]),
    receive
	{_Pid, release, Connection2Release}->
	    eredis:stop(Connection2Release),
	    FirstWaitingPid!{ok},
	    %% Now we have just consumed the resource so we have zero resources
	    %% We can decide to grow a bit or to simply stay with 0 connectins
	    rpool(?GROW_FACTOR)
    end.    
