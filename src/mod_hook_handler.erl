-module(mod_hook_handler).
-include_lib("emqttd/include/emqttd.hrl").

-export([load/1, unload/0]).
-export([on_client_connected/3, on_client_disconnected/3]).
-export([on_client_subscribe/4, on_client_unsubscribe/4]).
-export([on_session_created/3, on_session_subscribed/4, on_session_unsubscribed/4, on_session_terminated/4]).
-export([on_message_publish/2, on_message_delivered/4, on_message_acked/4]).

load(Env) ->
  ekaf_init(),
  % emqttd:hook('client.connected', fun ?MODULE:on_client_connected/3, [Env]),
  % emqttd:hook('client.disconnected', fun ?MODULE:on_client_disconnected/3, [Env]),
  % emqttd:hook('client.subscribe', fun ?MODULE:on_client_subscribe/4, [Env]),
  % emqttd:hook('client.unsubscribe', fun ?MODULE:on_client_unsubscribe/4, [Env]),
  % emqttd:hook('session.created', fun ?MODULE:on_session_created/3, [Env]),
  % emqttd:hook('session.subscribed', fun ?MODULE:on_session_subscribed/4, [Env]),
  % emqttd:hook('session.unsubscribed', fun ?MODULE:on_session_unsubscribed/4, [Env]),
  % emqttd:hook('session.terminated', fun ?MODULE:on_session_terminated/4, [Env]),
  emqttd:hook('message.publish', fun ?MODULE:on_message_publish/2, [Env]).
  % emqttd:hook('message.delivered', fun ?MODULE:on_message_delivered/4, [Env]),
  % emqttd:hook('message.acked', fun ?MODULE:on_message_acked/4, [Env]).

on_client_connected(ConnAck, Client = #mqtt_client{client_id = ClientId}, _Env) ->
  io:format("client ~s connected, connack: ~w~n", [ClientId, ConnAck]),
  
  Topic = <<"test">>,

  Json = mochijson2:encode([
      {type, <<"connected">>},
      {client_id, ClientId},
      {cluster_node, node()},
      {ts, emqttd_time:now_secs()}
  ]),    
  ekaf:produce_async_batched(Topic, list_to_binary(Json)),
  io:format("Pushed data using ekaf\n"),
   
  emit_to_kafka_using_brod(Json),
  {ok, Client}.

on_client_disconnected(Reason, _Client = #mqtt_client{client_id = ClientId}, _Env) ->
  ok.

on_client_subscribe(ClientId, Username, TopicTable, _Env) ->
  {ok, TopicTable}.

on_client_unsubscribe(ClientId, Username, TopicTable, _Env) ->
  {ok, TopicTable}.

on_session_created(ClientId, Username, _Env) ->
  ok.

on_session_subscribed(ClientId, Username, {Topic, Opts}, _Env) ->
  {ok, {Topic, Opts}}.

on_session_unsubscribed(ClientId, Username, {Topic, Opts}, _Env) ->
  ok.

on_session_terminated(ClientId, Username, Reason, _Env) ->
  ok.

on_message_publish(Message = #mqtt_message{topic = <<"$SYS/", _/binary>>}, _Env) ->
  {ok, Message};

on_message_publish(Message, _Env) ->
  io:format("publish ~s~n", [emqttd_message:format(Message)]),   

    From = element(1, Message#mqtt_message.from),
    Topic = Message#mqtt_message.topic,
    Payload = Message#mqtt_message.payload, 
    QoS = Message#mqtt_message.qos,
    Timestamp = Message#mqtt_message.timestamp,

    Json = mochijson2:encode([
          {type, <<"published">>},
          {client_id, From},
          {topic, Topic},
          {payload, Payload},
          {qos, QoS},
          {cluster_node, node()},
          {ts, emqttd_time:now_secs(Timestamp)}
  ]),
  emit_to_kafka_using_brod(Json),
  {ok, Message}.

on_message_delivered(ClientId, Username, Message, _Env) ->
  {ok, Message}.

on_message_acked(ClientId, Username, Message, _Env) ->
  {ok, Message}.

unload() ->
  emqttd:unhook('client.connected', fun ?MODULE:on_client_connected/3),
  emqttd:unhook('client.disconnected', fun ?MODULE:on_client_disconnected/3),
  emqttd:unhook('client.subscribe', fun ?MODULE:on_client_subscribe/4),
  emqttd:unhook('client.unsubscribe', fun ?MODULE:on_client_unsubscribe/4),
  emqttd:unhook('session.subscribed', fun ?MODULE:on_session_subscribed/4),
  emqttd:unhook('session.unsubscribed', fun ?MODULE:on_session_unsubscribed/4),
  emqttd:unhook('message.publish', fun ?MODULE:on_message_publish/2),
  emqttd:unhook('message.delivered', fun ?MODULE:on_message_delivered/4),
emqttd:unhook('message.acked', fun ?MODULE:on_message_acked/4).


emit_to_kafka_using_brod(Json) ->
  Topic = <<"test">>,
  Partition = 0,
  KafkaBootstrapEndpoints = [{"localhost", 9092}],

  ok = brod:start_client(KafkaBootstrapEndpoints, client1),
  ok = brod:start_producer(client1, Topic, _ProducerConfig = []),
  brod:produce_sync(client1, Topic, Partition, <<"key1">>, list_to_binary(Json)),
  io:format("Pushed data to usong brod to kafka\n").


ekaf_init(_Env) ->
    %% Get parameters
    {ok, Kafka} = application:get_env(emqttd_plugin_kafka_bridge, kafka),
    BootstrapBroker = proplists:get_value(bootstrap_broker, Kafka),
    PartitionStrategy = proplists:get_value(partition_strategy, Kafka),
    Topic = proplists:get_value(topic, Kafka),
    %% Set partition strategy, like application:set_env(ekaf, ekaf_partition_strategy, strict_round_robin),
    application:set_env(ekaf, ekaf_partition_strategy, PartitionStrategy),
    %% Set broker url and port, like application:set_env(ekaf, ekaf_bootstrap_broker, {"127.0.0.1", 9092}),
    application:set_env(ekaf, ekaf_bootstrap_broker, BootstrapBroker),
    %% Set topic
    application:set_env(ekaf, ekaf_bootstrap_topics, Topic),

    {ok, _} = application:ensure_all_started(kafkamocker),
    {ok, _} = application:ensure_all_started(gproc),
    {ok, _} = application:ensure_all_started(ranch),
    {ok, _} = application:ensure_all_started(ekaf),

    io:format("Init ekaf with ~p~n", [BootstrapBroker]).
