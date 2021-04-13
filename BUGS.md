# EXEC Timeout bug 
April 2021
To fix Redis EXEC timeout we upgraded eredis library and then increased EXEC timeouts.

After about 580 seconds some timeouts occur anyway, perphaps the exec transaction is too wide.


Error:

    !!! Just down: {'DOWN',#Ref<0.3973127184.825229314.238899>,process,
                    <0.1978.0>,
                    {timeout,
                        {gen_server,call,
                            [<0.1979.0>,
                                {request,
                                    [[<<"*">>,"1",<<"\r\n">>],
                                    [[<<"$">>,"4",<<"\r\n">>,<<"EXEC">>,
                                    <<"\r\n">>]]]},
                                5000]}}}
    [256]s Workers[717]  Files processed:70 Files/sec: 0.2734375 


Seems independent from the numer of REDIS connections
