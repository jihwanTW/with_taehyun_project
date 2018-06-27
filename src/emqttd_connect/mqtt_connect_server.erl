%%%-------------------------------------------------------------------
%%% @author Twinny-KJH
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 26. 12월 2017 오후 12:15
%%%-------------------------------------------------------------------
-module(mqtt_connect_server).
-author("Twinny-KJH").

-behaviour(gen_server).

%% API
-export([publish_to_mqtt/1]).

-export([start_link/0]).

%% gen_server callbacks
-export([init/1,
  handle_call/3,
  handle_cast/2,
  handle_info/2,
  terminate/2,
  code_change/3]).

-record(state, {mqttc,seq}).

-define(MQTTC,emqttc).

start_link() ->
  gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

init([]) ->
  {ok,Pid} = connect_mqtt([
    {host, "localhost"},
    {client_id, <<"server">>},
    {username,<<"server_admin_jihwan">>},
    {password,<<"pw1234">>},
    {logger, {error_logger, warning}},
    {reconnect, 4}
  ]),
  {ok, #state{mqttc = Pid, seq = 1}}.

handle_call({publish,[Topic,Payload]}, _From,  State = #state{mqttc = Pid}) ->
  publish(Pid,Topic,Payload),
  {reply, ignored, State};
handle_call({publish,[Topic,Payload,Qos]}, _From,  State = #state{mqttc = Pid}) ->
  publish(Pid,Topic,Payload,Qos),
  {reply, ignored, State};
handle_call(_Request, _From, State) ->
  {reply, ignored, State}.

handle_cast(_Msg, State) ->
  {noreply, State}.

%% Receive Publish Message from TopicA...
handle_info({publish, Topic, Payload}, State) ->
  io:format("Message from ~s: ~p~n", [Topic, Payload]),
  {noreply, State};

%% Client connected
handle_info({mqttc, Pid, connected}, State = #state{mqttc = Pid}) ->
  io:format("Client ~p is connected~n", [Pid]),
  %?MQTTC:subscribe(Pid, <<"TopicA">>, 1),
  %?MQTTC:subscribe(Pid, <<"TopicB">>, 2),
  self() ! publish,
  {noreply, State};

%% Client disconnected
handle_info({mqttc, Pid,  disconnected}, State = #state{mqttc = Pid}) ->
  io:format("Client ~p is disconnected~n", [Pid]),
  {noreply, State};

handle_info(_Info, State) ->
  {noreply, State}.

terminate(_Reason, _State) ->
  ok.

code_change(_OldVsn, State, _Extra) ->
  {ok, State}.



publish_to_mqtt(Args)-> gen_server:call(?MODULE,{publish,Args}).

connect_mqtt(Args)->
  ?MQTTC:start_link(Args)
  .

subscribe(Pid,Topic,Payload)->
  ?MQTTC:subscribe(Pid,Topic,Payload)
.

%% publish(Client, Topic, Payload)
publish(Pid,Topic,Payload)->
  ?MQTTC:publish(Pid,Topic,Payload)
.
%% publish(Client, Topic, Payload, Qos)
publish(Pid,Topic,Payload,Qos)->
  ?MQTTC:publish(Pid,Topic,Payload,Qos)
.