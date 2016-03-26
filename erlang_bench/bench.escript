#! /usr/bin/env escript

%%! -pa _build/default/lib/teacup/ebin -pa _build/default/lib/teacup_nats/ebin -pa _build/default/lib/simpre/ebin pa _build/default/lib/nats_msg/ebin -pa _build/default/lib/jsx/ebin

-mode(compile).

main([]) ->
    Host = <<"127.0.0.1">>,
    Port = 4222,
    MsgCount = 1000000,
    Subject =  <<"0123456789012345">>,
    Payload = <<"0123456789012345012345678901234501234567890123450123456789012345">>,
    application:start(teacup),
    prepare_bench(Host, Port, MsgCount, Subject, Payload),
    application:stop(teacup).
   
prepare_bench(Host, Port, MsgCount, Subject, Payload) ->
    {Pub, Sub} = create_conns(Host, Port),
    F = fun() ->
        bench(Pub, Sub, MsgCount, Subject, Payload)
    end,
    {Time, ok} = timer:tc(F),
     MsgsPerSec = round(MsgCount / (Time / 1000000)),
     io:format("~p ~p ~p~n", [MsgCount, Time, MsgsPerSec]).
    
create_conns(Host, Port) ->
    {ok, Sub} = teacup_nats@sync:connect(Host, Port), 
    {ok, Pub} = teacup_nats:connect(Host, Port),
    loop_conn_ready(Pub),
    {Pub, Sub}.

bench(Pub, Sub, MsgCount, Subject, Payload) ->
    Me = self(),
    F = fun() ->
        teacup_nats@sync:sub(Sub, Subject),
        sub_loop(Sub, MsgCount),
        Me ! done
    end,
    spawn(F),
    spawn(fun() -> publish(Pub, Subject, Payload, MsgCount) end),
    receive 
        done -> ok
    end.

loop_conn_ready(Conn) ->
    receive
        {Conn, ready} -> ok
    after 1000 ->
        throw(conn_not_ready)     
    end.

publish(_, _, _, 0) ->
    ok;
    
publish(Pub, Subject, Payload, Left) ->
    teacup_nats:pub(Pub, Subject, #{payload => Payload}),
    publish(Pub, Subject, Payload, Left - 1).

sub_loop(_Sub, 0) ->
    ok;
    
sub_loop(Sub, Left) ->
    receive
        {Sub, {msg, _Subject, _ReplyTo, _Payload}} ->
            sub_loop(Sub, Left - 1);
        _Other ->
            sub_loop(Sub, Left)
    end.
