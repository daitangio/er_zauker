-module(simple_try).
-compile(export_all).

-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").
 
%% TEST CODE HERE

-import(eredis, [create_multibulk/1]).


stupid_test()->
    ?assertEqual(1,1).   

 
-endif.


