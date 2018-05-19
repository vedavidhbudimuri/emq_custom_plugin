%%%-------------------------------------------------------------------
%% @doc emq_custom_plugin public API
%% @end
%%%-------------------------------------------------------------------

-module(emq_custom_plugin_app).

-behaviour(application).

%% Application callbacks
-export([start/2, stop/1]).

%%====================================================================
%% API
%%====================================================================

start(_StartType, _StartArgs) ->
    {ok, Sup} = emq_custom_plugin_sup:start_link(),
    application:ensure_all_started(brod),
    application:ensure_all_started(ekaf),
    emqttd_access_control:register_mod(auth, emq_custom_plugin, []),
    emqttd_access_control:register_mod(acl, emq_custom_plugin, []),
    mod_hook_handler:load(application:get_all_env()),
    {ok, Sup}.

%%--------------------------------------------------------------------
stop(_State) ->
    emqttd_access_control:unregister_mod(auth, emq_custom_plugin),
    emqttd_access_control:unregister_mod(acl, emq_custom_plugin),
    emq_custom_plugin:unload().

%%====================================================================
%% Internal functions
%%====================================================================
