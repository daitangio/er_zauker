-module(er_zauker_rpool).
-author("giovanni.giorgi@gioorgi.com").


-compile(export_all).

%%% Too many redis connection are bad bacause lead to
%% =ERROR REPORT==== 15-Jul-2014::11:38:05 ===
%% Error in process <0.10173.0> on node 'Cli@eva1.esp.internal.usinet.it' with exit value: {{badmatch,{error,{connection_error,{connection_error,timeout}}}},[{er_zauker_util,load_file,1,[{file,"src/er_zauker_util.erl"},{line,89}]}]}
%% So to avoid it we create a simple 'semaphre' to ask if we can proceed or not


startRedisPool()->
    register(rpool,spawn(fun rpoolman/0)).

%%% Define here max connections.
%%% Too high value (9000) get worst performance if redis run on the same machine.
%%% A lower value give a more balanced timing
rpoolman()->
    %%rpool(1000).
    rpool(264).



%%% PUBLIC API
wait4Connection()->
    rpool!{self(),ask},
    receive
	{ok}->
	    {ok, C} = eredis:start_link(),
	    C
       %% after 60000 ->
       %% 	       io:format("~n~p Mmmm still waiting Redis connection After 1 minute~n", [self()]),
       %% 	       wait4Connection()		 
    end.

releaseConnection(C)->
    rpool!{self(),release,C}.


%%%% INTERNALS FOLLOW




rpool(RemainingConnections)->
    if RemainingConnections <5 -> io:format("RedisFree Connections: ~p~n",[RemainingConnections]);
       true -> nothing2say
    end,
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
    io:format("ReleaseOnlyMode~n"),
    receive
	{_Pid, release, Connection2Release}->
	    eredis:stop(Connection2Release),
	    FirstWaitingPid!{ok},
	    %% Now do a double bump
	    rpool(2)
    end.    
