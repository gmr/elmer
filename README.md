# Elmer
Work in progress toolset for granular monitoring of RabbitMQ Queues using Queue attributes and the RabbitMQ Monitoring plugin with support for Nagios.

## Elmer Erlang Functions

### get_monitoring_status/2

Gets the monitoring status for the specified queue

_Parameters_:

 - Virtual host
 - Queue name

_Returns_:

 - Setup (bool)
 - Enabled (bool)
 - Warning threshold (short)
 - Alert theshold (short)
 
 or

 - error
 - Error message

### setup_monitoring/4

Add the monitoring records to the specified queue.

_Parameters_:

 - Virtual host
 - Queue name
 - Queue depth quantity for a warning
 - Queue depth quantity for an alert

_Returns_:

 - Result (ok, error)
 - Attribute tuple list for the queue or error message

### remove_monitoring/2

Remove the monitoring records to the specified queue.

_Parameters_:

 - Virtual host
 - Queue name

_Returns_:

 - Result (ok, error)
 - Remaining attribute tuple list for the queue or error message

### toggle_monitoring/2

Turns monitoring off and on for the specified queue

_Parameters_:

 - Virtual host
 - Queue name

_Returns_:

 - Result (ok, error)
 - Value (true,false,error message)

### change_monitoring_thresholds/4

Change the monitoring thresholds for the specified queue

_Parameters_:

 - Virtual host
 - Queue name
 - Queue depth quantity for a warning
 - Queue depth quantity for an alert

_Returns_:

 - Result (ok, error)
 - Attribute tuple list for the queue or error message

## Example use in erl

  erl -sname elmer -remsh rabbit@gmr-0x09
  Erlang R14B02 (erts-5.8.3) [source] [64-bit] [smp:2:2] [rq:2] [async-threads:0] [hipe] [kernel-poll:false]
  Eshell V5.8.3  (abort with ^G)
  (rabbit@gmr-0x09)1> cd("/Users/gmr/Source/elmer/").
  /Users/gmr/Dropbox/Source/elmer
  ok
  (rabbit@gmr-0x09)2> elmer:setup_monitoring(<<"/">>, <<"test">>, 1000, 2500).
  {ok,[{<<"x-monitor">>,bit,true},
       {<<"x-warn">>,short,1000},
       {<<"x-alert">>,short,2500}]}
  (rabbit@gmr-0x09)3> elmer:toggle_monitoring(<<"/">>, <<"test">>).
  {ok,false}
  (rabbit@gmr-0x09)4> elmer:toggle_monitoring(<<"/">>, <<"test">>).
  {ok,true}
  (rabbit@gmr-0x09)5> elmer:remove_monitoring(<<"/">>, <<"test">>).
  {ok,[]}
