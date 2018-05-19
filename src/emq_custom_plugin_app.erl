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
    emq_custom_plugin_sup:start_link(),
    emqttd_access_control:register_mod(auth, emq_custom_plugin, []),
    emqttd_access_control:register_mod(acl, emq_custom_plugin, []),
    mod_hook_handler:load(application:get_all_env()).

%%--------------------------------------------------------------------
stop(_State) ->
    emqttd_access_control:unregister_mod(auth, emq_auth_demo),
    emqttd_access_control:unregister_mod(acl, emq_acl_demo),
    emq_custom_plugin:unload(),
    ok.

%%====================================================================
%% Internal functions
%%====================================================================
