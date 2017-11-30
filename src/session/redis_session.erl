%%%-------------------------------------------------------------------
%%% @author Twinny-KJH
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 10. 11월 2017 오후 4:38
%%%-------------------------------------------------------------------
-module(redis_session).
-author("Twinny-KJH").

-behaviour(gen_server).

%% API
-export([lookup/2,insert/2,delete/2,init_store/1]).


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
  {ok,state}.



init_store(Pool_id)-> gen_server:call(?MODULE,{init,Pool_id}).

lookup(Pool_id,Session)-> gen_server:call(?MODULE,{lookup, Pool_id,Session}).
insert(Pool_id,{Session,User_idx})-> gen_server:call(?MODULE,{insert, Pool_id,{Session,User_idx}}).
delete(Pool_id,Session)-> gen_server:call(?MODULE,{delete, Pool_id,Session}).


%% redis에서 조회
handle_call({lookup, Pool_id,Session}, _From, Data) ->
  %expire time 설정 시*분*초
  Expire_time = 1*30*60,
  Reply = case Data of
            {Pool_id,Pid}->
              eredis:q(Pid,["EXPIRE",Session,Expire_time]),
              eredis:q(Pid,["GET",Session]);
            _->
              {error,jsx:encode([{<<"result">>,<<"not exist pool_id">>}])}
          end,
  {reply, Reply, Data};
%% redis 에 삽입
handle_call({insert, Pool_id,{Session,User_idx}}, _From, Data) ->
  %expire time 설정 시*분*초
  Expire_time = 1*30*60,
  Reply = case Data of
            {Pool_id,Pid}->
              {ok,Result} = eredis:q(Pid,["SET",Session,User_idx]),
              eredis:q(Pid,["EXPIRE",Session,Expire_time]),
              {ok,jsx:encode([{<<"result">>,Result}])};
            _->
              {error,jsx:encode([{<<"result">>,<<"not exist pool_id">>}])}
          end,
  {reply, Reply, Data};
%% redis에서 삭제
handle_call({delete, Pool_id,Session}, _From, Data) ->
  Reply = case Data of
            {Pool_id,Pid} ->
              {ok,Result} = eredis:q(Pid,["DEL",Session]),
              {ok,jsx:encode([{<<"result">>,Result}])};
            _->
              {error,jsx:encode([{<<"result">>,<<"not exist pool_id">>}])}
  end,
  {reply, Reply, Data};
handle_call({init,Pool_id}, _From, Data) ->
  % 기존 redis db에서 제거된 redis process값을 제거함
  NewData = case Data of
              {Pool_id,Data_pid}->
                case process_info(Data_pid) of
                  undefined->
                    {ok,Pid} = eredis:start_link(),
                    eredis:q(Pid,[Pool_id,Pid]),
                    {Pool_id,Pid};
                  _->
                    {Pool_id,Data_pid}
                end;
              {Data_pool_id,Data_pid}->
                eredis:q(Data_pid,["DEL",Data_pool_id]),
                eredis:stop(Data_pid),
                {ok,Pid} = eredis:start_link(),
                eredis:q(Pid,[Pool_id,Pid]),
                {Pool_id,Pid};
              _->
                {ok,Pid} = eredis:start_link(),
                eredis:q(Pid,[Pool_id,Pid]),
                {Pool_id,Pid}
            end,
  {reply, Pool_id, NewData}
.

handle_cast(_Msg, State) ->
  {noreply, State}.

handle_info(_Info, State) ->
  {noreply, State}.

terminate(_Reason, _State) ->
  ok.

code_change(_OldVsn, State, _Extra) ->
  {ok, State}.
