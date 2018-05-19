PROJECT = emq_custom_plugin
PROJECT_DESCRIPTION = EMQ Custom Plugin
PROJECT_VERSION = 1.0

BUILD_DEPS = emqttd
dep_emqttd = git https://github.com/emqtt/emqttd master

COVER = true

include erlang.mk

app:: rebar.config

