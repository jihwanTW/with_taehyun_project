%%%-------------------------------------------------------------------
%%% @author Twinny-KJH
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 29. 11월 2017 오후 4:21
%%%-------------------------------------------------------------------
-module(with_taehyun_project_app).
-author("Twinny-KJH").

-behaviour(application).

%% Application callbacks
-export([start/2,
  stop/1]).

%%%===================================================================
%%% Application callbacks
%%%===================================================================

%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called whenever an application is started using
%% application:start/[1,2], and should start the processes of the
%% application. If the application is structured according to the OTP
%% design principles as a supervision tree, this means starting the
%% top supervisor of the tree.
%%
%% @end
%%--------------------------------------------------------------------
-spec(start(StartType :: normal | {takeover, node()} | {failover, node()},
    StartArgs :: term()) ->
  {ok, pid()} |
  {ok, pid(), State :: term()} |
  {error, Reason :: term()}).
start(_StartType, _StartArgs) ->
  %cowboy 로딩
  ok = application:start(crypto),
  ok = application:start(cowlib),
  ok = application:start(ranch),
  ok = application:start(cowboy),
  %emysql 로딩
  crypto:start(),
  application:start(emysql),
  %emysql DB pool 생성
  emysql:add_pool(
    db,
    [{size,1},
      {user,"root"},
      {password,"jhkim1020"},
      {database,"with_taehyun_project"},
      {encoding,utf8}
    ]),
  % redis query server 시작
  redis_query_server:start_link(),
  % session server 시작
  session_server:start_link(redis_session,session),
  % redis_session server 시작
  redis_session:start_link(),
  % connect to emqttd server
  mqtt_connect_server:start_link(),

  % cowboy router 설정
  Dispatch = cowboy_router:compile([
    {'_',[
      {"/:version/[:category/[:name]]",http,[]}
    ]}
  ]),
  {Result_code,Value} =cowboy:start_http(
    http,
    100,
    [{port,6070}],
    [{env,[{dispatch,Dispatch}]}]
  ),
  io:format("~p ~p ~n",[Result_code,Value]),
  %% reloader 실행
  reloader:start(),


%%  Dispatch2 = cowboy_router:compile([
%%    {'_', [
%%      {"/:version/[:category/[:name]]", toppage_handler, []}
%%    ]}
%%  ]),
%%  {ok, _} = cowboy:start_tls(https, [
%%    {port, 6443},
%%    {cacertfile,  "../ssl/cowboy-ca.crt"},
%%    {certfile,  "../ssl/server.crt"},
%%    {keyfile,  "../ssl/server.key"}
%%  ], #{env => #{dispatch => Dispatch2}}),

  case 'with_taehyun_project_sup':start_link() of
    {ok, Pid} ->
      {ok, Pid};
    Error ->
      Error
  end.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called whenever an application has stopped. It
%% is intended to be the opposite of Module:start/2 and should do
%% any necessary cleaning up. The return value is ignored.
%%
%% @end
%%--------------------------------------------------------------------
-spec(stop(State :: term()) -> term()).
stop(_State) ->
  ok.

%%%===================================================================
%%% Internal functions
%%%===================================================================
