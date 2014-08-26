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
	#spinner { style="text-align:center;" },
        "
        Search for something and press enter:
        ",
        #textbox{ id=q, postback=do_search},
        #p{},
	#panel { id=search_result, body="SearchResults Here" }
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
    ?PRINT({result,Candidates}),
    %% Now call grep in the background to filter out candidates
    %% grep -n -C --no-messages  would be great
    %% we cycle on every guy to get more control
    doGrep(SearchString,Candidates),
    bho.

doGrep(Query,Stuff2Process) ->
    %% ?PRINT({grepping,Stuff2Process}),
    case Stuff2Process of
	[] ->
	    wf:update(search_result,[
		#p { body="Nothing Found" }]);
	FileCandidates->
	    %% First of all list comprenshion	    
	    Grepped=grepize(Query,FileCandidates,[]),
	    NitrogenRecords=formatHtml(Grepped),
	    wf:update(search_result,[
		#p { body="Record(s) Found:" ++ integer_to_list(string:len(Grepped)) },
		#list{ 
		    numbered=true,
		    body=NitrogenRecords}])
    end.

%% Return a listitem of list/listitems...
formatHtml(ListOfLines) ->
    case ListOfLines of
	[] ->
	    [];
	[ SingleResult | Rest] ->
	    %% Split line providing br
	    ResultLines=[ #listitem { body=X} ||  X <- string:tokens(SingleResult,"\n") ],
	    [ #listitem{ body=[ #list{ numbered=false, body=ResultLines}] } | formatHtml(Rest)]
    end.

%%ListOfBinary:: <<"src/er_zauker_app.erl">>
%% Tip: do a guard to define a different function for less stuff

grepize(Query,ListOfBinary,Acc)->
    case ListOfBinary of
	[] ->
	    ?PRINT({searchresult,Acc}),
	    Acc;
	[ FirstBinary | Rest ] ->
	    FileName=binary_to_list(FirstBinary),
	    FullCmd = "grep -n  -C1 -i --no-messages " ++ Query ++ " " ++ FileName,
	    ?PRINT({grep,FullCmd}),
	    %% string:tokens(os:cmd(FullCmd), "\n")
	    NewAcc= [ "File:"++FileName++"\n" ++ os:cmd(FullCmd) | Acc],
	    grepize(Query,Rest,NewAcc)
    end.
    
%% ---------------------------------------------------------------------------
-spec shell_quote(string()) -> string().
%% @doc Replace all ' by \'
shell_quote(String) -> lists:flatten(lists:map(fun($') -> "\\'"; (C) -> C end, String)).
