%%%-------------------------------------------------------------------
%%% @author Twinny-KJH
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 29. 11월 2017 오후 4:32
%%%-------------------------------------------------------------------
-module(check_input_data).
-author("Twinny-KJH").

%% API
-export([check_input/2]).

%% 유저 정보관련
%% 유저 가입 데이터 존재여부 체크
check_input({'2017_07_05',<<"user">>,<<"register">>},Data)->
  check_inputData([<<"name">>,<<"email">>,<<"user_nick">>],Data);
%% 유저 탈퇴 데이터 존재여부 체크
check_input({'2017_07_05',<<"user">>,<<"withdrawl">>},Data)->
  check_inputDataAndSession([<<"session">>],Data);
%% 유저 로그인 데이터 존재여부 체크
check_input({'2017_07_05',<<"user">>,<<"login">>},Data)->
  check_inputData([<<"user_id">>,<<"pwd">>],Data);
%% 유저 살트값 조회 데이터 존재여부 체크
check_input({'2017_07_05',<<"user">>,<<"get_salt">>},Data)->
  check_inputData([<<"user_id">>],Data);
%% 유저 중복 조회 데이터 존재여부 체크
check_input({'2017_07_05',<<"user">>,<<"check_exist">>},Data)->
  case check_inputData([<<"user_id">>],Data) of
    {error,_}->
      case check_inputData([<<"user_email">>],Data) of
        {error,_}->
          case check_inputData([<<"user_nick">>],Data) of
            {error,Result}->
              {error,Result};
            {ok,undefined}->
              {ok,undefined}
          end;
        {ok,undefined}->
          {ok,undefined}
      end;
    {ok,undefined}->
      {ok,undefined}
  end
;
%% 유저 정보 보기 체크
check_input({<<"user">>,<<"info">>,_},Data)->
  check_inputDataAndSession([<<"target_idx">>],Data);
%% 유저 정보변경 데이터 존재여부 체크
check_input({<<"user">>,<<"update">>,_},Data)->
  check_inputDataAndSession([<<"email">>,<<"nickname">>,<<"session">>],Data);
%% 유저 로그아웃 데이터 존재여부 체크
check_input({<<"user">>,<<"logout">>,_},Data)->
  check_inputDataAndSession([<<"session">>],Data)

.


check_inputDataAndSession(NeedList,Data)->
  CheckDef = fun(NeedParam) ->
    proplists:is_defined(NeedParam,Data) == false
             end,
  Result = lists:filter(CheckDef, NeedList),
  case Result of
    []->
      % session key check
      Session = proplists:get_value(<<"session">>,Data),
      case Lookup_result = session_server:lookup(Session) of
        {ok,undefined}->
          {error,jsx:encode([{<<"result">>,<<"not exsist session">>}])};
        _->
          Lookup_result
      end;
    _->
      {error,jsx:encode([{<<"result">>,<<"Not enough data">>}])}
  end.


check_inputData(NeedList,Data)->
  CheckDef = fun(NeedParam) ->
    proplists:is_defined(NeedParam,Data) == false
             end,
  Result = lists:filter(CheckDef, NeedList),
  case Result of
    []->
      {ok,undefined};
    _->
      {error,jsx:encode([{<<"result">>,<<"Not enough data">>}])}
  end.