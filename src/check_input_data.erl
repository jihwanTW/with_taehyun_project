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

check_input({'2017_07_05',<<"board">>,<<"list">>},Data)->
  check_inputData([<<"board">>],Data)
;
check_input({'2017_07_05',<<"board">>,<<"view">>},Data)->
  check_inputData([<<"board">>,<<"post_idx">>],Data)
;
check_input({'2017_07_05',<<"board">>,<<"write">>},Data)->
  check_inputDataAndSession([<<"board">>,<<"title">>,<<"contents">>],Data)
;
check_input({'2017_07_05',<<"board">>,<<"fixed">>},Data)->
  check_inputDataAndSession([<<"board">>,<<"post_idx">>,<<"title">>,<<"contents">>],Data)
;
check_input({'2017_07_05',<<"board">>,<<"remove">>},Data)->
  check_inputDataAndSession([<<"board">>,<<"post_idx">>],Data)
;
check_input({_Version,_Category,_Name},_Data)->
  {error_url_not_found,[{<<"message">>,<<"undefiend url">>}]}
.


check_inputDataAndSession(NeedList,Data)->
  CheckDef = fun(NeedParam) ->
    proplists:is_defined(NeedParam,Data) == false
             end,
  Result = lists:filter(CheckDef, NeedList),
  case Result of
    []->
      % session key check
      Session = proplists:get_value(<<"session_key">>,Data),
      case Lookup_result = session_server:lookup(Session) of
        {ok,undefined}->
          {error_session_not_exist,[{<<"message">>,<<"not exsist session">>}]};
        _->
          Lookup_result
      end;
    _->
      {error_not_enough_parameter,[{<<"message">>,<<"not enough data">>}]}
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
      {error_not_enough_parameter,[{<<"message">>,<<"not enough data">>}]}
  end.