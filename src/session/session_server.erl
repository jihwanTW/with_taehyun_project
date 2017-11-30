%%%-------------------------------------------------------------------
%%% @author Twinny-KJH
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 02. 11월 2017 오후 6:12
%%%-------------------------------------------------------------------
-module(session_server).
-author("Twinny-KJH").

%% API

-behaviour(gen_server).

%% API
-export([lookup/1,insert/1,delete/1]).


-export([start_link/2]).

%% gen_server callbacks
-export([init/1,
  handle_call/3,
  handle_cast/2,
  handle_info/2,
  terminate/2,
  code_change/3]).

-record(state, {}).

start_link(Mod,Pool_id) ->
  gen_server:start_link({local, ?MODULE}, ?MODULE, [Mod,Pool_id], []).


lookup(Session)-> gen_server:call(?MODULE,{lookup,Session}).

insert({User_idx,User_id}) -> gen_server:call(?MODULE,{insert,{User_idx,User_id}}).

delete(Session)->gen_server:call(?MODULE,{delete,Session}).





init([Mod,Pool_id]) ->
  Mod:start_link(),
  Mod_id = Mod:init_store(Pool_id),
  {ok, {Mod,Mod_id}}.


%% 조회
handle_call({lookup,Session}, _From, State) ->
  {Mod,Mod_id} = State,
  Reply = Mod:lookup(Mod_id ,Session),
  {reply,Reply, State};
%% 세션 인서트
handle_call({insert,{User_idx,User_id}},_From, State)->
  {Mod,Mod_id} = State,
  % generate session
  Session = generate_session(User_id),
  % session insert to db
  Mod:insert(Mod_id,{Session,User_idx}),

  Reply = {ok,Session},
  {reply,Reply, State};
%% 세션삭제
handle_call({delete,Session},_From,State)->
  {Mod,Mod_id} = State,
  Reply = Mod:delete(Mod_id,Session),
  {reply,Reply, State}
.

handle_cast(_Msg, State) ->
  {noreply, State}.

handle_info(_Info, State) ->
  {noreply, State}.

terminate(_Reason, _State) ->
  ok.

code_change(_OldVsn, State, _Extra) ->
  {ok, State}.


generate_session(User_id)->
  random:seed(now()),
  Num = random:uniform(10000),
  Hash=erlang:phash2(User_id),
  List = io_lib:format("~.16B~.16B",[Hash,Num]),
  list_to_binary(lists:append(List))
  .

