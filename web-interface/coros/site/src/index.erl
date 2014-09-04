%% -*- mode: nitrogen -*-
-module (index).
-compile(export_all).
-include_lib("nitrogen_core/include/wf.hrl").

main() -> #template { file="./site/templates/bare.html" }.

title() -> "Welcome to the COde ZaukeR web Search engine -- COROS".

body() ->
    #container_12 { body=[
        #grid_8 { alpha=true, prefix=2, suffix=2, omega=true, body=inner_body() }
    ]}.

inner_body() -> 
    [
        #spinner { style="text-align:center;" },
        "
        Code Search:
        ",
        #textbox{ id=q, postback=do_search},
        #p{},
	#link { 
	    url="meganoid", text="Download and Index open source project" ,
	    style="text-align:center;"
	},
	  
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
    case string:len(SearchString)<3 of
	true ->
	    wf:update(search_result,[
		#p { body="At least 3 chars" }]);
	false ->
	    %% GG: Enlarged timeout
	    Candidates=er_zauker_app:erlist(SearchString,30000),
	    doGrep(SearchString,Candidates),
	    bho
    end.

doGrep(Query,Stuff2Process) ->
    %% ?PRINT({grepping,Stuff2Process}),
    case Stuff2Process of
	[] ->
	    wf:update(search_result,[
		#p { body="Nothing Found for " ++ Query }]);
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

%% This value DEPENDS on how much can be long a cmd line on your Unix.
%% Increase at your own risc
-define(MAX_GREP_ELEMENTS,360).

%%ListOfBinary:: <<"src/er_zauker_app.erl">>
%% To avoid function_clause error, we also define a generic guy... which split the work down the street
grepize(_Query,[],Acc) ->
    ?PRINT({searchresult_size, length(Acc)}),
    Acc;
grepize(Query,ListOfBinary,Acc) when length(ListOfBinary) =< ?MAX_GREP_ELEMENTS   ->
    FileNameListWithSpace = lists:flatmap(fun(X)->[ binary_to_list(X)++" "] end,ListOfBinary),
    FileNames=lists:flatten(FileNameListWithSpace),    
    FullCmd = "grep -n  -C1 -i --no-messages " ++ Query ++ " " ++ FileNames,
    %% Grep will split result easily via a "--\n" line, so we split it:
    %% Example:
    %% [code/er_zauker>grep -C1 -n  MAX_CONNECTIONS src/*
    %% src/er_zauker_rpool.erl-22-%% or you will start getting errors
    %% src/er_zauker_rpool.erl:23:-define(MAX_CONNECTIONS,1000).
    %% src/er_zauker_rpool.erl-24-
    %% --
    %% src/er_zauker_rpool.erl-50-init([]) ->
    %% src/er_zauker_rpool.erl:51:    State=?MAX_CONNECTIONS,
    %% src/er_zauker_rpool.erl-52-    {ok,State}.    
    BulkResults=os:cmd(FullCmd),
    SplittedGuys=[ re:replace(wf:html_encode(X), Query, "<b>"++Query++"</b>", [caseless, global,{return,list}])   ||  X <- string:tokens(BulkResults,"\n"), X /= "--" ],  
    %% TODO: First line will be in the form of
    %% filename-line-text
    %% so we should be able extract the file name easyl!
    NewAcc=lists:append(SplittedGuys,Acc),
    NewAcc;
grepize(Query,ListOfBinary,Acc) ->
    %% Split The list in bulks...
    %% the first part is very tiny, so we ensutre we enter in above definition ^^^^^^^^^^^^^^
    LSize=?MAX_GREP_ELEMENTS,    
    {Lone,Ltwo} = lists:split(LSize,ListOfBinary),
    ?PRINT({splitting,LSize, remains, length(Ltwo)}),
    %%?PRINT({splitted1, Lone}),
    AccPart1=grepize(Query,Lone,Acc),
    grepize(Query,Ltwo,AccPart1).
    
%% ---------------------------------------------------------------------------
-spec shell_quote(string()) -> string().
%% @doc Replace all ' by \'
shell_quote(String) -> lists:flatten(lists:map(fun($') -> "\\'"; (C) -> C end, String)).
