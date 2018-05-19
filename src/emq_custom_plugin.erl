
-behaviour(emqttd_auth_mod).

-include_lib("emqttd/include/emqttd.hrl").
-include_lib("emqttd/include/emqttd_cli.hrl").

-export([
   init/1,
   check/3,
   check_acl/2,
   reload_acl/1,
   description/0
]).

init(Opts)->
   {ok, Opts}.


// Authentication function
check(#mqtt_client{client_id = ClientId, username = Username}, Password, _Opts) ->
  ok.


// Authorization
check_acl({Client, PubSub, Topic}, Opts) ->
  allow.


// Reloading authorization
reload_acl(_Opts) ->
  ok.


// To provide module description
description() ->
  "EMQ Custom Plugin".



