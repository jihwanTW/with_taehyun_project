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
  mysql_query:query(user_login,[User_id,Pwd]);
%% 설트값 조회
handle('2017_07_05', <<"user">>, <<"get_salt">>, Data) ->
  User_id = proplists:get_value(<<"user_id">>,Data),
  mysql_query:query(get_salt,[User_id]);
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
      mysql_query:query(user_register,[User_id,Pwd,Name,Email, User_nick,Salt]);
    _->
      {error_user_exist,[{<<"message">>,<<"user exsit">>}]}
  end;
%% 유저 아이디,닉네임,이메일 중복여부 조회
handle('2017_07_05',<<"user">>,<<"check_exist">>,Data)->
  User_id = proplists:get_value(<<"user_id">>,Data),
  Email = proplists:get_value(<<"email">>,Data),
  User_nick = proplists:get_value(<<"user_nick">>,Data),
  Result = mysql_query:query(check_exist,[User_id,Email, User_nick]),
  case Result#result_packet.rows of
    []->
      {ok,[{<<"message">>,<<"not exist">>}]};
    _->
      {error_check_exist,[{<<"message">>,<<"check exsit">>}]}
  end
  ;


%% 게시판 리스트/검색
handle('2017_07_05',<<"board">>,<<"list">>,Data)->
  Board = proplists:get_value(<<"board">>,Data),
  Page = proplists:get_value(<<"page">>,Data,1),
  Limit = proplists:get_value(<<"limit">>,Data,10),
  Search_type = proplists:get_value(<<"search_type">>,Data,0),
  Search_keyword = proplists:get_value(<<"search_keyword">>,Data,""),
  mysql_query:query(board_list,[Board,Page,Limit,Search_type,Search_keyword])
  ;
%% 게시글 조회
handle('2017_07_05',<<"board">>,<<"view">>,Data)->
  Board = proplists:get_value(<<"board">>,Data),
  Post_idx = proplists:get_value(<<"post_idx">>,Data),
  mysql_query:query(board_view,[Board, Post_idx])
  ;
%% 게시글 쓰기
handle('2017_07_05',<<"board">>,<<"write">>,{User_idx,Data})->
  Board = proplists:get_value(<<"board">>,Data),
  Title = proplists:get_value(<<"title">>,Data),
  Contents = proplists:get_value(<<"contents">>,Data),
  mysql_query:query(board_write,[Board,Title,Contents,User_idx])
;
%% 게시글 수정
handle('2017_07_05',<<"board">>,<<"fixed">>,{User_idx,Data})->
  Board = proplists:get_value(<<"board">>,Data),
  Post_idx = proplists:get_value(<<"post_idx">>,Data),
  Title = proplists:get_value(<<"title">>,Data),
  Contents = proplists:get_value(<<"contents">>,Data),
  mysql_query:query(board_fixed,[Board,Post_idx,Title,Contents,User_idx])
  ;

%% 게시글 삭제
handle('2017_07_05',<<"board">>,<<"remove">>,{User_idx,Data})->
  Board = proplists:get_value(<<"board">>,Data),
  Post_idx = proplists:get_value(<<"post_idx">>,Data),
  mysql_query:query(board_remove,[Board,Post_idx,User_idx])
  ;

handle(_Version,_Category,_Name,_Data)->
%%  Version:handle(Version,Category,Name,Data)
  {error_url_not_found,[{<<"message">>,<<"not found api">>}]}
.
