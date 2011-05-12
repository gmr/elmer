%% elmer erlang support functions

-module(elmer).
-export([setup_monitoring/4,remove_monitoring/2,toggle_monitoring/2]).
-include("queue.hrl").

%% Removes all monitoring related attributes
%% Returns a tuple of result, Remaining attributes/Error message
remove_monitoring(VirtualHost, Queue) ->
  {Response, Record} = rabbit_amqqueue:lookup({resource, VirtualHost, queue, Queue}),
  case Response of
    ok ->
      case get_x_monitor_value(Record#amqqueue.attributes) of
        error -> {error, "Monitoring not setup."};
        _ ->
          Attributes = lists:filter(fun filter_monitoring_tuples/1, Record#amqqueue.attributes),
          New = Record#amqqueue{attributes = Attributes},
          {write_record(New), Attributes}
      end;
    error -> {error, "Queue not found."}
  end.

%% Turns on monitoring for a queue
%% Returns a tuple of result, Value/Error message
setup_monitoring(VirtualHost, Queue, WarnQty, AlertQty) ->
  {Response, Record} = rabbit_amqqueue:lookup({resource, VirtualHost, queue, Queue}),
  case Response of
    ok ->
      case get_x_monitor_value(Record#amqqueue.attributes) of
        true -> {error, "Monitoring already setup."};
        false -> {error, "Monitoring already setup."};
        error ->
          Attributes = [{<<"x-monitor">>, bit, true},
                        {<<"x-warn">>, short, WarnQty},
                        {<<"x-alert">>, short, AlertQty}] ++ Record#amqqueue.attributes,
          New = Record#amqqueue{attributes = Attributes},
          {write_record(New), Attributes}
      end;
    error -> {error, "Queue not found."}
  end.

%% Toggles the boolean value of the x-monitor record. 
%% Returns a tuple of result, Value/Error message
toggle_monitoring(VirtualHost, Queue) ->
  {Response, Record} = rabbit_amqqueue:lookup({resource, VirtualHost, queue, Queue}),
  case Response of
    ok ->
      case get_x_monitor_value(Record#amqqueue.attributes) of
        error -> {error, "Monitoring not setup."};
        _ ->
          Attributes = [toggle_x_monitor_value(Attrib) || Attrib <- Record#amqqueue.attributes],
          New = Record#amqqueue{attributes = Attributes},
          {write_record(New), get_x_monitor_value(Attributes)}
      end;
    error -> {error, "Queue not found."}
  end.

%% -----------------
%% Support functions
%% -----------------

%% Writes a amqqueue record to mnesia in both ram and disk so the rabbitmq processes
%% get the info needed to see the update live
write_record(Record) ->
  F = fun() ->
    mnesia:write(rabbit_queue, Record, write),
    mnesia:write(rabbit_durable_queue, Record, write)
  end,
  {_, Response} = mnesia:transaction(F),
  Response.

%% x-monitor specific functions
get_x_monitor_value(Attributes) ->
  Record = lists:filter(fun(R) -> element(1, R) =:= <<"x-monitor">> end, Attributes),
  case Record of 
    [] ->
      Value = error;
    [{<<"x-monitor">>, _, _}] ->
      [{_, _, Value}] = Record
    end,
  Value.
  
%% Toggles the x-monitor attribute tuple's value
toggle_x_monitor_value({<<"x-monitor">>, DataType, Value}) ->
  {<<"x-monitor">>, DataType, get_new_bool_value(Value)};

toggle_x_monitor_value({Name, DataType, Value}) ->
  {Name, DataType, Value}.
  
%% flip the boolean value
get_new_bool_value(true) ->
  false;
  
get_new_bool_value(_) ->
  true.

%% Only return attributes that are not related to monitoring
filter_monitoring_tuples(Record) ->
  case element(1, Record) of
    <<"x-monitor">> -> false;
    <<"x-warn">> -> false;
    <<"x-alert">> -> false;
    _ -> true
  end.
