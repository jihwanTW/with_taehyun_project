%%%-------------------------------------------------------------------
%%% @author Twinny-KJH
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 15. 11월 2017 오후 4:12
%%%-------------------------------------------------------------------
-module(redis_query_server).
-author("Twinny-KJH").

-behaviour(gen_server).

%% API
-export([get_user/1,insert/1,login/1,update/1,delete/1]).

-export([start_link/0]).

%% gen_server callbacks
-export([init/1,
  handle_call/3,
  handle_cast/2,
  handle_info/2,
  terminate/2,
  code_change/3]).

-record(state, {}).

start_link() ->
  gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

init([]) ->
  {Result,Pid} = eredis:start_link(),
  eredis:q(Pid,["SELECT","1"]),
  {Result,Pid}.


get_user(User_idx)->gen_server:call(?MODULE,{get_user,User_idx}).
delete(User_idx)->gen_server:call(?MODULE,{delete,User_idx}).
insert(Mysql_result)->gen_server:call(?MODULE,{insert,Mysql_result}).
login(Mysql_result)->gen_server:call(?MODULE,{login,Mysql_result}).
update({User_idx,Email,Nickname})->gen_server:call(?MODULE,{update,{User_idx,Email,Nickname}}).


%% 유저조회
handle_call({get_user,User_idx}, _From, State) ->
  eredis:q(State,["EXPIRE",User_idx,1*30*60]),
  Reply = case eredis:q(State,["HGETALL",User_idx]) of
    {ok,[]}->
      {ok,undefined};
    {ok,Values}->
      {ok,Values}
  end,
  {reply, Reply, State};
%% redis에 저장되지 않은 유저를 조회할경우 저장
handle_call({insert,Mysql_result}, _From, State) ->
  User_idx = proplists:get_value(<<"idx">>,Mysql_result),
  Mysql_keys = proplists:get_keys(Mysql_result),
  Insert2redis = fun(Key)->
    eredis:q(State,["HSET",User_idx,Key,proplists:get_value(Key,Mysql_result)])
                 end,
  lists:map(Insert2redis,Mysql_keys),
  eredis:q(State,["EXPIRE",User_idx,1*30*60]),
  Reply = {ok,'_'},
  {reply, Reply, State};
%% 로그인할경우 redis에 저장
handle_call({login,Mysql_result}, _From, State) ->
  User_idx = proplists:get_value(<<"idx">>,Mysql_result),
  Mysql_keys = proplists:get_keys(Mysql_result),
  Insert2redis = fun(Key)->
    eredis:q(State,["HSET",User_idx,Key,proplists:get_value(Key,Mysql_result)])
                 end,
  lists:map(Insert2redis,Mysql_keys),
  eredis:q(State,["EXPIRE",User_idx,1*30*60]),
  {reply, ignored, State};
handle_call({delete,User_idx}, _From, State) ->
  eredis:q(State,["HDEL",User_idx]),
  {reply, ignored, State};
handle_call({update,{User_idx,Email,Nickname}}, _From, State) ->
  eredis:q(State,["HDEL",User_idx,email,nickname]),
  eredis:q(State,["HSET",User_idx,email,Email]),
  eredis:q(State,["HSET",User_idx,nickname,Nickname]),
  {reply, ignored, State}
.


handle_cast(_Msg, State) ->
  {noreply, State}.

handle_info(_Info, State) ->
  {noreply, State}.

terminate(_Reason, _State) ->
  ok.

code_change(_OldVsn, State, _Extra) ->
  {ok, State}.

%% Internal functions