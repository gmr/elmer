-module(rqae).
-export([toggle_monitoring/2]).
-include("queue.hrl").
  
get_new_bool_value(<<"True">>) ->
  <<"False">>;
  
get_new_bool_value(_) ->
  <<"True">>.
  
update_tuple_value({<<"x-monitor">>, DataType, Value}) ->
  {<<"x-monitor">>, DataType, get_new_bool_value(Value)};
  
update_tuple_value({Name, DataType, Value}) ->
  {Name, DataType, Value}.

toggle_monitoring(VirtualHost, Queue) ->
  F = fun() ->
    io:format("Running query~n"),
    [A] = mnesia:read(rabbit_queue, {resource,VirtualHost,queue,Queue}, write),
    io:format("Queue: ~s~n", [element(4, A#amqqueue.queue)]),
    Attributes = [update_tuple_value(Attrib) || Attrib <- A#amqqueue.attributes],
    New = A#amqqueue{attributes = Attributes},
    mnesia:write(rabbit_queue, New, write),
    mnesia:write(rabbit_durable_queue, New, write)
  end,
  {_, Response} = mnesia:transaction(F),
  Response.