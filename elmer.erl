%% elmer erlang support functions

-module(elmer).
-export([get_monitoring_status/2, setup_monitoring/4, remove_monitoring/2, 
         toggle_monitoring/2, change_monitoring_thresholds/4]).
-include("queue.hrl").

%% Get the status of a queue's monitorng setup
%% Returns a tuple of setup (bool), enabled (bool), warning threshold, alert threshold
get_monitoring_status(VirtualHost, Queue) ->
  {Response, Record} = rabbit_amqqueue:lookup({resource, VirtualHost, queue, Queue}),
  case Response of
    ok ->
      Monitor = get_tuple_value(Record#amqqueue.attributes, <<"x-monitor">>),
      case Monitor of
        error -> {false, false, -1, -1};
        _ -> {true , 
              get_tuple_value(Record#amqqueue.attributes, <<"x-monitor">>),
              get_tuple_value(Record#amqqueue.attributes, <<"x-warn">>),
              get_tuple_value(Record#amqqueue.attributes, <<"x-alert">>)}
      end;
    error -> {error, "Queue not found."}
  end.

%% Turns on monitoring for a queue
%% Returns a tuple of result, Value/Error message
setup_monitoring(VirtualHost, Queue, WarnQty, AlertQty) ->
  {Response, Record} = rabbit_amqqueue:lookup({resource, VirtualHost, queue, Queue}),
  case Response of
    ok ->
      case get_tuple_value(Record#amqqueue.attributes, <<"x-monitor">>) of
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
      case get_tuple_value(Record#amqqueue.attributes, <<"x-monitor">>) of
        error -> {error, "Monitoring not setup."};
        _ ->
          Attributes = [toggle_x_monitor_value(Attrib) || Attrib <- Record#amqqueue.attributes],
          New = Record#amqqueue{attributes = Attributes},
          {write_record(New), get_tuple_value(Attributes, <<"x-monitor">>)}
      end;
    error -> {error, "Queue not found."}
  end.

%% Update monitoring thresholds
%% Returns a tuple of result, Value/Error message
change_monitoring_thresholds(VirtualHost, Queue, WarnQty, AlertQty) ->
  {Response, Record} = rabbit_amqqueue:lookup({resource, VirtualHost, queue, Queue}),
  case Response of
    ok ->
      case get_tuple_value(Record#amqqueue.attributes, <<"x-monitor">>) of
        error -> {error, "Monitoring not setup."};
        _ ->
          Attributes = [update_warn_or_alert_value(Attrib, WarnQty, AlertQty) || Attrib <- Record#amqqueue.attributes],
          New = Record#amqqueue{attributes = Attributes},
          {write_record(New), Attributes}
      end;
    error -> {error, "Queue not found."}
  end.

%% Removes all monitoring related attributes
%% Returns a tuple of result, Remaining attributes/Error message
remove_monitoring(VirtualHost, Queue) ->
  {Response, Record} = rabbit_amqqueue:lookup({resource, VirtualHost, queue, Queue}),
  case Response of
    ok ->
      case get_tuple_value(Record#amqqueue.attributes, <<"x-monitor">>) of
        error -> {error, "Monitoring not setup."};
        _ ->
          Attributes = lists:filter(fun filter_monitoring_tuples/1, Record#amqqueue.attributes),
          New = Record#amqqueue{attributes = Attributes},
          {write_record(New), Attributes}
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

%% Get the value for a specified attribute tuple  
get_tuple_value(Attributes, Field) ->
  Record = lists:filter(fun(R) -> element(1, R) =:= Field end, Attributes),
  case Record of 
    [] ->
      Value = error;
    [{Field, _, _}] ->
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

% Takes a tuple and updates the value for x-warn and x-alert
update_warn_or_alert_value(Record, WarnQty, AlertQty) ->
  case element(1, Record) of
    <<"x-warn">> -> 
      {<<"x-warn">>, element(2, Record), WarnQty};
    <<"x-alert">> -> 
      {<<"x-alert">>, element(2, Record), AlertQty};
    _ ->
      Record
  end.
