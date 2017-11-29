%%%-------------------------------------------------------------------
%%% @author Twinny-KJH
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 29. 11월 2017 오후 4:41
%%%-------------------------------------------------------------------
-module('2017_07_05').
-author("Twinny-KJH").

%% API
-export([handle/4]).
-include("sql_result_records.hrl").

%% 유저 로그인
handle('2017_07_05', <<"user">>, <<"login">>, Data) ->
  User_id = proplists:get_value(<<"user_id">>,Data),
  Pwd = proplists:get_value(<<"pwd">>,Data),
  {ok,jsx:encode([{<<"result">>,<<"0">>},mysql_query:query(user_login,[User_id,Pwd])])};
%% 설트값 조회
handle('2017_07_05', <<"user">>, <<"get_salt">>, Data) ->
  User_id = proplists:get_value(<<"user_id">>,Data),
  {Result_atom,Result_json}= mysql_query:query(get_salt,[User_id]),
  {Result_atom,jsx:encode(Result_json)};
%% 유저 가입
handle('2017_07_05', <<"user">>, <<"register">>, Data) ->
  User_id = proplists:get_value(<<"user_id">>,Data),
  Pwd = proplists:get_value(<<"pwd">>,Data),
  Name = proplists:get_value(<<"name">>,Data),
  Email = proplists:get_value(<<"email">>,Data),
  User_nick = proplists:get_value(<<"user_nick">>,Data),
  Salt = proplists:get_value(<<"salt">>,Data),
  % check duplicate
  Result = mysql_query:query(check_exist,[User_id,Email, User_nick]),
  case Result#result_packet.rows of
    []->
      {ok,jsx:encode([{<<"result">>,<<"0">>},mysql_query:query(user_register,[User_id,Pwd,Name,Email, User_nick,Salt])])};
    _->
      {ok,jsx:encode([{<<"result">>,<<"0">>},{<<"message">>,<<"exist">>}])}
  end;
%% 유저 아이디,닉네임,이메일 중복여부 조회
handle('2017_07_05',<<"user">>,<<"check_exist">>,Data)->
  User_id = proplists:get_value(<<"user_id">>,Data),
  Email = proplists:get_value(<<"email">>,Data),
  User_nick = proplists:get_value(<<"user_nick">>,Data),
  Result = mysql_query:query(check_exist,[User_id,Email, User_nick]),
  case Result#result_packet.rows of
    []->
      {ok,jsx:encode([{<<"result">>,<<"0">>},{<<"message">>,<<"not exist">>}])};
    _->
      {ok,jsx:encode([{<<"result">>,<<"0">>},{<<"message">>,<<"exist">>}])}
  end

  ;

handle(_Version,_Category,_Name,_Data)->
%%  Version:handle(Version,Category,Name,Data)
  {not_found_error,jsx:encode([{<<"result">>,<<"0">>}])}
.
