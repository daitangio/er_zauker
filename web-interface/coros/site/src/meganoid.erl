%% -*- mode: nitrogen -*-
-module (meganoid).
-compile(export_all).
-include_lib("nitrogen_core/include/wf.hrl").

main() -> #template { file="./site/templates/bare.html" }.

title() -> " Humble Meganoids Open source Indexer".

body() ->
    #container_12 { body=[
        #grid_8 { alpha=true, prefix=2, suffix=2, omega=true, body=inner_body() }
    ]}.

inner_body() -> 
    [
	#spinner { style="text-align:center;" },
        "
        The Open source indexer will download a git repository and then index it via its slave meganiods.
        You will be delighted by our service.
        Try url like https://github.com/spring-projects/spring-framework. 
        ",
        #p{
	   body="Note: we will extract a very tiny history to avoid fillup your disk."
	  },
        #textbox{ id=q, postback=do_search, text="https://github.com/github/hubot", size=70 },
        #p{},
	#panel { id=index_result, body="" }
    ].
	
event(click) ->
    wf:replace(button, #panel { 
        body="You clicked the button!", 
        actions=#effect { effect=highlight }
    });

event(do_search)->
    SearchString=wf:q(q),
    ?PRINT({requested, SearchString, now()}),
    GitRepoName=lists:last(string:tokens(SearchString,"/")),
    {ok,Cwd}=file:get_cwd(),
    %% Point to er_zauker/web-interface/coros/repos
    FullPath=Cwd++"/repos/"++GitRepoName,    
    wf:update(index_result,[ "Extracting git repository into " ++ FullPath ]),
    %% TODO Extract dir name and ensure does not yet exist
    RemoveResult=os:cmd( "rm -r " ++ FullPath),
    ?PRINT({remove_result,RemoveResult}),
    %% git clone --depth 2 git://github.com/github/hubot
    CloneCommand="git clone --depth 1 "++ SearchString ++ " " ++ FullPath,
    GitResult=os:cmd(CloneCommand ),
    ?PRINT({git_output,GitResult}),
    wf:insert_bottom(index_result, [ #br{},#p{},"Cloned via "++ CloneCommand ]),
    er_zauker_indexer!{self(),directory, FullPath },
    wf:insert_bottom(index_result, [ #br{},"Asking Lord Zauker to process our humble request..." ]),
    %% Ask zauker some info... but give it some time to start
    timer:sleep(150),
    er_zauker_indexer!{self(),report},
    receive
	{worker, RunningGuys, files_processed, TotalFilesDone} ->
	    Msg="Indexing Files:" ++integer_to_list(RunningGuys)++ " Files Processed so far:" ++ integer_to_list(TotalFilesDone);
        _ -> 
	    Msg="Unknown status"
    after 250 ->
	    Msg="Timeout (Lord Zauker very busy?)"
    end,    
    wf:insert_bottom(index_result,[ #br{}, Msg,#hr{} ]),
    %% TODO: Ask Zauker to index and then monitor it
    ok.
