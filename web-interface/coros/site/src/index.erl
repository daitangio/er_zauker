%% -*- mode: nitrogen -*-
-module (index).
-compile(export_all).
-include_lib("nitrogen_core/include/wf.hrl").

main() -> #template { file="./site/templates/bare.html" }.

title() -> "Welcome to Coros, the Web search engine for ErZauker".

body() ->
    #container_12 { body=[
        #grid_8 { alpha=true, prefix=2, suffix=2, omega=true, body=inner_body() }
    ]}.

inner_body() -> 
    [
        #h1 { text=title() },
        #p{},
        "
        Search for something and press enter:
        ",
        #textbox{ id=q, postback=do_search},
        #p{},
	#panel { id=search_result, body="SearchResults Here" },
	#p{}
    ].
	
event(click) ->
    wf:replace(button, #panel { 
        body="You clicked the button!", 
        actions=#effect { effect=highlight }
    });

event(do_search)->
    SearchString=wf:q(q),
    ?PRINT({requested, SearchString, now()}),
    Candidates=er_zauker_app:erlist(SearchString),
    %% ?PRINT({result,Candidates}),
    %% Now call grep in the background to filter out candidates
    %% grep -n -C --no-messages  would be great
    %% we cycle on every guy to get more control
    doGrep(Candidates),
    bho.

doGrep(Stuff2Process) ->
    %% ?PRINT({grepping,Stuff2Process}),
    case Stuff2Process of
	[] ->
	    wf:update(search_result,[
		#p { body="Nothing Found" },
		#p { body=io_lib:format("~p", [now()]) }]);
	_FileCandidates->
	    wf:update(search_result,[
		#p { body="Search Results:" },
		#p { body=io_lib:format("~p", [now()]) }])
    end.
