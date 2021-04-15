%% Example module based on leptus
%% https://github.com/sinasamavati/leptus
-module(er_coros).
-compile({parse_transform, leptus_pt}).

%% leptus callbacks
-export([init/3]).
-export([get/3]).
-export([terminate/4]).

init(_Route, _Req, State) ->
    {ok, State}.

get("/", _Req, State) ->
    {<<"Hello, leptus!">>, State};
get("/hi/:name", Req, State) ->
    Status = ok,
    Name = cowboy_req:binding(name, Req),
    Body = #{<<"say">> => <<"Hi">>, <<"to">> => Name},
    {Status, Body, State}.

terminate(_Reason, _Route, _Req, _State) ->
    ok.