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
                     {error,_}->CheckResult
                   end,
  % http 상태코드 붙임
  {HttpStateCode,Reply} = append_http_code(FunctionResult),

  {ok,Req5} = cowboy_req:reply(HttpStateCode,[
    {<<"content-type">>,<<"application/json">>}
  ], Reply,Req4),
  {ok,Req5,State}.



terminate(_Reason,_Req,_State)->ok.

%% http state 코드를 붙이는 함수
append_http_code(Result)->
  % tuple 값이 들어오면, 해당부분은 상태코드가 포함된 에러값이 리턴된것이므로, 그대로 반환.
  {State,JSON} = Result,
  case State of
    not_found_error->{404,JSON};
    error->{400,JSON};
    server_error->{500,JSON};
    ok->{200,JSON};
    _->{500,jsx:encode([{"result","1"}])}
  end
.
