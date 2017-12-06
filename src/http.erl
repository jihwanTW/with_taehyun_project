%%%-------------------------------------------------------------------
%%% @author Twinny-KJH
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 29. 11월 2017 오후 4:29
%%%-------------------------------------------------------------------
-module(http).
-author("Twinny-KJH").

%% API
-export([init/3,handle/2,terminate/3]).


init(_Type,Req,[]) ->
  {ok,Req,no_state}.

handle(Req,State)->
  {Version,Req1} = cowboy_req:binding(version,Req),
  {Category,Req2} = cowboy_req:binding(category,Req1),
  {Name,Req3} = cowboy_req:binding(name,Req2),
  % 데이터 로딩

  {ok, [{_,JsonData}|_],Req4} = cowboy_req:body_qs(Req3),
  % JSON 형태로 들어온 데이터 decode
  DecodeData = jsx:decode(JsonData),
  Version_atom = binary_to_atom(Version,utf8),
  % 인풋데이터 존재여부와 세션키를 필요로하면 세션값체크
  CheckResult = check_input_data:check_input({Version_atom, Category, Name},DecodeData),
  io:format("~p ~p ~p ~p ~n",[Version,Category,Name,DecodeData]),
  % api 호출
  FunctionResult = case CheckResult of
                     {ok,undefined}->
                       try Version_atom:handle(Version_atom, Category, Name,DecodeData)
                       catch T:Why ->
                         io:format("Why(no session) : [~p] ~p~n~p ~n",[T,Why,erlang:get_stacktrace()]),
                         {error,jsx:encode([{<<"result">>,<<"check error log">>}])}
                       end;
                     {ok,User_idx}->
                       try Version_atom:handle(Version_atom, Category, Name,{User_idx,DecodeData})
                       catch T:Why ->
                         io:format("Why(no session) : [~p] ~p~n~p ~n",[T,Why,erlang:get_stacktrace()]),
                         {error,jsx:encode([{<<"result">>,<<"check error log">>}])}
                       end;
                     _->CheckResult
                   end,
  % http 상태코드 붙임
  {HttpStateCode,Reply} = append_http_code(append_result_json(FunctionResult)),

  {ok,Req5} = cowboy_req:reply(HttpStateCode,[
    {<<"content-type">>,<<"application/json">>}
  ], Reply,Req4),
  {ok,Req5,State}.



terminate(_Reason,_Req,_State)->ok.

%% http state 코드를 붙이는 함수
append_http_code(Result)->
  % tuple 값이 들어오면, 해당부분은 상태코드가 포함된 에러값이 리턴된것이므로, 그대로 반환.
  {State,JSON} = Result,
  Code_200 = {200,JSON},
  Code_400 = {400,JSON},
  Code_404 = {404,JSON},
  Code_500 = {500,JSON},
  case State of
    error_url_not_found->Code_404;

    error->Code_400;
    error_session_not_exist->Code_400;
    error_not_enough_parameter->Code_400;
    error_failed_login->Code_400;
    error_user_not_exist->Code_400;
    error_user_exist->Code_400;
    error_check_exist->Code_400;
    error_board_not_exist->Code_400;
    error_post_not_exist->Code_400;

    ok->Code_200;

    server_error->Code_500;
    _->Code_500
  end
.

append_result_json({Result, Json_list})->
  Json = case Result of
           ok->
             utils:list2json([{<<"result">>,<<"0">>}]++ Json_list);
           error_url_not_found->
             utils:list2json([{<<"result">>,<<"1">>}]++ Json_list);
           error_not_enough_parameter->
             utils:list2json([{<<"result">>,<<"2">>}]++ Json_list);
           error_session_not_exist->
             utils:list2json([{<<"result">>,<<"3">>}]++ Json_list);
           error_failed_login->
             utils:list2json([{<<"result">>,<<"4">>}]++ Json_list);
           error_user_not_exist->
             utils:list2json([{<<"result">>,<<"5">>}]++ Json_list);
           error_user_exist->
             utils:list2json([{<<"result">>,<<"6">>}]++ Json_list);
           error_check_exist->
             utils:list2json([{<<"result">>,<<"7">>}]++ Json_list);
           error_board_not_exist->
             utils:list2json([{<<"result">>,<<"8">>}]++ Json_list);
           error_post_not_exist->
             utils:list2json([{<<"result">>,<<"9">>}]++ Json_list);
           _->
             utils:list2json([{<<"result">>,<<"-1">>},{<<"error_result">>,Result},{<<"list">>,Json_list}])
  end,
  {Result,Json}
  .